# typed: true
# frozen_string_literal: true

module ValidationConfigurable
  extend ActiveSupport::Concern
  extend T::Sig

  included do
    if ancestors.include?(FormConfigurable)
      apply_form_validations
    end
  end

  class_methods do
    extend T::Sig

    sig { void }
    def apply_form_validations
      raw = begin
        form_fields
      rescue
        nil
      end
      return unless raw

      schema = AssessmentSchema.new(name.to_s, raw)
      schema.fields.each { |field| apply_validation_for(field) }
    end

    private

    sig { params(field: AssessmentSchema::Field).void }
    def apply_validation_for(field)
      validates field.name, presence: true if field.required?

      if field.numeric?
        options = numericality_options(field)
        options[:only_integer] = true
        validates field.name, numericality: options, allow_blank: true
      elsif field.decimal?
        validates field.name,
          numericality: numericality_options(field),
          allow_blank: true
      end
    end

    sig do
      params(field: AssessmentSchema::Field)
        .returns(T::Hash[Symbol, T.untyped])
    end
    def numericality_options(field)
      options = {}
      options[:greater_than_or_equal_to] = field.min if field.min
      options[:less_than_or_equal_to] = field.max if field.max
      options
    end
  end
end
