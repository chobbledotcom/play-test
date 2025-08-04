class PdfGeneratorService
  class AssessmentBlockRenderer
    include Configuration

    ASSESSMENT_MARGIN_AFTER_TITLE = 3
    ASSESSMENT_TITLE_SIZE = 9
    ASSESSMENT_FIELD_TEXT_SIZE = 7

    # Calculate column width (1/4 of page width minus spacing)
    PAGE_WIDTH = 595.28 - (2 * 36) # A4 width minus margins
    TOTAL_SPACER_WIDTH = Configuration::ASSESSMENT_COLUMN_SPACER * 3
    COLUMN_WIDTH = (PAGE_WIDTH - TOTAL_SPACER_WIDTH) / 4.0

    def initialize(font_size: ASSESSMENT_FIELD_TEXT_SIZE)
      @font_size = font_size
    end

    def render(block)
      case block.type
      when :header
        render_header(block)
      when :value
        render_value(block)
      when :comment
        render_comment(block)
      else
        raise ArgumentError, "Unknown block type: #{block.type}"
      end
    end

    def font_size_for(block)
      block.header? ? ASSESSMENT_TITLE_SIZE : @font_size
    end

    def height_for(block, pdf)
      # Get the rendered text
      text = render(block)

      # Return 0 height for empty text (like blank comments)
      return 0 if text.blank?

      font_size = font_size_for(block)

      # Create a text box and render with dry_run to measure using actual PDF
      box = Prawn::Text::Box.new(
        text,
        document: pdf,
        at: [0, pdf.cursor],
        width: COLUMN_WIDTH,
        size: font_size,
        inline_format: true
      )

      # Render with dry_run to calculate height without actually drawing
      box.render(dry_run: true)

      # Get the actual height used
      box.height
    end

    private

    def render_header(block)
      bold(block.name || block.value)
    end

    def render_value(block)
      parts = []

      # Add pass/fail indicator if present
      if !block.pass_fail.nil?
        parts << pass_fail_indicator(block.pass_fail)
      end

      # Add field name
      parts << bold(block.name) if block.name

      # Add value if present and not a pass/fail field
      if block.value && !block.name.to_s.end_with?("_pass")
        parts << ": #{block.value}"
      end

      parts.join
    end

    def render_comment(block)
      return "" if block.comment.blank?

      "<font name='Courier'>#{colored(italic(block.comment), Configuration::HEADER_COLOR)}</font>"
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
  end
end
