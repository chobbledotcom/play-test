class PdfGeneratorService
  class AssessmentRenderer
    include Configuration

    SENSITIVE_COLUMNS = %w[id inspection_id created_at updated_at].freeze
    PASS_COLOR = "00AA00".freeze
    FAIL_COLOR = "CC0000".freeze
    NULL_COLOR = "663399".freeze
    COMMENT_COLOR = "663399".freeze
    SECTION_TITLE_SIZE = 12
    ASSESSMENT_TITLE_SIZE = 10
    FIELD_TEXT_SIZE = 8
    SECTION_MARGIN_AFTER_TITLE = 15
    ASSESSMENT_MARGIN_AFTER_TITLE = 3
    ASSESSMENT_MARGIN_AFTER = 16
    SECTION_MARGIN_AFTER = 20
    COLUMN_COUNT = 3
    COLUMN_SPACER = 10

    attr_accessor :current_assessment_blocks, :current_assessment_fields

    def initialize
      @current_assessment_blocks = []
      reset_assessment_context
    end

    private

    def reset_assessment_context
      @current_assessment_fields = nil
      @current_assessment_type = nil
      @current_assessment = nil
    end

    def render_fields_from_i18n
      available_columns = @current_assessment.attributes.keys - SENSITIVE_COLUMNS
      field_groups = group_assessment_fields(available_columns.map(&:to_sym))
      field_groups.each { |base, fields| render_field_group(base, fields) }
    end

    def render_field_group(base_name, fields)
      # For grouped fields, check i18n for base field; for standalone pass fields, check the pass field
      label_field = fields[:base] || fields[:pass]
      return unless label_field && has_i18n_label?(label_field)

      [render_field_line(fields), render_comment_line(fields)].compact.each do |line|
        @current_assessment_fields << line
      end
    end

    def has_i18n_label?(field)
      I18n.exists?("forms.#{@current_assessment_type}.fields.#{field}")
    end

    def determine_pass_value(fields, main_field, value)
      return @current_assessment.send(fields[:pass]) if fields[:pass]
      return value if main_field.to_s.end_with?("_pass")
      nil
    end

    def format_field_line(label, value, pass_value, is_pass_field)
      parts = []
      parts << pass_fail_indicator(pass_value) if is_pass_field
      parts << bold(label)
      parts << ": #{value}" if !is_pass_field && value.present?
      parts.join
    end

    def pass_fail_indicator(pass_value)
      indicator, color =
        if pass_value.nil?
          ["[NULL]", NULL_COLOR]
        else
          [
            pass_fail(pass_value).to_s,
            pass_value ? PASS_COLOR : FAIL_COLOR
          ]
        end
      "<font name='Courier'>#{bold(colored(indicator, color))}</font> "
    end

    def colored(text, color) = "<color rgb='#{color}'>#{text}</color>"

    def bold(text) = "<b>#{text}</b>"

    def italic(text) = "<i>#{text}</i>"

    def field_label(field_name) = I18n.t!("forms.#{@current_assessment_type}.fields.#{field_name}")

    def pass_fail(value) = I18n.t(value ? "shared.pass_pdf" : "shared.fail_pdf")

    public

    def extract_base_field_name(field_str)
      field_str.sub(/_(pass|comment)$/, "")
    end

    def group_assessment_fields(field_keys)
      field_keys.each_with_object({}) do |field, groups|
        field_str = field.to_s
        next unless @current_assessment.respond_to?(field_str)

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

    def render_field_line(fields)
      main_field = fields[:base] || fields[:pass]
      return unless main_field

      value = @current_assessment.send(main_field)
      # Use base field label when available, otherwise use pass field label
      label_field = fields[:base] || fields[:pass]
      label = field_label(label_field)
      pass_value = determine_pass_value(fields, main_field, value)

      format_field_line(label, value, pass_value, main_field.to_s.end_with?("_pass"))
    end

    def render_comment_line(fields)
      return unless fields[:comment]
      comment = @current_assessment.send(fields[:comment])
      return unless comment.present?

      "    #{colored(italic(comment), COMMENT_COLOR)}"
    end

    def generate_assessment_section(pdf, assessment_type, assessment)
      raise "Assessment missing: #{assessment_type}" unless assessment

      @current_assessment_type = assessment_type
      @current_assessment = assessment
      @current_assessment_fields = []

      render_fields_from_i18n

      @current_assessment_blocks << {
        title: I18n.t("forms.#{assessment_type}.header"),
        fields: @current_assessment_fields
      }
    end

    def render_all_assessments_in_columns(pdf)
      return if @current_assessment_blocks.empty?

      pdf.text I18n.t("pdf.inspection.assessments_section"), size: SECTION_TITLE_SIZE, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down SECTION_MARGIN_AFTER_TITLE

      pdf.column_box([0, pdf.cursor], columns: COLUMN_COUNT, width: pdf.bounds.width, spacer: COLUMN_SPACER) do
        @current_assessment_blocks.each { |block| render_assessment_block(pdf, block) }
      end

      @current_assessment_blocks = []
      pdf.move_down SECTION_MARGIN_AFTER
    end

    def render_assessment_block(pdf, block)
      pdf.text block[:title], size: ASSESSMENT_TITLE_SIZE, style: :bold
      pdf.move_down ASSESSMENT_MARGIN_AFTER_TITLE

      block[:fields].each { |field| pdf.text field, size: FIELD_TEXT_SIZE, inline_format: true }
      pdf.move_down ASSESSMENT_MARGIN_AFTER
    end
  end
end
