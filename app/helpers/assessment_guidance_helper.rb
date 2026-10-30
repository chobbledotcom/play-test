# typed: true
# frozen_string_literal: true

module AssessmentGuidanceHelper
  extend T::Sig

  sig do
    params(assessment: ApplicationRecord, entry: T::Hash[Symbol, T.untyped])
      .returns(String)
  end
  def measurement_guidance_text(assessment, entry)
    form = entry.fetch(:form)
    field = entry.fetch(:field)
    label = assessment.inspection.field_label(form, field)
    value = number_with_precision(entry.fetch(:value), precision: 4,
      strip_insignificant_zeros: true)
    status = t(entry.fetch(:status), scope: "assessment_guidance.status")
    t("assessment_guidance.comparison", label: label, value: value,
      status: status)
  end
end
