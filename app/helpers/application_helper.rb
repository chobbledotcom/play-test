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

  ALLOWED_LOCAL_ASSIGNS = %i[
    accept
    field
    max
    min
    options
    required
    rows
    step
    type
  ]

  def form_field_setup(field, local_assigns)
    locally_assigned_keys = (local_assigns || {}).keys
    disallowed_keys = locally_assigned_keys - ALLOWED_LOCAL_ASSIGNS

    if disallowed_keys.any?
      raise ArgumentError, "local_assigns contains #{disallowed_keys.inspect}"
    end

    form_object = @_current_form
    i18n_base = @_current_i18n_base

    if i18n_base.nil?
      raise ArgumentError, "no @_current_form in form_field_setup"
    elsif form_object.nil?
      raise ArgumentError, "no @_current_i18n_base in form_field_setup"
    end

    label_key = "#{i18n_base}.#{field}"
    field_label = t(label_key, raise: true)

    base_parts = i18n_base.split(".")
    root = base_parts[0..-2]
    hint_key = (root + ["hints", field]).join(".")
    placeholder_key = (root + ["placeholders", field]).join(".")

    field_hint = t(hint_key, default: nil)
    field_placeholder = t(placeholder_key, default: nil)

    {
      form_object:,
      i18n_base:,
      field_label:,
      field_hint:,
      field_placeholder:
    }
  end
end
