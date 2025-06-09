module ApplicationHelper
  TIME_FORMATS = {
    "date" => "%b %d, %Y",
    "time" => "%b %d, %Y - %H:%M"
  }

  def render_time(datetime)
    return nil if datetime.nil?

    format = TIME_FORMATS[current_user&.time_display] || TIME_FORMATS["date"]
    datetime.strftime(format)
  end

  def date_for_form(datetime)
    return nil if datetime.nil?

    if current_user&.time_display == "date"
      datetime.to_date
    else
      datetime
    end
  end

  def scrollable_table(html_options = {}, &block)
    content_tag(:div, class: "table-container") do
      content_tag(:table, html_options, &block)
    end
  end

  # Shared form field helper logic - requires explicit i18n_base
  def form_field_setup(field, local_assigns, i18n_base: nil)
    # Get form object - either passed directly or from wrapper
    form_object = local_assigns[:form] || @_current_form

    # Require explicit i18n_base - no more guessing
    i18n_base = local_assigns[:i18n_base] || i18n_base
    raise ArgumentError, "i18n_base is required for form field setup" if i18n_base.nil?

    # Simple label key construction
    label_key = "#{i18n_base}.#{field}"

    # Get label, hint, placeholder - fail loudly if required keys are missing
    field_label = local_assigns[:label] || t(label_key, raise: true)

    # Build hint and placeholder keys with proper structure
    base_parts = i18n_base.split(".")
    hint_key = (base_parts[0..-2] + ["hints", field.to_s]).join(".")
    placeholder_key = (base_parts[0..-2] + ["placeholders", field.to_s]).join(".")

    field_hint = local_assigns[:hint] || t(hint_key, default: nil)
    field_placeholder = local_assigns[:placeholder] || t(placeholder_key, default: nil)

    {
      form_object: form_object,
      i18n_base: i18n_base,
      field_label: field_label,
      field_hint: field_hint,
      field_placeholder: field_placeholder
    }
  end
end
