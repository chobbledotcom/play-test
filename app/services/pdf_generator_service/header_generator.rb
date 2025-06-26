class PdfGeneratorService
  class HeaderGenerator
    include Configuration

    def self.generate_inspection_pdf_header(pdf, inspection)
      create_inspection_header(pdf, inspection)
    end

    def self.create_inspection_header(pdf, inspection)
      inspector_user = inspection.user

      # Two-column layout: Left side has Report ID + Pass/Fail, Right side has logo (if present)
      report_id_text = "#{I18n.t("pdf.inspection.fields.report_id")}: #{inspection.id}"

      # Pass/Fail status
      status_text = inspection.passed? ? I18n.t("pdf.inspection.passed") : I18n.t("pdf.inspection.failed")
      status_color = inspection.passed? ? "008000" : "CC0000"

      # Calculate logo space if logo is present
      logo_width = 0
      logo_temp = nil
      
      if inspector_user&.logo&.attached?
        logo_data = inspector_user.logo.download
        logo_height = LOGO_HEIGHT
        logo_width = logo_height * 2 + 10  # Add padding

        # Create temporary file for the logo
        logo_temp = Tempfile.new(["user_logo_#{inspector_user.id}", ".png"])
        logo_temp.binmode
        logo_temp.write(logo_data)
        logo_temp.close
      end

      # Create layout with or without logo space
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
        # Left side text
        pdf.bounding_box([0, pdf.bounds.top], width: pdf.bounds.width - logo_width) do
          pdf.text report_id_text, size: HEADER_TEXT_SIZE, style: :bold
          pdf.text status_text, size: HEADER_TEXT_SIZE, style: :bold, color: status_color
        end
        
        # Right side logo (if present)
        if logo_temp
          pdf.bounding_box([pdf.bounds.width - logo_width + 10, pdf.bounds.top], width: logo_width - 10) do
            pdf.image logo_temp.path, height: LOGO_HEIGHT, position: :right
          end
        end
      end

      logo_temp&.unlink
      pdf.move_down STATUS_SPACING
    end

    def self.generate_unit_pdf_header(pdf, unit)
      create_unit_header(pdf, unit)
    end

    def self.create_unit_header(pdf, unit)
      # Get the user who owns this unit for logo
      user = unit.user

      # Left side has Unit ID only (no pass/fail status)
      unit_id_text = "#{I18n.t("pdf.unit.fields.unit_id")}: #{unit.id}"

      # Calculate logo space if logo is present
      logo_width = 0
      logo_temp = nil
      
      if user&.logo&.attached?
        logo_data = user.logo.download
        logo_height = LOGO_HEIGHT
        logo_width = logo_height * 2 + 10  # Add padding

        # Create temporary file for the logo
        logo_temp = Tempfile.new(["user_logo_#{user.id}", ".png"])
        logo_temp.binmode
        logo_temp.write(logo_data)
        logo_temp.close
      end

      # Create layout with or without logo space
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
        # Left side text (just Unit ID)
        pdf.bounding_box([0, pdf.bounds.top], width: pdf.bounds.width - logo_width) do
          pdf.text unit_id_text, size: HEADER_TEXT_SIZE, style: :bold
        end
        
        # Right side logo (if present)
        if logo_temp
          pdf.bounding_box([pdf.bounds.width - logo_width + 10, pdf.bounds.top], width: logo_width - 10) do
            pdf.image logo_temp.path, height: LOGO_HEIGHT, position: :right
          end
        end
      end

      logo_temp&.unlink
      pdf.move_down STATUS_SPACING
    end
  end
end
