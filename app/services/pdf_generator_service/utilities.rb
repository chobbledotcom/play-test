class PdfGeneratorService
  class Utilities
    include Configuration

    def self.truncate_text(text, max_length)
      return "" if text.nil?
      (text.length > max_length) ? "#{text[0...max_length]}..." : text
    end

    def self.format_dimension(value)
      return "" if value.nil?
      value.to_s.sub(/\.0$/, "")
    end

    def self.format_pass_fail(value)
      case value
      when true then I18n.t("shared.pass")
      when false then I18n.t("shared.fail")
      else I18n.t("pdf.inspection.fields.na")
      end
    end

    def self.format_measurement(value, unit = "")
      return I18n.t("pdf.inspection.fields.na") if value.nil?
      "#{value}#{unit}"
    end

    def self.add_draft_watermark(pdf)
      # Add 3x3 grid of DRAFT watermarks to each page
      (1..pdf.page_count).each do |page_num|
        pdf.go_to_page(page_num)

        pdf.transparent(WATERMARK_TRANSPARENCY) do
          pdf.fill_color "FF0000"

          # 3x3 grid positions
          y_positions = [0.10, 0.30, 0.50, 0.70, 0.9].map { |pct| pdf.bounds.height * pct }
          x_positions = [0.15, 0.50, 0.85].map { |pct| pdf.bounds.width * pct - (WATERMARK_WIDTH / 2) }

          y_positions.each do |y|
            x_positions.each do |x|
              pdf.text_box I18n.t("pdf.inspection.watermark.draft"),
                at: [x, y],
                width: WATERMARK_WIDTH,
                height: WATERMARK_HEIGHT,
                size: WATERMARK_TEXT_SIZE,
                style: :bold,
                align: :center,
                valign: :top
            end
          end
        end

        pdf.fill_color "000000"
      end
    end
  end
end
