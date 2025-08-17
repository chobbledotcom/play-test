# typed: false

class PdfGeneratorService
  class AssessmentBlockBuilder
    include Configuration

    def self.build_from_assessment(assessment_type, assessment)
      new(assessment_type, assessment).build
    end

    def initialize(assessment_type, assessment)
      @assessment_type = assessment_type
      @assessment = assessment
      @not_applicable_fields = get_not_applicable_fields
    end

    def build
      blocks = []

      # Add header block
      blocks << AssessmentBlock.new(
        type: :header,
        name: I18n.t("forms.#{@assessment_type}.header")
      )

      # Process fields
      ordered_fields = get_form_config_fields
      field_groups = group_assessment_fields(ordered_fields)

      field_groups.each do |base, fields|
        # Skip if this is a not-applicable field with value 0
        main_field = fields[:base] || fields[:pass]
        if main_field && field_is_not_applicable?(main_field)
          next
        end

        # Add value block
        if main_field
          value = @assessment.send(main_field)
          label = get_field_label(fields)
          pass_value = determine_pass_value(fields, main_field, value)
          is_pass_field = main_field.to_s.end_with?("_pass")

          # For boolean fields that aren't pass/fail fields
          is_bool_non_pass = [true, false].include?(value) &&
            !is_pass_field && pass_value.nil?
          blocks << if is_bool_non_pass
            AssessmentBlock.new(
              type: :value,
              name: label,
              value: value ? I18n.t("shared.yes") : I18n.t("shared.no")
            )
          else
            AssessmentBlock.new(
              type: :value,
              pass_fail: pass_value,
              name: label,
              value: is_pass_field ? nil : value
            )
          end
        elsif fields[:comment]
          # Handle standalone comment fields (no base or pass field)
          label = get_field_label(fields)
          comment = @assessment.send(fields[:comment])
          if comment.present?
            # Add a label block for the standalone comment
            blocks << AssessmentBlock.new(
              type: :value,
              name: label,
              value: nil
            )
          end
        end

        # Add comment block if present
        if fields[:comment]
          comment = @assessment.send(fields[:comment])
          if comment.present?
            blocks << AssessmentBlock.new(
              type: :comment,
              comment: comment
            )
          end
        end
      end

      blocks
    end

    private

    def get_form_config_fields
      return [] unless @assessment.class.respond_to?(:form_fields)

      form_config = @assessment.class.form_fields
      ordered_fields = []

      form_config.each do |section|
        section[:fields].each do |field_config|
          field_name = field_config[:field]
          partial_name = field_config[:partial]

          # Get composite fields first to check if any exist
          composite_fields = ChobbleForms::FieldUtils.get_composite_fields(field_name, partial_name)

          # Skip if neither the base field nor any composite fields exist
          has_base = @assessment.respond_to?(field_name)
          has_composites = composite_fields.any? { |cf| @assessment.respond_to?(cf) }
          next unless has_base || has_composites

          # Add base field if it exists
          ordered_fields << field_name if has_base

          # Add composite fields that exist
          composite_fields.each do |composite_field|
            ordered_fields << composite_field if @assessment.respond_to?(composite_field)
          end
        end
      end

      ordered_fields
    end

    def group_assessment_fields(field_keys)
      field_keys.each_with_object({}) do |field, groups|
        field_str = field.to_s
        next unless @assessment.respond_to?(field_str)

        base_field = ChobbleForms::FieldUtils.strip_field_suffix(field)
        groups[base_field] ||= {}

        field_type = case field_str
        when /pass$/ then :pass
        when /comment$/ then :comment
        else :base
        end

        groups[base_field][field_type] = field
      end
    end

    def get_field_label(fields)
      # Try in order: base field, pass field, comment field
      if fields[:base]
        field_label(fields[:base])
      elsif fields[:pass]
        # For pass fields, use the base field name for the label
        base_name = ChobbleForms::FieldUtils.strip_field_suffix(fields[:pass])
        field_label(base_name)
      elsif fields[:comment]
        # For standalone comment fields, use the base field name
        base_name = ChobbleForms::FieldUtils.strip_field_suffix(fields[:comment])
        field_label(base_name)
      else
        raise "No valid fields found: #{fields}"
      end
    end

    def field_label(field_name)
      I18n.t!("forms.#{@assessment_type}.fields.#{field_name}")
    end

    def determine_pass_value(fields, main_field, value)
      return @assessment.send(fields[:pass]) if fields[:pass]
      return value if main_field.to_s.end_with?("_pass")
      nil
    end

    def get_not_applicable_fields
      return [] unless @assessment.class.respond_to?(:form_fields)

      @assessment.class.form_fields
        .flat_map { |section| section[:fields] }
        .select { |field| field[:attributes]&.dig(:add_not_applicable) }
        .map { |field| field[:field].to_sym }
    end

    def field_is_not_applicable?(field)
      return false unless @not_applicable_fields.include?(field)

      value = @assessment.send(field)
      # Field is not applicable if it has add_not_applicable and value is 0
      value.present? && value.to_i == 0
    end
  end
end
