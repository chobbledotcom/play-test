# Module to track I18n key usage during test runs
module I18nUsageTracker
  class << self
    attr_accessor :tracking_enabled
    attr_reader :used_keys

    def reset!
      @used_keys = Set.new
      @tracking_enabled = false
    end

    def track_key(key, options = {})
      return unless tracking_enabled && key

      # Handle both string and symbol keys
      key_string = key.to_s

      # Skip Rails internal keys and error keys
      return if key_string.start_with?("errors.", "activerecord.", "activemodel.", "helpers.", "number.", "date.", "time.", "support.")

      # Track the full key
      @used_keys << key_string

      # Also track parent keys for nested translations
      # e.g., for "users.messages.created", also track "users.messages" and "users"
      parts = key_string.split(".")
      (1...parts.length).each do |i|
        parent_key = parts[0...i].join(".")
        @used_keys << parent_key unless parent_key.empty?
      end

      # Track keys used with scope option
      if options[:scope]
        scope = Array(options[:scope]).join(".")
        full_key = "#{scope}.#{key_string}"
        @used_keys << full_key

        # Track parent keys for scoped translations
        full_parts = full_key.split(".")
        (1...full_parts.length).each do |i|
          parent_key = full_parts[0...i].join(".")
          @used_keys << parent_key unless parent_key.empty?
        end
      end
    end

    def all_locale_keys
      @all_locale_keys ||= begin
        keys = Set.new

        # Load all locale files
        locale_files = Rails.root.glob("config/locales/**/*.yml")

        locale_files.each do |file|
          yaml_content = YAML.load_file(file)

          # Process each locale (en, es, etc.)
          yaml_content.each do |locale, content|
            extract_keys_from_hash(content, [], keys)
          end
        end

        keys
      end
    end

    def unused_keys
      all_locale_keys - used_keys
    end

    def usage_report
      total_keys = all_locale_keys.size
      used_count = used_keys.size
      unused_count = unused_keys.size

      {
        total_keys: total_keys,
        used_keys: used_count,
        unused_keys: unused_count,
        usage_percentage: (used_count.to_f / total_keys * 100).round(2),
        unused_key_list: unused_keys.sort
      }
    end

    private

    def extract_keys_from_hash(hash, current_path, keys)
      hash.each do |key, value|
        new_path = current_path + [key.to_s]
        full_key = new_path.join(".")

        if value.is_a?(Hash)
          keys << full_key
          extract_keys_from_hash(value, new_path, keys)
        else
          keys << full_key
        end
      end
    end
  end

  # Reset on initialization
  reset!

  # Add at_exit hook to save tracking results if enabled
  at_exit do
    if tracking_enabled && used_keys.any?
      Rails.root.join("tmp/i18n_tracking_results.json").write(used_keys.to_a.to_json)
    end
  end
end

# Monkey patch I18n.t to track usage
module I18n
  class << self
    alias_method :original_t, :t
    alias_method :original_translate, :translate

    def t(key, **options)
      I18nUsageTracker.track_key(key, options) if I18nUsageTracker.tracking_enabled
      original_t(key, **options)
    end

    def translate(key, **options)
      I18nUsageTracker.track_key(key, options) if I18nUsageTracker.tracking_enabled
      original_translate(key, **options)
    end
  end
end

# Also track Rails view helpers
if defined?(ActionView::Helpers::TranslationHelper)
  module ActionView::Helpers::TranslationHelper
    alias_method :original_t, :t
    alias_method :original_translate, :translate

    def t(key, **options)
      I18nUsageTracker.track_key(key, options) if I18nUsageTracker.tracking_enabled
      original_t(key, **options)
    end

    def translate(key, **options)
      I18nUsageTracker.track_key(key, options) if I18nUsageTracker.tracking_enabled
      original_translate(key, **options)
    end
  end
end
