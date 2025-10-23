# typed: false
# frozen_string_literal: true

class DatabaseI18nBackend < I18n::Backend::Simple
  @cache = {}
  @cache_loaded = false

  class << self
    attr_accessor :cache, :cache_loaded

    def load_cache
      @cache = TextReplacement.pluck(:i18n_key, :value).to_h
      @cache_loaded = true
      Rails.logger.info "Loaded #{@cache.size} text replacements into cache"
    end

    def reload_cache
      @cache_loaded = false
      load_cache
    end
  end

  def lookup(locale, key, scope = [], options = {})
    self.class.load_cache unless self.class.cache_loaded

    flat_key = I18n.normalize_keys(locale, key, scope, options[:separator]).join(".")

    cached_value = self.class.cache[flat_key]
    return cached_value if cached_value

    super
  end
end
