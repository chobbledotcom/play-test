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
      blocks = [create_header_block]
      field_groups = group_assessment_fields(get_form_config_fields)
      field_groups.each { |base, fields| process_field_group(blocks, fields) }
      blocks
    end

    private

    def create_header_block
      AssessmentBlock.new(
        type: :header,
        name: I18n.t("forms.#{@assessment_type}.header")
      )
    end

    def process_field_group(blocks, fields)
      main_field = fields[:base] || fields[:pass]
      return if main_field && field_is_not_applicable?(main_field)

      add_value_block(blocks, fields, main_field) if main_field
      add_standalone_comment_label(blocks, fields) if fields[:comment] && !main_field
      add_comment_block(blocks, fields) if fields[:comment]
    end

    def add_value_block(blocks, fields, main_field)
      value = @assessment.send(main_field)
      label = get_field_label(fields)
      pass_value = determine_pass_value(fields, main_field, value)
      is_pass_field = main_field.to_s.end_with?("_pass")
      is_bool_non_pass = boolean_non_pass_field?(value, is_pass_field, pass_value)

      blocks << if is_bool_non_pass
        create_boolean_block(label, value)
      else
        create_standard_block(label, pass_value, is_pass_field, value)
      end
    end

    def boolean_non_pass_field?(value, is_pass_field, pass_value)
      [true, false].include?(value) && !is_pass_field && pass_value.nil?
    end

    def create_boolean_block(label, value)
      AssessmentBlock.new(
        type: :value,
        name: label,
        value: value ? I18n.t("shared.yes") : I18n.t("shared.no")
      )
    end

    def create_standard_block(label, pass_value, is_pass_field, value)
      AssessmentBlock.new(
        type: :value,
        pass_fail: pass_value,
        name: label,
        value: is_pass_field ? nil : value
      )
    end

    def add_standalone_comment_label(blocks, fields)
      comment = @assessment.send(fields[:comment])
      return unless comment.present?

      blocks << AssessmentBlock.new(
        type: :value,
        name: get_field_label(fields),
        value: nil
      )
    end

    def add_comment_block(blocks, fields)
      comment = @assessment.send(fields[:comment])
      return unless comment.present?

      blocks << AssessmentBlock.new(
        type: :comment,
        comment: comment
      )
    end

    def get_form_config_fields
      return [] unless @assessment.class.respond_to?(:form_fields)

      ordered_fields = []
      @assessment.class.form_fields.each do |section|
        section[:fields].each do |field_config|
          add_field_and_composites(ordered_fields, field_config)
        end
      end
      ordered_fields
    end

    def add_field_and_composites(ordered_fields, field_config)
      field_name = field_config[:field]
      partial_name = field_config[:partial]
      composite_fields = ChobbleForms::FieldUtils.get_composite_fields(field_name, partial_name)

      has_base = @assessment.respond_to?(field_name)
      has_composites = composite_fields.any? { |cf| @assessment.respond_to?(cf) }
      return unless has_base || has_composites

      ordered_fields << field_name if has_base
      composite_fields.each { |cf| ordered_fields << cf if @assessment.respond_to?(cf) }
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
