# typed: false

class UserHeightAssessmentsController < ApplicationController
  include AssessmentController
  include SafetyStandardsTurboStreams

  private

  def preprocess_values
    @fields_defaulted_to_zero = []

    # The param key matches the model's param_key
    param_key = assessment_class.model_name.param_key
    return unless params[param_key]

    apply_user_height_defaults(param_key)
  end

  def apply_user_height_defaults(param_key)
    user_height_fields = %w[
      users_at_1000mm
      users_at_1200mm
      users_at_1500mm
      users_at_1800mm
    ]

    user_height_fields.each do |field|
      if params[param_key][field].blank?
        params[param_key][field] = "0"
        @fields_defaulted_to_zero << field
      end
    end
  end

  def build_additional_info
    return nil unless @fields_defaulted_to_zero&.any?

    fields = @fields_defaulted_to_zero
    field_names = fields.map { |f| I18n.t("forms.user_height.fields.#{f}") }
    I18n.t(
      "inspections.messages.user_height_defaults_applied",
      fields: field_names.join(", ")
    )
  end
end
