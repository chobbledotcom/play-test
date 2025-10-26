# typed: false

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

    def self.format_date(date)
      return I18n.t("pdf.inspection.fields.na") if date.nil?
      date.strftime(I18n.t("date.formats.pdf"))
    end

    def self.format_pass_fail(value)
      case value
      when true then I18n.t("shared.pass_pdf")
      when false then I18n.t("shared.fail_pdf")
      else I18n.t("pdf.inspection.fields.na")
      end
    end

    def self.format_measurement(value, unit = "")
      return I18n.t("pdf.inspection.fields.na") if value.nil?
      "#{value}#{unit}"
    end

    def self.add_draft_watermark(pdf)
      (1..pdf.page_count).each do |page_num|
        pdf.go_to_page(page_num)
        render_watermark_grid(pdf)
        pdf.fill_color "000000"
      end
    end

    def self.render_watermark_grid(pdf)
      pdf.transparent(WATERMARK_TRANSPARENCY) do
        pdf.fill_color "FF0000"
        y_positions = calculate_watermark_y_positions(pdf)
        x_positions = calculate_watermark_x_positions(pdf)
        render_watermark_at_positions(pdf, y_positions, x_positions)
      end
    end

    def self.calculate_watermark_y_positions(pdf)
      [0.10, 0.30, 0.50, 0.70, 0.9].map { pdf.bounds.height * _1 }
    end

    def self.calculate_watermark_x_positions(pdf)
      [0.15, 0.50, 0.85].map { pdf.bounds.width * _1 - (WATERMARK_WIDTH / 2) }
    end

    def self.render_watermark_at_positions(pdf, y_positions, x_positions)
      y_positions.each do |y|
        x_positions.each do |x|
          render_watermark_text(pdf, x, y)
        end
      end
    end

    def self.render_watermark_text(pdf, x, y)
      pdf.text_box(
        I18n.t("pdf.inspection.watermark.draft"),
        at: [x, y],
        width: WATERMARK_WIDTH,
        height: WATERMARK_HEIGHT,
        size: WATERMARK_TEXT_SIZE,
        style: :bold,
        align: :center,
        valign: :top
      )
    end
  end
end
