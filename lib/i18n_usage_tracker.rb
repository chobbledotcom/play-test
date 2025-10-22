module I18nUsageTracker
  SKIPPED_PREFIXES = %w[
    activemodel.
    activerecord.
    date.
    errors.
    helpers.
    number.
    support.
    time.
  ].freeze

  class << self
    attr_accessor :tracking_enabled
    attr_reader :used_keys

    def reset!
      @used_keys = Set.new
    end

    def track_key(key, options = {})
      return unless tracking_enabled && key

      key_string = key.to_s
      return if skip_key?(key_string)

      track_key_and_parents(key_string)
      track_scoped_key(key_string, options[:scope]) if options[:scope]
    end

    def all_locale_keys
      @all_locale_keys ||= begin
        keys = Set.new
        locale_files = Rails.root.glob("config/locales/**/*.yml")

        locale_files.each do |file|
          yaml_content = YAML.load_file(file)
          yaml_content.each do |_locale, content|
            extract_keys(content, [], keys)
          end
        end

        keys
      end
    end

    def unused_keys
      all_locale_keys - used_keys
    end

    def usage_report
      total = all_locale_keys.size
      used = used_keys.size
      unused = unused_keys.size

      {
        total_keys: total,
        used_keys: used,
        unused_keys: unused,
        usage_percentage: (used.to_f / total * 100).round(2),
        unused_key_list: unused_keys.sort
      }
    end

    private

    def skip_key?(key_string)
      SKIPPED_PREFIXES.any? { |prefix| key_string.start_with?(prefix) }
    end

    def track_key_and_parents(key_string)
      @used_keys << key_string
      parts = key_string.split(".")
      (1...parts.length).each do |i|
        parent = parts[0...i].join(".")
        @used_keys << parent unless parent.empty?
      end
    end

    def track_scoped_key(key_string, scope)
      scope_string = Array(scope).join(".")
      full_key = "#{scope_string}.#{key_string}"
      track_key_and_parents(full_key)
    end

    def extract_keys(hash, current_path, keys)
      hash.each do |key, value|
        new_path = current_path + [key.to_s]
        full_key = new_path.join(".")
        keys << full_key

        extract_keys(value, new_path, keys) if value.is_a?(Hash)
      end
    end
  end

  @used_keys = Set.new
  @tracking_enabled = false

  at_exit do
    if tracking_enabled && used_keys.any?
      results_path = Rails.root.join("tmp/i18n_tracking_results.json")
      results_path.write(used_keys.to_a.to_json)
    end
  end
end

module I18n
  class << self
    alias_method :original_t, :t
    alias_method :original_translate, :translate

    def t(key, **options)
      track_usage(key, options)
      original_t(key, **options)
    end

    def translate(key, **options)
      track_usage(key, options)
      original_translate(key, **options)
    end

    private

    def track_usage(key, options)
      return unless I18nUsageTracker.tracking_enabled
      I18nUsageTracker.track_key(key, options)
    end
  end
end

if defined?(ActionView::Helpers::TranslationHelper)
  module ActionView::Helpers::TranslationHelper
    alias_method :original_t, :t
    alias_method :original_translate, :translate

    def t(key, **options)
      track_usage(key, options)
      original_t(key, **options)
    end

    def translate(key, **options)
      track_usage(key, options)
      original_translate(key, **options)
    end

    private

    def track_usage(key, options)
      return unless I18nUsageTracker.tracking_enabled
      I18nUsageTracker.track_key(key, options)
    end
  end
end
