class PdfGeneratorService
  class FieldFormatter
    include Configuration

    # Generic field rendering method that handles all field types
    def self.add_field(fields_array, assessment, field_name, assessment_type, options = {})
      # Extract options with defaults
      unit = options[:unit]
      pass_field = options[:pass_field]
      custom_label = options[:label]
      custom_text = options[:text]

      # Get the label
      label = custom_label || I18n.t("inspections.assessments.#{assessment_type}.fields.#{field_name}")

      # Get the value
      value = assessment.send(field_name) unless custom_text

      # Format the value based on field type
      formatted_value = if custom_text
        custom_text
      elsif unit
        Utilities.format_measurement(value, unit)
      elsif field_name.to_s.include?("_pass")
        Utilities.format_pass_fail(value)
      elsif [true, false].include?(value)
        value ? I18n.t("shared.yes") : I18n.t("shared.no")
      else
        value || I18n.t("pdf.inspection.fields.na")
      end

      # Build the text parts
      text_parts = []
      text_parts << "#{label}:" unless custom_text
      text_parts << formatted_value

      # Add pass/fail if specified
      if pass_field
        pass_fail = assessment.send(pass_field)
        text_parts << "-"
        text_parts << Utilities.format_pass_fail(pass_fail)
      end

      # Add comment if it exists
      comment_field = derive_comment_field_name(field_name, pass_field)
      if assessment.respond_to?(comment_field)
        comment = assessment.send(comment_field)
        text_parts << comment if comment.present?
      end

      # Add to the fields array
      field_text = text_parts.join(" ")
      fields_array << field_text
    end

    # Derive the comment field name based on the main field or pass field
    def self.derive_comment_field_name(field_name, pass_field = nil)
      base_name = if pass_field
        # Use pass field as base, removing _pass suffix
        pass_field.to_s.gsub(/_pass$/, "")
      else
        # Use field name as base, removing _pass suffix if present
        field_name.to_s.gsub(/_pass$/, "")
      end
      "#{base_name}_comment"
    end

    # Wrapper methods for backward compatibility and clarity
    def self.add_field_with_comment(fields_array, assessment, field_name, unit, assessment_type)
      add_field(fields_array, assessment, field_name, assessment_type, unit: unit)
    end

    def self.add_boolean_field_with_comment(fields_array, assessment, field_name, assessment_type)
      add_field(fields_array, assessment, field_name, assessment_type)
    end

    def self.add_pass_fail_field_with_comment(fields_array, assessment, field_name, assessment_type)
      add_field(fields_array, assessment, field_name, assessment_type)
    end

    def self.add_measurement_pass_fail_field(fields_array, assessment, value_field, unit, pass_field, assessment_type)
      add_field(fields_array, assessment, value_field, assessment_type, unit: unit, pass_field: pass_field)
    end

    def self.add_text_pass_fail_field(fields_array, text, assessment, pass_field)
      pass_fail = assessment.send(pass_field)
      # Remove _pass suffix to get the base field name for comment
      base_field_name = pass_field.to_s.gsub(/_pass$/, "")
      comment = assessment.send("#{base_field_name}_comment") if assessment.respond_to?("#{base_field_name}_comment")
      full_text = "#{text} - #{Utilities.format_pass_fail(pass_fail)} #{comment}".strip
      fields_array << full_text
    end
  end
end
