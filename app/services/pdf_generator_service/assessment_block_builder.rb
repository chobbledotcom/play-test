class PdfGeneratorService
  class AssessmentBlockBuilder
    include Configuration

    def self.build_from_assessment(assessment_type, assessment)
      new(assessment_type, assessment).build
    end

    def initialize(assessment_type, assessment)
      @assessment_type = assessment_type
      @assessment = assessment
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
        # Add value block
        main_field = fields[:base] || fields[:pass]
        next unless main_field

        value = @assessment.send(main_field)
        label = get_field_label(fields)
        pass_value = determine_pass_value(fields, main_field, value)
        is_pass_field = main_field.to_s.end_with?("_pass")

        # For boolean fields that aren't pass/fail fields
        blocks << if [true, false].include?(value) && !is_pass_field && pass_value.nil?
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
          next unless @assessment.respond_to?(field_name)

          # Add base field
          ordered_fields << field_name.to_sym

          # Use consolidated method to get composite fields
          composite_fields = FieldUtils.get_composite_fields(field_name, partial_name)
          composite_fields.each do |composite_field|
            ordered_fields << composite_field.to_sym if @assessment.respond_to?(composite_field)
          end
        end
      end

      ordered_fields
    end

    def group_assessment_fields(field_keys)
      field_keys.each_with_object({}) do |field, groups|
        field_str = field.to_s
        next unless @assessment.respond_to?(field_str)

        base_field = extract_base_field_name(field_str)
        groups[base_field] ||= {}

        field_type = case field_str
        when /pass$/ then :pass
        when /comment$/ then :comment
        else :base
        end

        groups[base_field][field_type] = field
      end
    end

    def extract_base_field_name(field_str)
      field_str.sub(/_(pass|comment)$/, "")
    end

    def get_field_label(fields)
      base_name = extract_base_field_name(fields[:pass].to_s) if fields[:pass]

      # Try in order: base field, pass field, base name
      if fields[:base]
        field_label(fields[:base])
      elsif fields[:pass]
        field_label(fields[:pass])
      else
        field_label(base_name)
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
  end
end
