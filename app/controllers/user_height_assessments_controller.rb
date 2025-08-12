# typed: false

class UserHeightAssessmentsController < ApplicationController
  include AssessmentController
  include SafetyStandardsTurboStreams

  private

  def success_turbo_streams(additional_info: nil)
    # Call parent which includes SafetyStandardsTurboStreams
    streams = super

    # Add our field update streams if any fields were defaulted
    return streams unless @fields_defaulted_to_zero&.any?

    streams + field_update_streams
  end

  def field_update_streams
    form_config = assessment_class.form_fields

    @fields_defaulted_to_zero.map do |field|
      field_config = find_field_config(form_config, field)
      next unless field_config

      build_field_turbo_stream(field, field_config)
    end.compact
  end

  def build_field_turbo_stream(field, field_config)
    turbo_stream.replace(
      field,
      partial: "chobble_forms/field_turbo_response",
      locals: {
        model: @assessment,
        field:,
        partial: field_config[:partial],
        i18n_base: "forms.user_height",
        attributes: field_config[:attributes] || {}
      }
    )
  end

  def find_field_config(form_config, field_name)
    # The YAML loads field names as strings, not symbols
    field_str = field_name.to_s
    form_config.each do |fieldset|
      fieldset[:fields].each do |field_config|
        return field_config if field_config[:field] == field_str
      end
    end
    nil
  end

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
