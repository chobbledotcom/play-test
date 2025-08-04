# Module to track I18n key usage during test runs
module ChobbleApp
  module I18nUsageTracker
    class << self
      attr_accessor :tracking_enabled
      attr_reader :used_keys

      def reset!
        @used_keys = Set.new
        @tracking_enabled = false
      end

      def track_key(key, options = {})
        return unless tracking_enabled
        return unless key.is_a?(String) || key.is_a?(Symbol)

        # Skip Rails internal keys
        key_str = key.to_s
        return if rails_internal_key?(key_str)

        # Track the key itself
        full_key = key_str
        @used_keys << full_key unless rails_internal_key?(full_key)

        # Track scoped keys
        if options[:scope]
          scopes = Array(options[:scope]).map(&:to_s).join(".")
          scoped_key = [scopes, key_str].join(".")
          @used_keys << scoped_key unless rails_internal_key?(scoped_key)
          
          # Track all parent keys from the scoped key
          track_parent_keys(scoped_key)
          
          # Also track parent keys from the scope itself
          track_parent_keys(scopes)
        end

        # Track parent keys (e.g., 'users' from 'users.new.title')
        # This helps identify if entire sections are unused
        track_parent_keys(full_key)
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
        total = all_locale_keys.size
        used = used_keys.size
        unused_count = unused_keys.size
        percentage = total > 0 ? (used.to_f / total * 100).round(2) : 0.0

        {
          total_keys: total,
          used_keys: used,
          unused_keys: unused_count,
          usage_percentage: percentage,
          unused_key_list: unused_keys.to_a.sort
        }
      end

      def print_usage_report
        unused = unused_keys
        puts "\n=== I18n Usage Report ==="
        puts "Total keys: #{all_locale_keys.size}"
        puts "Used keys: #{used_keys.size}"
        puts "Unused keys: #{unused.size}"

        if unused.any?
          puts "\nUnused keys:"
          unused.to_a.sort.each { |key| puts "  - #{key}" }
        end
      end

      private

      def track_parent_keys(key)
        return if key.nil? || key.empty?
        
        parts = key.split(".")
        if parts.length > 1
          # Add all parent keys
          (1...parts.length).each do |i|
            parent_key = parts[0...i].join(".")
            @used_keys << parent_key unless parent_key.empty? || rails_internal_key?(parent_key)
          end
        end
      end

      def rails_internal_key?(key)
        # List of Rails internal key patterns to skip
        rails_patterns = [
          /^errors\./,
          /^activerecord\./,
          /^activemodel\./,
          /^helpers\./,
          /^number\./,
          /^date\./,
          /^time\./,
          /^support\./
        ]
        
        rails_patterns.any? { |pattern| key.match?(pattern) }
      end

      def extract_keys_from_hash(hash, path, keys)
        return unless hash.is_a?(Hash)

        hash.each do |key, value|
          new_path = path + [key.to_s]
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
end

# Monkey patch I18n.t to track usage
module I18n
  class << self
    alias_method :original_t, :t
    alias_method :original_translate, :translate

    def t(key, **options)
      ChobbleApp::I18nUsageTracker.track_key(key, options) if ChobbleApp::I18nUsageTracker.tracking_enabled
      original_t(key, **options)
    end

    def translate(key, **options)
      ChobbleApp::I18nUsageTracker.track_key(key, options) if ChobbleApp::I18nUsageTracker.tracking_enabled
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
      ChobbleApp::I18nUsageTracker.track_key(key, options) if ChobbleApp::I18nUsageTracker.tracking_enabled
      original_t(key, **options)
    end

    def translate(key, **options)
      ChobbleApp::I18nUsageTracker.track_key(key, options) if ChobbleApp::I18nUsageTracker.tracking_enabled
      original_translate(key, **options)
    end
  end
end