# typed: false
# frozen_string_literal: true

class PdfGeneratorService
  class DisclaimerFooterRenderer
    include Configuration

    def self.render_disclaimer_footer(pdf, user, unbranded: false)
      return if unbranded

      original_y = pdf.cursor
      pdf.move_cursor_to FOOTER_HEIGHT

      render_footer_in_bounding_box(pdf, user)
      pdf.move_cursor_to original_y
    end

    def self.render_footer_in_bounding_box(pdf, user)
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: FOOTER_HEIGHT) do
        pdf.move_down FOOTER_TOP_PADDING
        render_footer_content(pdf, user)
      end
    end

    def self.measure_footer_height(unbranded:)
      unbranded ? 0 : FOOTER_HEIGHT
    end

    def self.render_footer_content(pdf, user)
      render_disclaimer_header(pdf)
      pdf.move_down FOOTER_INTERNAL_PADDING

      has_signature = user&.signature&.attached?
      has_user_logo = check_has_user_logo(user)

      first_row = build_footer_first_row(pdf, user, has_signature, has_user_logo)
      table_data = [first_row]

      pdf.table(table_data) { |t| t.cells.borders = [] }
    end

    def self.check_has_user_logo(user)
      pdf_logo = Rails.configuration.pdf.logo
      pdf_logo.present? && user&.logo&.attached?
    end

    def self.build_footer_first_row(pdf, user, has_signature, has_user_logo)
      first_row = [build_disclaimer_cell(pdf, has_signature, has_user_logo)]
      first_row << build_signature_cell(pdf, user, has_user_logo) if has_signature
      first_row << build_logo_cell(pdf, user) if has_user_logo
      first_row
    end

    def self.build_disclaimer_cell(pdf, has_signature, has_user_logo)
      pdf.make_cell(
        content: I18n.t("pdf.disclaimer.text"),
        size: DISCLAIMER_TEXT_SIZE,
        inline_format: true,
        valign: :top,
        padding: [0, (has_signature || has_user_logo) ? 10 : 0, 0, 0]
      )
    end

    def self.build_signature_cell(pdf, user, has_user_logo)
      pdf.make_cell(
        image: StringIO.new(user.signature.download),
        fit: [100, DISCLAIMER_TEXT_HEIGHT],
        width: 100,
        borders: %i[top bottom left right],
        border_color: "CCCCCC",
        border_width: 1,
        padding: 5,
        padding_right: has_user_logo ? 10 : 5,
        padding_left: 5
      )
    end

    def self.build_logo_cell(pdf, user)
      pdf.make_cell(
        image: StringIO.new(user.logo.download),
        fit: [1000, DISCLAIMER_TEXT_HEIGHT],
        borders: [],
        padding: [0, 0, 0, 10]
      )
    end

    def self.render_disclaimer_header(pdf)
      pdf.text I18n.t("pdf.disclaimer.header"),
        size: DISCLAIMER_HEADER_SIZE,
        style: :bold
      pdf.stroke_horizontal_rule
    end
  end
end
