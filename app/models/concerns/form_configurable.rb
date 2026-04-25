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

    # Schema for rendering. Override in subclasses to filter fields based on
    # the current user (e.g. hiding admin-only fields).
    sig { params(user: T.nilable(User)).returns(AssessmentSchema) }
    def form_schema(user: nil)
      assessment_schema
    end
  end
end
