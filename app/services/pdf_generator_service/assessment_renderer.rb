class PdfGeneratorService
  class AssessmentRenderer
    include Configuration

    SENSITIVE_COLUMNS = %w[id inspection_id created_at updated_at].freeze
    NULL_COLOR = "663399".freeze
    COMMENT_COLOR = "663399".freeze
    SECTION_TITLE_SIZE = 12
    SECTION_MARGIN_AFTER_TITLE = 15
    ASSESSMENT_MARGIN_AFTER_TITLE = 3
    ASSESSMENT_MARGIN_AFTER = 16
    SECTION_MARGIN_AFTER = 20

    attr_accessor :current_assessment_blocks, :current_assessment_fields, :used_compact_layout

    def initialize
      @current_assessment_blocks = []
      @used_compact_layout = false
      reset_assessment_context
    end

    private

    def reset_assessment_context
      @current_assessment_fields = nil
      @current_assessment_type = nil
      @current_assessment = nil
    end

    def render_fields_from_i18n
      ordered_fields = get_form_config_fields
      field_groups = group_assessment_fields(ordered_fields)
      field_groups.each { |base, fields| render_field_group(base, fields) }
    end

    def get_form_config_fields
      return [] unless @current_assessment.class.respond_to?(:form_fields)

      form_config = @current_assessment.class.form_fields
      ordered_fields = []

      form_config.each do |section|
        section[:fields].each do |field_config|
          field_name = field_config[:field]
          partial_name = field_config[:partial]
          next unless @current_assessment.respond_to?(field_name)

          # Add base field
          ordered_fields << field_name.to_sym

          # Use consolidated method to get composite fields
          composite_fields = FieldUtils.get_composite_fields(field_name, partial_name)
          composite_fields.each do |composite_field|
            ordered_fields << composite_field.to_sym if @current_assessment.respond_to?(composite_field)
          end
        end
      end

      ordered_fields
    end

    def render_field_group(base_name, fields)
      # For grouped fields, check i18n for base field; for standalone pass fields, check the pass field
      label_field = fields[:base] || fields[:pass]
      return unless label_field && has_any_i18n_label?(base_name, fields)

      [render_field_line(fields), render_comment_line(fields)].compact.each do |line|
        @current_assessment_fields << line
      end
    end

    def has_i18n_label?(field)
      I18n.exists?("forms.#{@current_assessment_type}.fields.#{field}")
    end

    def has_any_i18n_label?(base_name, fields)
      # Check if any of the field variants have an i18n label
      # Priority: base field, pass field, then base name
      fields[:base] && has_i18n_label?(fields[:base]) ||
        fields[:pass] && has_i18n_label?(fields[:pass]) ||
        has_i18n_label?(base_name)
    end

    def determine_pass_value(fields, main_field, value)
      return @current_assessment.send(fields[:pass]) if fields[:pass]
      return value if main_field.to_s.end_with?("_pass")
      nil
    end

    def format_field_line(label, value, pass_value, is_pass_field)
      parts = []
      # For boolean fields that aren't pass/fail fields, don't show pass/fail indicator
      if [true, false].include?(value) && !is_pass_field && pass_value.nil?
        # Just show the label and value for regular boolean fields
        parts << bold(label)
        parts << ": #{value ? "Yes" : "No"}"
      else
        parts << pass_fail_indicator(pass_value) unless pass_value.nil?
        parts << bold(label)
        parts << ": #{value}" if !is_pass_field && value.present?
      end
      parts.join
    end

    def pass_fail_indicator(pass_value)
      indicator, color = case pass_value
      when true, "pass" then [I18n.t("shared.pass_pdf"), Configuration::PASS_COLOR]
      when false, "fail" then [I18n.t("shared.fail_pdf"), Configuration::FAIL_COLOR]
      else [I18n.t("shared.na_pdf"), Configuration::NA_COLOR]
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
      # Try to get label in priority order: base field, pass field, base name
      label = get_field_label(fields)
      pass_value = determine_pass_value(fields, main_field, value)

      format_field_line(label, value, pass_value, main_field.to_s.end_with?("_pass"))
    end

    def get_field_label(fields)
      base_name = extract_base_field_name(fields[:pass].to_s) if fields[:pass]

      # Try in order: base field, pass field, base name
      if fields[:base] && has_i18n_label?(fields[:base])
        field_label(fields[:base])
      elsif fields[:pass] && has_i18n_label?(fields[:pass])
        field_label(fields[:pass])
      else
        field_label(base_name)
      end
    end

    def render_comment_line(fields)
      return unless fields[:comment]
      comment = @current_assessment.send(fields[:comment])
      return if comment.blank?

      "    #{colored(italic(comment), COMMENT_COLOR)}"
    end

    def generate_assessment_section(pdf, assessment_type, assessment)
      raise ArgumentError, "Assessment missing: #{assessment_type}" unless assessment

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

      # Calculate available height accounting for footer on first page
      available_height = if pdf.page_number == 1
        pdf.cursor - Configuration::FOOTER_HEIGHT
      else
        pdf.cursor
      end

      # Check if we have enough space for at least some content
      min_content_height = 100  # Minimum height for meaningful content
      if available_height < min_content_height
        pdf.start_new_page
        available_height = pdf.cursor
      end

      # Try adaptive rendering with overflow detection
      render_assessments_adaptively(pdf, available_height)

      @current_assessment_blocks = []
      pdf.move_down SECTION_MARGIN_AFTER
    end

    def render_assessment_block(pdf, block)
      pdf.text block[:title], size: ASSESSMENT_TITLE_SIZE, style: :bold
      pdf.move_down ASSESSMENT_MARGIN_AFTER_TITLE

      block[:fields].each { |field| pdf.text field, size: ASSESSMENT_FIELD_TEXT_SIZE, inline_format: true }
      pdf.move_down ASSESSMENT_MARGIN_AFTER
    end

    private

    def render_assessments_adaptively(pdf, available_height)
      # First, calculate photo boundary (top edge of unit photo)
      photo_boundary = calculate_photo_boundary(pdf)

      # Save the current state
      start_y = pdf.y

      # Try a dry run with 3 columns to check for overflow
      overflow = check_for_overflow(pdf, available_height, 3, 8, photo_boundary)

      # Reset cursor position
      pdf.y = start_y

      if overflow
        # Use 4 columns with smaller text
        render_assessments_with_params(pdf, available_height, ASSESSMENT_COLUMNS_COUNT, ASSESSMENT_FIELD_TEXT_SIZE)
        # Return true to indicate we used compact layout
        @used_compact_layout = true
      else
        # Use 3 columns with larger text
        render_assessments_with_params(pdf, available_height, 3, 8)
        @used_compact_layout = false
      end
    end

    def calculate_photo_boundary(pdf)
      # For boundary calculation, use the larger photo size (3 columns)
      # This ensures we check against where the photo WOULD be if we use 3 columns
      photo_width = Configuration::QR_CODE_SIZE * 2
      # Assume square photo for calculation (will be adjusted by aspect ratio later)
      photo_height = photo_width

      # Calculate photo position in bottom right corner
      # Account for footer height on first page
      if pdf.page_number == 1
        Configuration::FOOTER_HEIGHT + Configuration::QR_CODE_BOTTOM_OFFSET + photo_height
      else
        Configuration::QR_CODE_BOTTOM_OFFSET + photo_height
      end

      # Return the top edge of the photo (photo_y is the top edge in Prawn coordinates)
    end

    def check_for_overflow(pdf, available_height, columns, text_size, photo_boundary)
      overflow = false

      # Perform a dry run to check if content would overflow
      pdf.transaction do
        pdf.column_box([0, pdf.cursor], columns: columns, width: pdf.bounds.width, spacer: ASSESSMENT_COLUMN_SPACER, height: available_height) do
          @current_assessment_blocks.each do |block|
            # Check if we're in the third column
            column_width = (pdf.bounds.width - (ASSESSMENT_COLUMN_SPACER * (columns - 1))) / columns
            current_column = (pdf.bounds.absolute_left / (column_width + ASSESSMENT_COLUMN_SPACER)).floor

            # If in third column (index 2) and cursor would go below photo boundary
            if current_column == 2 && pdf.cursor < photo_boundary
              overflow = true
              raise Prawn::Errors::CannotFit # Force rollback
            end

            # Simulate rendering the block
            pdf.text block[:title], size: ASSESSMENT_TITLE_SIZE, style: :bold
            pdf.move_down ASSESSMENT_MARGIN_AFTER_TITLE

            block[:fields].each do |field|
              pdf.text field, size: text_size, inline_format: true
            end
            pdf.move_down ASSESSMENT_MARGIN_AFTER
          end
        end

        # Rollback the transaction
        pdf.rollback
      end

      overflow
    rescue Prawn::Errors::CannotFit
      true
    end

    def render_assessments_with_params(pdf, available_height, columns, text_size)
      pdf.column_box([0, pdf.cursor], columns: columns, width: pdf.bounds.width, spacer: ASSESSMENT_COLUMN_SPACER, height: available_height) do
        @current_assessment_blocks.each do |block|
          pdf.text block[:title], size: ASSESSMENT_TITLE_SIZE, style: :bold
          pdf.move_down ASSESSMENT_MARGIN_AFTER_TITLE

          block[:fields].each do |field|
            pdf.text field, size: text_size, inline_format: true
          end
          pdf.move_down ASSESSMENT_MARGIN_AFTER
        end
      end
    end
  end
end
