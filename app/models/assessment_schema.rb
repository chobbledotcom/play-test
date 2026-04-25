# typed: true
# frozen_string_literal: true

# Centralised, immutable representation of an assessment's form schema.
#
# Replaces the ad-hoc walks of the YAML structure that previously lived in
# FormConfigurable, ValidationConfigurable, AssessmentCompletion and a few
# consumers (PDF builder, controllers). Each assessment YAML in
# config/forms/*.yml is loaded once into an AssessmentSchema; concerns and
# consumers ask the schema typed questions instead of poking at raw hashes.
class AssessmentSchema
  extend T::Sig

  FORM_CONFIG_DIR = Rails.root.join("config/forms").freeze

  @cache = {}

  sig do
    params(klass: T.class_of(ActiveRecord::Base))
      .returns(AssessmentSchema)
  end
  def self.for(klass)
    @cache[klass.name] ||= load(klass.name.demodulize.underscore)
  end

  sig { params(file_name: String).returns(AssessmentSchema) }
  def self.load(file_name)
    config_path = FORM_CONFIG_DIR.join("#{file_name}.yml")
    yaml = YAML.load_file(config_path).deep_symbolize_keys
    new(file_name, yaml.fetch(:form_fields))
  end

  sig { void }
  def self.reset_cache!
    @cache = {}
  end

  class Field
    extend T::Sig

    NUMERIC_PARTIALS = %i[number number_pass_fail_na_comment].freeze
    DECIMAL_PARTIALS = %i[decimal decimal_comment].freeze

    sig { returns(Symbol) }
    attr_reader :name

    sig { returns(Symbol) }
    attr_reader :partial

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :attributes

    sig { params(raw: T::Hash[Symbol, T.untyped]).void }
    def initialize(raw)
      @name = raw.fetch(:field).to_sym
      @partial = raw.fetch(:partial).to_sym
      @attributes = (raw[:attributes] || {}).freeze
    end

    sig { returns(T::Boolean) }
    def required? = !!attributes[:required]

    sig { returns(T::Boolean) }
    def numeric? = NUMERIC_PARTIALS.include?(partial)

    sig { returns(T::Boolean) }
    def decimal? = DECIMAL_PARTIALS.include?(partial)

    sig { returns(T::Boolean) }
    def add_not_applicable? = !!attributes[:add_not_applicable]

    sig { returns(T.nilable(Numeric)) }
    def min = attributes[:min]

    sig { returns(T.nilable(Numeric)) }
    def max = attributes[:max]

    sig { returns(T::Array[Symbol]) }
    def composite_fields
      @composite_fields ||= ChobbleForms::FieldUtils
        .get_composite_fields(name, partial)
        .map(&:to_sym)
        .freeze
    end
  end

  class Fieldset
    extend T::Sig

    sig { returns(Symbol) }
    attr_reader :legend_i18n_key

    sig { returns(T::Array[Field]) }
    attr_reader :fields

    sig { params(raw: T::Hash[Symbol, T.untyped]).void }
    def initialize(raw)
      @legend_i18n_key = raw.fetch(:legend_i18n_key).to_sym
      @fields = (raw[:fields] || []).map { Field.new(_1) }.freeze
    end
  end

  sig { returns(String) }
  attr_reader :name

  sig { returns(T::Array[Fieldset]) }
  attr_reader :fieldsets

  sig do
    params(
      name: String,
      raw: T::Array[T::Hash[Symbol, T.untyped]]
    ).void
  end
  def initialize(name, raw)
    @name = name
    @raw = raw
    @fieldsets = raw.map { Fieldset.new(_1) }.freeze
  end

  # Returns a deep copy of the original YAML structure. Callers that haven't
  # yet been migrated to the typed API receive a fresh array each call so
  # they can mutate without affecting the cached schema.
  sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def to_form_config = @raw.deep_dup

  sig { returns(T::Array[Field]) }
  def fields
    @fields ||= fieldsets.flat_map(&:fields).freeze
  end

  sig { params(field_name: T.any(String, Symbol)).returns(T.nilable(Field)) }
  def find_field(field_name)
    sym = field_name.to_sym
    fields.find { _1.name == sym }
  end

  # Looks up the rendering partial for a field, falling back to its base
  # field (so e.g. :ropes_pass resolves via :ropes' partial).
  sig { params(field_name: T.any(String, Symbol)).returns(T.nilable(Symbol)) }
  def partial_for(field_name)
    direct = find_field(field_name)
    return direct.partial if direct

    base = ChobbleForms::FieldUtils.strip_field_suffix(field_name.to_sym)
    find_field(base)&.partial
  end

  sig { returns(T::Array[Symbol]) }
  def add_not_applicable_fields
    fields.select(&:add_not_applicable?).map(&:name)
  end
end
