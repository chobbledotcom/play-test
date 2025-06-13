class PdfGeneratorService
  require_relative "pdf_generator_service/configuration"
  require_relative "pdf_generator_service/utilities"
  require_relative "pdf_generator_service/header_generator"
  require_relative "pdf_generator_service/table_builder"
  require_relative "pdf_generator_service/field_formatter"
  require_relative "pdf_generator_service/assessment_renderer"
  require_relative "pdf_generator_service/position_calculator"
  require_relative "pdf_generator_service/image_orientation_processor"
  require_relative "pdf_generator_service/image_processor"

  include Configuration

  def self.generate_inspection_report(inspection)
    require "prawn/table"

    Prawn::Document.new(page_size: "A4", page_layout: :portrait) do |pdf|
      Configuration.setup_pdf_fonts(pdf)

      # Initialize assessment renderer
      assessment_renderer = AssessmentRenderer.new

      # Header section
      HeaderGenerator.generate_inspection_pdf_header(pdf, inspection)

      # Unit details section
      generate_inspection_unit_details(pdf, inspection)

      # User Height/Count Assessment section
      renderer = AssessmentRenderer.generate_user_height_section(pdf, inspection)
      assessment_renderer.current_assessment_blocks.concat(renderer.current_assessment_blocks)

      # Slide Assessment section (if inspection has slide)
      if inspection.has_slide?
        renderer = AssessmentRenderer.generate_slide_section(pdf, inspection)
        assessment_renderer.current_assessment_blocks.concat(renderer.current_assessment_blocks)
      end

      # Structure Assessment section
      renderer = AssessmentRenderer.generate_structure_section(pdf, inspection)
      assessment_renderer.current_assessment_blocks.concat(renderer.current_assessment_blocks)

      # Anchorage Assessment
      renderer = AssessmentRenderer.generate_anchorage_section(pdf, inspection)
      assessment_renderer.current_assessment_blocks.concat(renderer.current_assessment_blocks)

      # Totally Enclosed section (if applicable)
      if inspection.is_totally_enclosed?
        renderer = AssessmentRenderer.generate_enclosed_section(pdf, inspection)
        assessment_renderer.current_assessment_blocks.concat(renderer.current_assessment_blocks)
      end

      # Materials Assessment
      renderer = AssessmentRenderer.generate_materials_section(pdf, inspection)
      assessment_renderer.current_assessment_blocks.concat(renderer.current_assessment_blocks)

      # Fan/Blower Assessment
      renderer = AssessmentRenderer.generate_fan_section(pdf, inspection)
      assessment_renderer.current_assessment_blocks.concat(renderer.current_assessment_blocks)

      # Risk Assessment section
      renderer = AssessmentRenderer.generate_risk_assessment_section(pdf, inspection)
      assessment_renderer.current_assessment_blocks.concat(renderer.current_assessment_blocks)

      # Render all collected assessments in newspaper-style columns
      assessment_renderer.render_all_assessments_in_columns(pdf)

      # QR Code in bottom right corner
      ImageProcessor.generate_qr_code_footer(pdf, inspection)

      # Add DRAFT watermark overlay for draft inspections
      Utilities.add_draft_watermark(pdf) unless inspection.complete?
    end
  end

  def self.generate_unit_report(unit)
    require "prawn/table"

    Prawn::Document.new(page_size: "A4", page_layout: :portrait) do |pdf|
      Configuration.setup_pdf_fonts(pdf)
      HeaderGenerator.generate_unit_pdf_header(pdf, unit)
      generate_unit_details(pdf, unit)
      generate_unit_inspection_history(pdf, unit)
      ImageProcessor.generate_qr_code_footer(pdf, unit)
    end
  end

  def self.generate_inspection_unit_details(pdf, inspection)
    unit = inspection.unit

    if unit
      unit_data = TableBuilder.build_unit_details_table(unit, :inspection)
      TableBuilder.create_unit_details_table(pdf, I18n.t("pdf.inspection.equipment_details"), unit_data)
    end
    # Hide the table entirely when no unit is associated
  end


  def self.generate_unit_details(pdf, unit)
    unit_data = TableBuilder.build_unit_details_table(unit, :unit)
    TableBuilder.create_unit_details_table(pdf, I18n.t("pdf.unit.details"), unit_data)
  end

  def self.generate_unit_inspection_history(pdf, unit)
    # Check for completed inspections
    completed_inspections = unit.inspections.complete.order(inspection_date: :desc)

    if completed_inspections.empty?
      TableBuilder.create_nice_box_table(pdf, I18n.t("pdf.unit.inspection_history"), [[I18n.t("pdf.unit.no_completed_inspections"), ""]])
    else
      TableBuilder.create_inspection_history_table(pdf, I18n.t("pdf.unit.inspection_history"), completed_inspections)
    end
  end

  # Helper methods for backward compatibility and testing
  def self.truncate_text(text, max_length)
    Utilities.truncate_text(text, max_length)
  end

  def self.format_pass_fail(value)
    Utilities.format_pass_fail(value)
  end

  def self.format_measurement(value, unit = "")
    Utilities.format_measurement(value, unit)
  end
end
