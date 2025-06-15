module ApplicationHelper
  def render_time(datetime) = datetime&.strftime("%b %d, %Y")

  def date_for_form(datetime) = datetime&.to_date

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

    case [i18n_base, form_object]
    in [nil, _] then raise ArgumentError, "no @_current_i18n_base in form_field_setup"
    in [_, nil] then raise ArgumentError, "no @_current_form in form_field_setup"
    else # both present, continue
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

    # Get value and prefilled status
    value, prefilled = get_field_value_and_prefilled_status(form_object, field)

    {
      form_object:,
      i18n_base:,
      field_label:,
      field_hint:,
      field_placeholder:,
      value:,
      prefilled:
    }
  end

  # Get field value and prefilled status
  def get_field_value_and_prefilled_status(form_object, field)
    # Return early if form doesn't have an object
    return [nil, false] unless form_object&.object

    model = form_object.object
    resolved = resolve_field_value(model, field)
    [resolved[:value], resolved[:prefilled]]
  end

  def format_numeric_value(value)
    return value unless value.is_a?(Numeric) || (value.is_a?(String) && value.match?(/\A-?\d*\.?\d+\z/))
    
    numeric_value = value.is_a?(Numeric) ? value : Float(value)
    # Convert to string and remove trailing zeros (e.g., 5.0 -> "5", 5.012000 -> "5.012")
    formatted = numeric_value.to_s.sub(/\.0+\z/, '').sub(/(\.\d*?)0+\z/, '\1')
    formatted
  rescue ArgumentError, TypeError
    value
  end

  def resolve_field_value(model, field, current_value = nil)
    field_str = field.to_s
    if field_str.include?("password") || field_str == "password_confirmation"
      return {value: nil, prefilled: false}
    end

    actual_current_value = model.send(field) if model.respond_to?(field)

    # If there's no previous inspection, use current value
    if !@previous_inspection
      formatted_value = format_numeric_value(actual_current_value)
      return {value: formatted_value, prefilled: false}
    end

    # For boolean fields (true/false), nil means "not set yet"
    # so we should prefill from previous inspection
    if actual_current_value.nil?
      previous_value = extract_previous_value(
        @previous_inspection,
        model,
        field
      )
      formatted_value = format_numeric_value(previous_value)
      {value: formatted_value, prefilled: true}
    else
      # Field has been explicitly set (even if false), so use current value
      formatted_value = format_numeric_value(actual_current_value)
      {value: formatted_value, prefilled: false}
    end
  end

  # Extract value from previous inspection, handling nested associations
  def extract_previous_value(previous_inspection, current_model, field)
    # If current model is an assessment, find the matching assessment type
    if current_model.class.name.include?("Assessment")
      assessment_type = current_model.class.name.demodulize.underscore
      previous_model = previous_inspection.send(assessment_type)
      previous_model&.send(field) if previous_model&.respond_to?(field)
    elsif previous_inspection.respond_to?(field)
      # Direct inspection field
      previous_inspection.send(field)
    end
  rescue
    nil
  end

  def comment_field_options(form, comment_field, base_field_label)
    model = form.object
    comment_value, comment_prefilled = get_field_value_and_prefilled_status(form, comment_field)

    actual_value = comment_prefilled ? comment_value : model.send(comment_field)
    has_comment = actual_value.present? || (comment_prefilled && comment_value.present?)

    # Get base field name by removing _comment suffix
    base_field = comment_field.to_s.chomp("_comment")

    # Extract complex interpolations to variables
    placeholder_text = t("shared.field_comment_placeholder", field: base_field_label)
    textarea_id = "#{base_field}_comment_textarea_#{model.object_id}"
    checkbox_id = "#{base_field}_has_comment_#{model.object_id}"
    display_style = has_comment ? "block" : "none"

    options = {
      rows: 2,
      placeholder: placeholder_text,
      id: textarea_id,
      style: "display: #{display_style};"
    }

    options[:value] = comment_value if comment_prefilled

    {
      options: options,
      prefilled: comment_prefilled,
      has_comment: has_comment,
      checkbox_id: checkbox_id
    }
  end

  def radio_button_options(prefilled, checked_value, expected_value)
    (prefilled && checked_value == expected_value) ? {checked: true} : {}
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
