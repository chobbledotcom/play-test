# typed: false

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

    def render_fragments(block)
      case block.type
      when :header
        render_header_fragments(block)
      when :value
        render_value_fragments(block)
      when :comment
        render_comment_fragments(block)
      else
        raise ArgumentError, "Unknown block type: #{block.type}"
      end
    end

    def font_size_for(block)
      block.header? ? ASSESSMENT_TITLE_SIZE : @font_size
    end

    def height_for(block, pdf)
      fragments = render_fragments(block)
      return 0 if fragments.empty?

      font_size = font_size_for(block)

      # Convert fragments to formatted text array
      formatted_text = fragments.map do |fragment|
        styles = []
        styles << :bold if fragment[:bold]
        styles << :italic if fragment[:italic]

        {
          text: fragment[:text],
          styles: styles,
          color: fragment[:color]
        }
      end

      # Use height_of_formatted to get the actual height with wrapping
      base_height = pdf.height_of_formatted(
        formatted_text,
        width: COLUMN_WIDTH,
        size: font_size
      )

      # Add 33% of font size as spacing
      spacing = (font_size * 0.33).round(1)
      base_height + spacing
    end

    private

    def render_header_fragments(block)
      text = block.name || block.value
      [{text: text, bold: true, color: "000000"}]
    end

    def render_value_fragments(block)
      fragments = []

      # Add pass/fail indicator if present
      if !block.pass_fail.nil?
        indicator, color = case block.pass_fail
        when true, "pass" then [I18n.t("shared.pass_pdf"), Configuration::PASS_COLOR]
        when false, "fail" then [I18n.t("shared.fail_pdf"), Configuration::FAIL_COLOR]
        else [I18n.t("shared.na_pdf"), Configuration::NA_COLOR]
        end
        fragments << {text: "#{indicator} ", bold: true, color: color}
      end

      # Add field name
      if block.name
        fragments << {text: block.name, bold: true, color: "000000"}
      end

      # Add value if present and not a pass/fail field
      if block.value && !block.name.to_s.end_with?("_pass")
        fragments << {text: ": #{block.value}", bold: false, color: "000000"}
      end

      fragments
    end

    def render_comment_fragments(block)
      return [] if block.comment.blank?

      [{text: block.comment, bold: false, color: Configuration::HEADER_COLOR, italic: true}]
    end
  end
end
