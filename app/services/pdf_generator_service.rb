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

      # Generate all assessment sections using ASSESSMENT_TYPES
      Inspection::ASSESSMENT_TYPES.each do |assessment_name, _assessment_class|
        # Skip slide assessment if unit doesn't have a slide
        next if assessment_name == :slide_assessment && !inspection.has_slide?

        # Skip enclosed assessment if not totally enclosed
        next if assessment_name == :enclosed_assessment && !inspection.is_totally_enclosed?

        # Get the assessment type name for i18n (remove _assessment suffix)
        assessment_type = assessment_name.to_s.sub(/_assessment$/, "")


        # Generate the section using the generic renderer
        renderer = AssessmentRenderer.new
        renderer.generate_assessment_section(pdf, assessment_type, inspection.send(assessment_name))
        assessment_renderer.current_assessment_blocks.concat(renderer.current_assessment_blocks)
      end

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

    # Preload all inspections once to avoid N+1 queries
    completed_inspections = unit.inspections
      .includes(:user, inspector_company: {logo_attachment: :blob})
      .complete
      .order(inspection_date: :desc)

    last_inspection = completed_inspections.first

    Prawn::Document.new(page_size: "A4", page_layout: :portrait) do |pdf|
      Configuration.setup_pdf_fonts(pdf)
      HeaderGenerator.generate_unit_pdf_header(pdf, unit)
      generate_unit_details_with_inspection(pdf, unit, last_inspection)
      generate_unit_inspection_history_with_data(pdf, unit, completed_inspections)
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

  def self.generate_unit_details_with_inspection(pdf, unit, last_inspection)
    unit_data = TableBuilder.build_unit_details_table_with_inspection(unit, last_inspection, :unit)
    TableBuilder.create_unit_details_table(pdf, I18n.t("pdf.unit.details"), unit_data)
  end

  def self.generate_unit_inspection_history(pdf, unit)
    # Check for completed inspections - preload associations to avoid N+1 queries
    # Since all inspections belong to the same unit, we don't need to reload the unit
    completed_inspections = unit.inspections
      .includes(:user, inspector_company: {logo_attachment: :blob})
      .complete
      .order(inspection_date: :desc)

    if completed_inspections.empty?
      TableBuilder.create_nice_box_table(pdf, I18n.t("pdf.unit.inspection_history"), [[I18n.t("pdf.unit.no_completed_inspections"), ""]])
    else
      TableBuilder.create_inspection_history_table(pdf, I18n.t("pdf.unit.inspection_history"), completed_inspections)
    end
  end

  def self.generate_unit_inspection_history_with_data(pdf, unit, completed_inspections)
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
