# typed: true
# frozen_string_literal: true

module FormConfigurable
  extend ActiveSupport::Concern
  extend T::Sig

  class_methods do
    extend T::Sig

    sig { returns(AssessmentSchema) }
    def assessment_schema
      AssessmentSchema.for(self)
    end

    sig do
      params(user: T.nilable(User))
        .returns(T::Array[T::Hash[Symbol, T.untyped]])
    end
    def form_fields(user: nil)
      assessment_schema.to_form_config
    end
  end
end
