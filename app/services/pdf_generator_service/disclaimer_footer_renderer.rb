# typed: false
# frozen_string_literal: true

class PdfGeneratorService
  class DisclaimerFooterRenderer
    include Configuration

    def self.render_disclaimer_footer(pdf, user)
      return unless should_render_footer?(pdf)

      # Save current position
      original_y = pdf.cursor

      # Move to footer position
      footer_y = FOOTER_HEIGHT
      pdf.move_cursor_to footer_y

      # Create bounding box for footer
      bounding_box_width = pdf.bounds.width
      bounding_box_at = [0, pdf.cursor]
      pdf.bounding_box(bounding_box_at,
        width: bounding_box_width,
        height: FOOTER_HEIGHT) do
        # Add top padding
        pdf.move_down FOOTER_TOP_PADDING
        render_footer_content(pdf, user)
      end

      # Restore position
      pdf.move_cursor_to original_y
    end

    def self.measure_footer_height(pdf)
      return 0 unless should_render_footer?(pdf)

      FOOTER_HEIGHT
    end

    def self.should_render_footer?(pdf)
      # Only render on first page
      pdf.page_number == 1
    end

    def self.render_footer_content(pdf, user)
      # Render disclaimer header
      render_disclaimer_header(pdf)

      pdf.move_down FOOTER_INTERNAL_PADDING

      # Check what content we have
      has_signature = user&.signature&.attached?
      has_user_logo = ENV["PDF_LOGO"].present? && user&.logo&.attached?
      pdf.bounds.width

      first_row = [
        pdf.make_cell(
          content: I18n.t("pdf.disclaimer.text"),
          size: DISCLAIMER_TEXT_SIZE,
          inline_format: true,
          valign: :top,
          padding: [0, (has_signature || has_user_logo) ? 10 : 0, 0, 0]
        )
      ]

      if has_signature
        first_row << pdf.make_cell(
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

      if has_user_logo
        first_row << pdf.make_cell(
          image: StringIO.new(user.logo.download),
          fit: [1000, DISCLAIMER_TEXT_HEIGHT],
          borders: [],
          padding: [0, 0, 0, 10]
        )
      end

      if has_signature
        caption_row = [pdf.make_cell(content: "", borders: [], padding: 0)]
        caption_row << pdf.make_cell(
          content: I18n.t("pdf.signature.caption"),
          size: DISCLAIMER_TEXT_SIZE,
          align: :center,
          borders: [],
          padding: [5, has_user_logo ? 10 : 5, 0, 5]
        )
        caption_row << pdf.make_cell(content: "", borders: [], padding: 0) if has_user_logo
      end

      first_row.length

      table_data = [first_row]
      # table_data << caption_row if has_signature

      pdf.table(table_data) do |t|
        t.cells.borders = []
      end
    end

    def self.render_disclaimer_header(pdf)
      pdf.text I18n.t("pdf.disclaimer.header"),
        size: DISCLAIMER_HEADER_SIZE,
        style: :bold
      pdf.stroke_horizontal_rule
    end
  end
end
