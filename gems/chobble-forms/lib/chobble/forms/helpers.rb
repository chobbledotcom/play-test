require "action_view"

module Chobble
  module Forms
    module Helpers
      include ActionView::Helpers::NumberHelper
      def form_field_setup(field, local_assigns)
        validate_local_assigns(local_assigns)
        validate_form_context

        field_translations = build_field_translations(field)
        value, prefilled = get_field_value_and_prefilled_status(@_current_form,
          field)

        build_field_setup_result(field_translations, value, prefilled)
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
            !value.include?(".")
          value.to_i
        else
          value
        end
      end

      def comment_field_options(form, comment_field, base_field_label)
        raise ArgumentError, "form_object required" unless form
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

      ALLOWED_LOCAL_ASSIGNS = %i[
        accept
        field
        max
        min
        number_options
        options
        preview_size
        required
        rows
        step
        type
      ]

      def validate_local_assigns(local_assigns)
        if local_assigns[:field].present? &&
            local_assigns[:field].to_s.match?(/^[A-Z]/)
          raise ArgumentError, "Field names must be snake_case symbols, not class names. Use :field, not Field."
        end

        locally_assigned_keys = (local_assigns || {}).keys
        disallowed_keys = locally_assigned_keys - ALLOWED_LOCAL_ASSIGNS

        if disallowed_keys.any?
          raise ArgumentError, "local_assigns contains #{disallowed_keys.inspect}"
        end
      end

      def validate_form_context
        raise ArgumentError, "missing i18n_base" unless @_current_i18n_base
        raise ArgumentError, "missing form_object" unless @_current_form
      end

      def build_field_translations(field)
        fields_key = "#{@_current_i18n_base}.fields.#{field}"
        field_label = t(fields_key, raise: true)

        base_parts = @_current_i18n_base.split(".")
        root = base_parts[0..-2]
        hint_key = (root + ["hints", field]).join(".")
        placeholder_key = (root + ["placeholders", field]).join(".")

        {
          field_label:,
          field_hint: t(hint_key, default: nil),
          field_placeholder: t(placeholder_key, default: nil)
        }
      end

      def build_field_setup_result(field_translations, value, prefilled)
        {
          form_object: @_current_form,
          i18n_base: @_current_i18n_base,
          value:,
          prefilled:
        }.merge(field_translations)
      end

      def resolve_field_value(model, field)
        field_str = field.to_s

        # Never return values for password fields
        if field_str.include?("password")
          return {value: nil, prefilled: false}
        end

        # Check current model value
        current_value = model.send(field) if model.respond_to?(field)

        # Check if this field should be excluded from prefilling
        if defined?(InspectionsController::NOT_COPIED_FIELDS) &&
            InspectionsController::NOT_COPIED_FIELDS.include?(field_str)
          return {value: current_value, prefilled: false}
        end

        # Extract previous value if available
        previous_value = extract_previous_value(@previous_inspection, model, field)

        # Return previous value if current is nil and previous exists
        if current_value.nil? && !previous_value.nil?
          return {
            value: format_numeric_value(previous_value),
            prefilled: true
          }
        end

        if field_str.end_with?("_id") && field_str != "id"
          resolve_association_value(model, field_str)
        else
          # Always return current value, even if nil
          {value: current_value, prefilled: false}
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

      def resolve_association_value(model, field_str)
        base_name = field_str.chomp("_id")
        association_name = base_name.to_sym

        if model.respond_to?(association_name)
          {value: model.send(association_name), prefilled: true}
        elsif model.respond_to?(field_str)
          value = model.send(field_str)
          if value && model.class.reflect_on_association(association_name)
            associated = model.class
              .reflect_on_association(association_name)
              .klass.find_by(id: value)
            {value: associated, prefilled: true}
          else
            {value: value, prefilled: true}
          end
        else
          {value: nil, prefilled: false}
        end
      end
    end
  end
end
