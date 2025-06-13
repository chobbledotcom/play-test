module ApplicationHelper
  def render_time(datetime)
    return nil if datetime.nil?

    datetime.strftime("%b %d, %Y")
  end

  def date_for_form(datetime)
    return nil if datetime.nil?

    datetime.to_date
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
    number_options
    options
    required
    rows
    step
    type
  ]

  def nav_link_to(name, path, options = {})
    css_class = if current_page?(path) || controller_matches?(path)
      "active"
    else
      ""
    end
    link_to name, path, options.merge(class: css_class)
  end

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

    # Look for field label in the fields namespace
    fields_key = "#{i18n_base}.fields.#{field}"
    
    field_label = t(fields_key, raise: true)

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

  private

  def controller_matches?(path)
    # Extract controller name from the path
    route = Rails.application.routes.recognize_path(path)
    path_controller = route[:controller]
    
    # Check if we're in the same controller
    controller_name == path_controller
  rescue ActionController::RoutingError
    false
  end
end
