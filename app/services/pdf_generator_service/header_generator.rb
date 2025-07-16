class PdfGeneratorService
  class HeaderGenerator
    include Configuration

    def self.generate_inspection_pdf_header(pdf, inspection)
      create_inspection_header(pdf, inspection)
    end

    def self.create_inspection_header(pdf, inspection)
      inspector_user = inspection.user
      report_id_text = build_report_id_text(inspection)
      status_text, status_color = build_status_text_and_color(inspection)

      logo_width, logo_temp = prepare_logo(inspector_user)

      render_inspection_header_layout(pdf, inspection, report_id_text,
        status_text, status_color,
        logo_width, logo_temp)

      logo_temp&.unlink
      pdf.move_down Configuration::STATUS_SPACING
    end

    def self.generate_unit_pdf_header(pdf, unit)
      create_unit_header(pdf, unit)
    end

    def self.create_unit_header(pdf, unit)
      user = unit.user
      unit_id_text = build_unit_id_text(unit)

      logo_width, logo_temp = prepare_logo(user)

      render_unit_header_layout(pdf, unit, unit_id_text, logo_width, logo_temp)

      logo_temp&.unlink
      pdf.move_down Configuration::STATUS_SPACING
    end

    class << self
      private

      def build_report_id_text(inspection)
        "#{I18n.t("pdf.inspection.fields.report_id")}: #{inspection.id}"
      end

      def build_status_text_and_color(inspection)
        case inspection.passed
        when true then [I18n.t("pdf.inspection.passed"), Configuration::PASS_COLOR]
        when false then [I18n.t("pdf.inspection.failed"), Configuration::FAIL_COLOR]
        when nil then [I18n.t("pdf.inspection.in_progress"), Configuration::NA_COLOR]
        end
      end

      def build_unit_id_text(unit)
        "#{I18n.t("pdf.unit.fields.unit_id")}: #{unit.id}"
      end

      def prepare_logo(user)
        return [0, nil] unless user&.logo&.attached?

        logo_data = user.logo.download
        logo_height = Configuration::LOGO_HEIGHT
        logo_width = logo_height * 2 + 10

        logo_temp = Tempfile.new(["user_logo_#{user.id}", ".png"])
        logo_temp.binmode
        logo_temp.write(logo_data)
        logo_temp.close

        [logo_width, logo_temp]
      end

      def render_inspection_header_layout(pdf, inspection, report_id_text,
        status_text, status_color,
        logo_width, logo_temp)
        pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
          render_inspection_text_section(pdf, inspection, report_id_text,
            status_text, status_color, logo_width)
          render_logo_section(pdf, logo_temp, logo_width) if logo_temp
        end
      end

      def render_inspection_text_section(pdf, inspection, report_id_text,
        status_text, status_color, logo_width)
        width = pdf.bounds.width - logo_width
        pdf.bounding_box([0, pdf.bounds.top], width: width) do
          pdf.text report_id_text, size: Configuration::HEADER_TEXT_SIZE,
            style: :bold
          pdf.text status_text, size: Configuration::HEADER_TEXT_SIZE,
            style: :bold,
            color: status_color

          expiry_label = I18n.t("pdf.inspection.fields.expiry_date")
          expiry_value = Utilities.format_date(inspection.reinspection_date)
          pdf.text "#{expiry_label}: #{expiry_value}",
            size: Configuration::HEADER_TEXT_SIZE, style: :bold
        end
      end

      def render_unit_header_layout(pdf, unit, unit_id_text,
        logo_width, logo_temp)
        pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
          render_unit_text_section(pdf, unit, unit_id_text, logo_width)
          render_logo_section(pdf, logo_temp, logo_width) if logo_temp
        end
      end

      def render_unit_text_section(pdf, unit, unit_id_text, logo_width)
        width = pdf.bounds.width - logo_width
        pdf.bounding_box([0, pdf.bounds.top], width: width) do
          pdf.text unit_id_text, size: Configuration::HEADER_TEXT_SIZE, style: :bold

          expiry_label = I18n.t("pdf.unit.fields.expiry_date")
          expiry_value = if unit.last_inspection&.reinspection_date
            Utilities.format_date(unit.last_inspection.reinspection_date)
          else
            I18n.t("pdf.unit.fields.na")
          end
          pdf.text "#{expiry_label}: #{expiry_value}",
            size: Configuration::HEADER_TEXT_SIZE, style: :bold
        end
      end

      def render_logo_section(pdf, logo_temp, logo_width)
        x_position = pdf.bounds.width - logo_width + 10
        pdf.bounding_box([x_position, pdf.bounds.top],
          width: logo_width - 10) do
          pdf.image logo_temp.path, height: Configuration::LOGO_HEIGHT, position: :right
        end
      end
    end
  end
end
