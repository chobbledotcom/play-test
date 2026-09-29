# typed: strict

# The i18n gem ships no RBI, so typed files cannot resolve I18n at all.
# Declare the methods the app calls; results stay untyped because the gem
# returns translated values, hashes or nil depending on the options given.
module I18n
  extend T::Sig

  sig { params(key: T.any(String, Symbol), options: T.untyped).returns(T.untyped) }
  def self.t(key, **options); end

  sig { params(key: T.any(String, Symbol), options: T.untyped).returns(T.untyped) }
  def self.t!(key, **options); end

  sig { params(key: T.any(String, Symbol), locale: T.untyped).returns(T::Boolean) }
  def self.exists?(key, locale = nil); end

  sig { returns(T.untyped) }
  def self.backend; end

  sig { params(locale: T.untyped, key: T.untyped, scope: T.untyped, separator: T.untyped).returns(T::Array[Symbol]) }
  def self.normalize_keys(locale, key, scope = [], separator = nil); end

  sig { returns(Symbol) }
  def self.default_locale; end
end
