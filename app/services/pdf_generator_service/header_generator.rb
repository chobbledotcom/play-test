# typed: false

class PdfGeneratorService
  class HeaderGenerator
    include Configuration

    def self.generate_inspection_pdf_header(pdf, inspection)
      create_inspection_header(pdf, inspection)
      # Generate QR code in top left corner
      ImageProcessor.generate_qr_code_header(pdf, inspection)
    end

    def self.create_inspection_header(pdf, inspection)
      inspector_user = inspection.user
      report_id_text = build_report_id_text(inspection)
      status_text, status_color = build_status_text_and_color(inspection)

      render_header_with_logo(pdf, inspector_user) do |logo_width|
        render_inspection_text_section(pdf, inspection, report_id_text,
          status_text, status_color, logo_width)
      end

      pdf.move_down Configuration::STATUS_SPACING
    end

    def self.generate_unit_pdf_header(pdf, unit, unbranded: false)
      create_unit_header(pdf, unit, unbranded: unbranded)
      # Generate QR code in top left corner
      ImageProcessor.generate_qr_code_header(pdf, unit)
    end

    def self.create_unit_header(pdf, unit, unbranded: false)
      user = unbranded ? nil : unit.user
      unit_id_text = build_unit_id_text(unit)

      render_header_with_logo(pdf, user) do |logo_width|
        render_unit_text_section(pdf, unit, unit_id_text, logo_width)
      end

      pdf.move_down Configuration::STATUS_SPACING
    end

    class << self
      private

      def build_report_id_text(inspection)
        "#{I18n.t("pdf.inspection.fields.report_id")}: #{inspection.id}"
      end

      def build_status_text_and_color(inspection)
        case inspection.passed
        when true
          [I18n.t("pdf.inspection.passed"), Configuration::PASS_COLOR]
        when false
          [I18n.t("pdf.inspection.failed"), Configuration::FAIL_COLOR]
        when nil
          [I18n.t("pdf.inspection.in_progress"), Configuration::NA_COLOR]
        end
      end

      def build_unit_id_text(unit)
        "#{I18n.t("pdf.unit.fields.unit_id")}: #{unit.id}"
      end

      def render_header_with_logo(pdf, user)
        logo_width, logo_data, logo_attachment = prepare_logo(user)

        pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
          yield(logo_width)
          if logo_data
            render_logo_section(pdf, logo_data, logo_width, logo_attachment)
          end
        end
      end

      def prepare_logo(user)
        # Check if PDF logo config is set to override user logo
        pdf_logo = Rails.configuration.pdf.logo
        if pdf_logo.present?
          logo_path = Rails.root.join("app", "assets", "images", pdf_logo)
          logo_data = File.read(logo_path, mode: "rb")
          logo_height = Configuration::LOGO_HEIGHT
          logo_width = logo_height * 2 + 10
          return [logo_width, logo_data, nil]
        end

        return [0, nil, nil] unless user&.logo&.attached?

        logo_data = user.logo.download
        logo_height = Configuration::LOGO_HEIGHT
        logo_width = logo_height * 2 + 10

        [logo_width, logo_data, user.logo]
      end

      def render_inspection_text_section(
        pdf,
        inspection,
        report_id_text,
        status_text,
        status_color,
        logo_width
      )
        qr_offset = Configuration::QR_CODE_SIZE + Configuration::HEADER_SPACING
        width = pdf.bounds.width - logo_width - qr_offset
        pdf.bounding_box([qr_offset, pdf.bounds.top], width: width) do
          render_inspection_report_id(pdf, report_id_text)
          render_inspection_status(pdf, status_text, status_color)
          render_inspection_expiry(pdf, inspection)
        end
      end

      def render_inspection_report_id(pdf, report_id_text)
        pdf.text(
          report_id_text,
          size: Configuration::HEADER_TEXT_SIZE,
          style: :bold
        )
      end

      def render_inspection_status(pdf, status_text, status_color)
        pdf.text(
          status_text,
          size: Configuration::HEADER_TEXT_SIZE,
          style: :bold,
          color: status_color
        )
      end

      def render_inspection_expiry(pdf, inspection)
        expiry_label = I18n.t("pdf.inspection.fields.expiry_date")
        expiry_value = Utilities.format_date(inspection.reinspection_date)
        pdf.text(
          "#{expiry_label}: #{expiry_value}",
          size: Configuration::HEADER_TEXT_SIZE,
          style: :bold
        )
      end

      def render_unit_text_section(pdf, unit, unit_id_text, logo_width)
        qr_offset = Configuration::QR_CODE_SIZE + Configuration::HEADER_SPACING
        width = pdf.bounds.width - logo_width - qr_offset
        pdf.bounding_box([qr_offset, pdf.bounds.top], width: width) do
          render_unit_header_text(pdf, unit_id_text)
          render_unit_expiry_text(pdf, unit)
          pdf.move_down Configuration::HEADER_TEXT_SIZE * 1.5
        end
      end

      def render_unit_header_text(pdf, unit_id_text)
        pdf.text(
          unit_id_text,
          size: Configuration::HEADER_TEXT_SIZE,
          style: :bold
        )
      end

      def render_unit_expiry_text(pdf, unit)
        expiry_label = I18n.t("pdf.unit.fields.expiry_date")
        expiry_value = format_unit_expiry_value(unit)
        pdf.text(
          "#{expiry_label}: #{expiry_value}",
          size: Configuration::HEADER_TEXT_SIZE,
          style: :bold
        )
      end

      def format_unit_expiry_value(unit)
        if unit.last_inspection&.reinspection_date
          Utilities.format_date(unit.last_inspection.reinspection_date)
        else
          I18n.t("pdf.unit.fields.na")
        end
      end

      def render_logo_section(pdf, logo_data, logo_width, logo_attachment)
        x_position = pdf.bounds.width - logo_width + 10
        pdf.bounding_box(
          [x_position, pdf.bounds.top],
          width: logo_width - 10
        ) do
          pdf.image(
            StringIO.new(logo_data),
            height: Configuration::LOGO_HEIGHT,
            position: :right
          )
        end
      rescue Prawn::Errors::UnsupportedImageType => e
        raise ImageError.build_detailed_error(e, logo_attachment)
      end
    end
  end
end
