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
      assessment_schema.fields.each { |field| apply_validation_for(field) }
    end

    private

    sig { params(field: AssessmentSchema::Field).void }
    def apply_validation_for(field)
      applicable = ->(record) do
        configured = record.form_schema.find_field(field.name)
        configured && configured.partial == field.partial &&
          !(record.is_a?(AssessmentCompletion) &&
            record.measurement_not_applicable?(field.name))
      end
      if field.required?
        required_fields = field.attribute_names
          .reject { it.end_with?("_comment") }
        unless required_fields.empty?
          validates(*required_fields, presence: true, if: applicable)
        end
      end
      return unless field.numeric? || field.decimal?

      options = numericality_options(field)
      options[:only_integer] = true if field.numeric?
      validates field.name, numericality: options,
        allow_blank: true, if: applicable
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
