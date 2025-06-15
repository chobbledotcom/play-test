# Helper methods for interacting with radio buttons that used to be checkboxes
module RadioButtonHelpers
  BOOLEANS_BY_FORM = {
    inspection: %i[has_slide is_totally_enclosed passed],
    slide_assessment: %i[slide_permanent_roof]
  }.freeze
  # Choose Yes/No radio button for boolean fields
  def choose_yes_no(field_label, value)
    # First, find all labels that contain the field label text
    # Then find the Yes/No radio button within the same container
    within(:xpath, "//label[contains(., '#{field_label}')]/..") do
      if value
        choose I18n.t("shared.yes")
      else
        choose I18n.t("shared.no")
      end
    end
  end

  # Convert field label to just the field name (without model prefix)
  def field_label_to_field_name(field_label)
    BOOLEANS_BY_FORM.each do |model, fields|
      form_type = (model == :inspection) ? :inspections : :slide
      fields.each do |field|
        return field.to_s if field_label == I18n.t("forms.#{form_type}.fields.#{field}")
      end
    end
    raise "Unknown field label: #{field_label}"
  end

  # Convert field label to form field name
  def field_label_to_name(field_label)
    BOOLEANS_BY_FORM.each do |model, fields|
      form_type = (model == :inspection) ? :inspections : :slide
      fields.each do |field|
        return "#{model}[#{field}]" if field_label == I18n.t("forms.#{form_type}.fields.#{field}")
      end
    end
    raise "Unknown field label: #{field_label}"
  end

  # Backwards compatible method for tests that use check
  def check_radio(field_label)
    choose_yes_no(field_label, true)
  end

  # Backwards compatible method for tests that use uncheck
  def uncheck_radio(field_label)
    choose_yes_no(field_label, false)
  end
end

RSpec.configure do |config|
  config.include RadioButtonHelpers, type: :feature
end
