module ApplicationHelper
  include ActionView::Helpers::NumberHelper

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

    i18n_base = @_current_i18n_base
    form_object = @_current_form

    raise ArgumentError, "missing i18n_base" unless i18n_base
    raise ArgumentError, "missing form_object" unless form_object

    fields_key = "#{i18n_base}.fields.#{field}"

    field_label = t(fields_key, raise: true)

    base_parts = i18n_base.split(".")
    root = base_parts[0..-2]
    hint_key = (root + ["hints", field]).join(".")
    placeholder_key = (root + ["placeholders", field]).join(".")

    field_hint = t(hint_key, default: nil)
    field_placeholder = t(placeholder_key, default: nil)

    value, prefilled = get_field_value_and_prefilled_status(
      form_object,
      field
    )

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

  def get_field_value_and_prefilled_status(form_object, field)
    return [nil, false] unless form_object&.object
    model = form_object.object
    resolved = resolve_field_value(model, field)
    [resolved[:value], resolved[:prefilled]]
  end

  def format_numeric_value(value)
    if value.is_a?(String) &&
        value.match?(/\A-?\d*\.?\d+\z/) &&
        (float_value = Float(value, exception: false))
      value = float_value
    end

    return value unless value.is_a?(Numeric)

    number_with_precision(
      value,
      precision: 4,
      strip_insignificant_zeros: true
    )
  end

  def resolve_field_value(model, field)
    field_str = field.to_s
    if field_str.include?("password")
      return {
        value: nil,
        prefilled: false
      }
    end

    actual_current_value = model.send(field) if model.respond_to?(field)

    # Check if this field should be excluded from prefilling
    # Use the same exclusion list as the controller
    if InspectionsController::NOT_COPIED_FIELDS.include?(field_str)
      return {
        value: actual_current_value,
        prefilled: false
      }
    end

    previous_value = extract_previous_value(
      @previous_inspection,
      model,
      field
    )

    if actual_current_value.nil? && !previous_value.nil?
      {
        value: format_numeric_value(previous_value),
        prefilled: !previous_value.nil?
      }
    else
      {
        value: format_numeric_value(actual_current_value),
        prefilled: false
      }
    end
  end

  def extract_previous_value(previous_inspection, current_model, field)
    if !previous_inspection
      nil
    elsif current_model.class.name.include?("Assessment")
      assessment_type = current_model.class.name.demodulize.underscore
      previous_model = previous_inspection.send(assessment_type)
      previous_model&.send(field)
    else
      previous_inspection.send(field)
    end
  end

  def comment_field_options(form, comment_field, base_field_label)
    model = form.object
    comment_value, comment_prefilled =
      get_field_value_and_prefilled_status(
        form,
        comment_field
      )

    has_comment = comment_value.present?

    base_field = comment_field.to_s.chomp("_comment")

    placeholder_text = t("shared.field_comment_placeholder", field: base_field_label)
    textarea_id = "#{base_field}_comment_textarea_#{model.object_id}"
    checkbox_id = "#{base_field}_has_comment_#{model.object_id}"
    display_style = has_comment ? "block" : "none"

    {
      options: {
        rows: 2,
        placeholder: placeholder_text,
        id: textarea_id,
        style: "display: #{display_style};",
        value: comment_value
      },
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
    route = Rails.application.routes.recognize_path(path)
    path_controller = route[:controller]
    controller_name == path_controller
  rescue ActionController::RoutingError
    false
  end
end
