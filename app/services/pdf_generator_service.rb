class PdfGeneratorService
  require_relative "pdf_generator_service/configuration"
  require_relative "pdf_generator_service/utilities"
  require_relative "pdf_generator_service/header_generator"
  require_relative "pdf_generator_service/table_builder"
  require_relative "pdf_generator_service/assessment_renderer"
  require_relative "pdf_generator_service/position_calculator"
  require_relative "pdf_generator_service/image_orientation_processor"
  require_relative "pdf_generator_service/image_processor"
  require_relative "pdf_generator_service/debug_info_renderer"
  require_relative "pdf_generator_service/photos_renderer"

  include Configuration

  def self.generate_inspection_report(inspection, debug_enabled: false, debug_queries: [])
    require "prawn/table"

    Prawn::Document.new(page_size: "A4", page_layout: :portrait) do |pdf|
      Configuration.setup_pdf_fonts(pdf)

      # Initialize assessment renderer
      assessment_renderer = AssessmentRenderer.new

      # Header section
      HeaderGenerator.generate_inspection_pdf_header(pdf, inspection)

      # Unit details section
      generate_inspection_unit_details(pdf, inspection)

      # Risk assessment section (if present)
      generate_risk_assessment_section(pdf, inspection)

      # Generate all assessment sections using the inspection's applicable assessments
      inspection.each_applicable_assessment do |assessment_key, _, assessment|
        # Get the assessment type name for i18n (remove _assessment suffix)
        assessment_type = assessment_key.to_s.sub(/_assessment$/, "")

        # Generate the section using the generic renderer
        renderer = AssessmentRenderer.new
        renderer.generate_assessment_section(pdf, assessment_type, assessment)
        assessment_renderer.current_assessment_blocks.concat(renderer.current_assessment_blocks)
      end

      # Render all collected assessments in newspaper-style columns
      assessment_renderer.render_all_assessments_in_columns(pdf)

      # QR Code in bottom right corner
      ImageProcessor.generate_qr_code_footer(pdf, inspection)

      # Add DRAFT watermark overlay for draft inspections
      Utilities.add_draft_watermark(pdf) unless inspection.complete?

      # Add photos page if photos are attached
      PhotosRenderer.generate_photos_page(pdf, inspection)

      # Add debug info page if enabled (admins only)
      if debug_enabled && debug_queries.present?
        DebugInfoRenderer.add_debug_info_page(pdf, debug_queries)
      end
    end
  end

  def self.generate_unit_report(unit, debug_enabled: false, debug_queries: [])
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

      # Add debug info page if enabled (admins only)
      if debug_enabled && debug_queries.present?
        DebugInfoRenderer.add_debug_info_page(pdf, debug_queries)
      end
    end
  end

  def self.generate_inspection_unit_details(pdf, inspection)
    unit = inspection.unit

    if unit
      unit_data = TableBuilder.build_unit_details_table_with_inspection(unit, inspection, :inspection)
      TableBuilder.create_unit_details_table(pdf, I18n.t("pdf.inspection.equipment_details"), unit_data)
    end
    # Hide the table entirely when no unit is associated
  end

  def self.generate_unit_details(pdf, unit)
    unit_data = TableBuilder.build_unit_details_table(unit, :unit)
    TableBuilder.create_unit_details_table(pdf, I18n.t("pdf.unit.details"), unit_data)
  end

  def self.generate_unit_details_with_inspection(pdf, unit, last_inspection)
    unit_data = TableBuilder.build_unit_details_table(unit, :unit)
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

  def self.generate_risk_assessment_section(pdf, inspection)
    return if inspection.risk_assessment.blank?

    pdf.text I18n.t("pdf.inspection.risk_assessment"), size: HEADER_TEXT_SIZE, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    pdf.text inspection.risk_assessment, size: 10
    pdf.move_down 15
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
