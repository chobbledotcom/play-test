class PdfGeneratorService
  class HeaderGenerator
    include Configuration

    def self.generate_inspection_pdf_header(pdf, inspection)
      inspector_user = inspection.user
      
      # Three-column table at the top: Report ID | Logo | Pass/Fail
      report_id_text = "#{I18n.t("pdf.inspection.fields.report_id")}: #{inspection.id}"
      
      # Pass/Fail status
      status_text = inspection.passed? ? I18n.t("pdf.inspection.passed") : I18n.t("pdf.inspection.failed")
      status_color = inspection.passed? ? "008000" : "CC0000"
      
      # Handle logo in middle column
      if inspector_user&.logo&.attached?
        begin
          logo_data = inspector_user.logo.download
          logo_height = LOGO_HEIGHT
          
          # Create temporary file for the logo
          logo_temp = Tempfile.new(["user_logo_#{inspector_user.id}", ".png"])
          logo_temp.binmode
          logo_temp.write(logo_data)
          logo_temp.close
          
          # Create table with logo image
          header_data = [[
            { content: report_id_text, align: :left, font_style: :bold },
            { image: logo_temp.path, image_height: logo_height, position: :center },
            { content: status_text, align: :right, font_style: :bold, text_color: status_color }
          ]]
          
          pdf.table(header_data, width: pdf.bounds.width) do |t|
            t.cells.borders = []
            t.cells.padding = HEADER_TABLE_PADDING
            t.cells.size = HEADER_TEXT_SIZE
            t.columns(1).width = pdf.bounds.width * LOGO_COLUMN_WIDTH_RATIO
          end
          
          logo_temp.unlink
        rescue => e
          Rails.logger.error "Failed to add logo to PDF: #{e.message}"
          # Fall back to table without logo
          create_header_table_without_logo(pdf, report_id_text, status_text, status_color)
        end
      else
        # No logo, create simpler table
        create_header_table_without_logo(pdf, report_id_text, status_text, status_color)
      end
      
      pdf.move_down STATUS_SPACING
    end
    
    private
    
    def self.create_header_table_without_logo(pdf, report_id_text, status_text, status_color)
      header_data = [[
        { content: report_id_text, align: :left, font_style: :bold },
        { content: "", align: :center },  # Empty middle column
        { content: status_text, align: :right, font_style: :bold, text_color: status_color }
      ]]
      
      pdf.table(header_data, width: pdf.bounds.width) do |t|
        t.cells.borders = []
        t.cells.padding = HEADER_TABLE_PADDING
        t.cells.size = HEADER_TEXT_SIZE
      end
    end

    def self.generate_unit_pdf_header(pdf, unit)
      # Line 1: Unit Report - Unit Name - Serial Number
      unit_name = unit.name || I18n.t("pdf.unit.fields.na")
      serial = unit.serial || I18n.t("pdf.unit.fields.na")

      line1_parts = [I18n.t("pdf.unit.title"), unit_name, "Serial: #{serial}"]
      pdf.text line1_parts.join(" - "), align: :center, size: HEADER_TEXT_SIZE, style: :bold, color: HEADER_COLOR
      pdf.move_down HEADER_SPACING

      # Line 2: Unit ID
      pdf.text "#{I18n.t("pdf.unit.fields.unit_id")}: #{unit.id}",
        align: :center, size: HEADER_TEXT_SIZE, style: :bold, color: HEADER_COLOR
      pdf.move_down HEADER_SPACING

      # Line 3: Owner and Manufacturer
      owner_manufacturer_parts = []
      owner_manufacturer_parts << "Owner: #{unit.owner}" if unit.owner.present?
      owner_manufacturer_parts << "Manufacturer: #{unit.manufacturer}" if unit.manufacturer.present?

      if owner_manufacturer_parts.any?
        pdf.text owner_manufacturer_parts.join(", "), align: :center, size: NICE_TABLE_TEXT_SIZE, color: HEADER_COLOR
      end

      pdf.move_down STATUS_SPACING
    end
  end
end
