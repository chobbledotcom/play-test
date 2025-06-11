class PdfGeneratorService
  class HeaderGenerator
    include Configuration

    def self.generate_inspection_pdf_header(pdf, inspection)
      # Line 1: Inspection Report - Unit Name - Status/Date
      unit_name = inspection.unit&.name || I18n.t("pdf.inspection.fields.na")
      status_date = if inspection.complete?
        "#{I18n.t("pdf.inspection.fields.issued")} #{inspection.inspection_date&.strftime("%d/%m/%Y") || I18n.t("pdf.inspection.fields.na")}"
      else
        I18n.t("pdf.inspection.fields.incomplete")
      end

      line1_parts = [I18n.t("pdf.inspection.title"), unit_name, status_date]
      pdf.text line1_parts.join(" - "), align: :center, size: HEADER_TEXT_SIZE, style: :bold, color: "663399"
      pdf.move_down HEADER_SPACING

      # Line 2: Unique Report Number
      pdf.text "#{I18n.t("pdf.inspection.fields.report_id")}: #{inspection.id}",
        align: :center, size: HEADER_TEXT_SIZE, style: :bold, color: "663399"
      pdf.move_down HEADER_SPACING

      # Line 3: Inspector Name, City, RPII Inspector No
      inspector_user = inspection.user
      if inspector_user
        inspector_parts = []
        inspector_parts << inspector_user.name if inspector_user.name.present?
        inspector_parts << inspector_user.display_country if inspector_user.display_country.present?
        inspector_parts << "#{I18n.t("pdf.inspection.fields.rpii_inspector_no")}: #{inspector_user.rpii_inspector_number}" if inspector_user.rpii_inspector_number.present?

        if inspector_parts.any?
          # Show incomplete status in red if not complete
          line3_color = inspection.complete? ? "663399" : "CC0000"
          pdf.text inspector_parts.join(", "), align: :center, size: NICE_TABLE_TEXT_SIZE, color: line3_color
        end
      end

      pdf.move_down 8

      # Line 4: Overall Pass/Fail Status
      status_text = inspection.passed? ? I18n.t("pdf.inspection.passed") : I18n.t("pdf.inspection.failed")
      status_color = inspection.passed? ? "008000" : "CC0000"
      pdf.text status_text, align: :center, size: STATUS_TEXT_SIZE, style: :bold, color: status_color

      pdf.move_down STATUS_SPACING
    end

    def self.generate_unit_pdf_header(pdf, unit)
      # Line 1: Unit Report - Unit Name - Serial Number
      unit_name = unit.name || I18n.t("pdf.unit.fields.na")
      serial_number = unit.serial || I18n.t("pdf.unit.fields.na")

      line1_parts = [I18n.t("pdf.unit.title"), unit_name, "Serial: #{serial_number}"]
      pdf.text line1_parts.join(" - "), align: :center, size: HEADER_TEXT_SIZE, style: :bold, color: "663399"
      pdf.move_down HEADER_SPACING

      # Line 2: Unit ID
      pdf.text "#{I18n.t("pdf.unit.fields.unit_id")}: #{unit.id}",
        align: :center, size: HEADER_TEXT_SIZE, style: :bold, color: "663399"
      pdf.move_down HEADER_SPACING

      # Line 3: Owner and Manufacturer
      owner_manufacturer_parts = []
      owner_manufacturer_parts << "Owner: #{unit.owner}" if unit.owner.present?
      owner_manufacturer_parts << "Manufacturer: #{unit.manufacturer}" if unit.manufacturer.present?

      if owner_manufacturer_parts.any?
        pdf.text owner_manufacturer_parts.join(", "), align: :center, size: NICE_TABLE_TEXT_SIZE, color: "663399"
      end

      pdf.move_down STATUS_SPACING
    end
  end
end
