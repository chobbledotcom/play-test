class PdfGeneratorService
  require_relative "pdf_generator_service/configuration"
  require_relative "pdf_generator_service/utilities"
  require_relative "pdf_generator_service/header_generator"
  require_relative "pdf_generator_service/table_builder"
  require_relative "pdf_generator_service/assessment_renderer"
  require_relative "pdf_generator_service/assessment_columns"
  require_relative "pdf_generator_service/position_calculator"
  require_relative "pdf_generator_service/image_orientation_processor"
  require_relative "pdf_generator_service/image_processor"
  require_relative "pdf_generator_service/debug_info_renderer"
  require_relative "pdf_generator_service/photos_renderer"
  require_relative "pdf_generator_service/disclaimer_footer_renderer"

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

      # Generate all assessment sections in the correct UI order from applicable_tabs
      generate_assessments_in_ui_order(inspection, assessment_renderer, pdf)

      # Render all collected assessments in newspaper-style columns
      assessment_renderer.render_all_assessments_in_columns(pdf)

      # Disclaimer footer (only on first page)
      DisclaimerFooterRenderer.render_disclaimer_footer(pdf, inspection.user)

      # Add unit photo in bottom right corner
      # Pass column count info to adjust photo width accordingly
      if inspection.unit&.photo
        column_count = assessment_renderer.used_compact_layout ? 4 : 3
        ImageProcessor.add_unit_photo_footer(pdf, inspection.unit, column_count)
      end

      # Add DRAFT watermark overlay for draft inspections (except in test env)
      if !inspection.complete? && !Rails.env.test?
        Utilities.add_draft_watermark(pdf)
      end

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

      # Disclaimer footer (only on first page)
      DisclaimerFooterRenderer.render_disclaimer_footer(pdf, unit.user)

      # Add unit photo in bottom right corner (for unit PDFs, always use 3 columns)
      if unit.photo
        ImageProcessor.add_unit_photo_footer(pdf, unit, 3)
      end

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

    # Create a text box constrained to 4 lines with shrink_to_fit
    line_height = 10 * 1.2  # Normal font size * line height multiplier
    max_height = line_height * 4  # 4 lines max

    pdf.text_box inspection.risk_assessment,
      at: [0, pdf.cursor],
      width: pdf.bounds.width,
      height: max_height,
      size: 10,
      overflow: :shrink_to_fit,
      min_font_size: 5

    pdf.move_down max_height + 15
  end

  def self.generate_assessments_in_ui_order(inspection, assessment_renderer, pdf)
    # Get the UI order from applicable_tabs (excluding non-assessment tabs)
    ui_ordered_tabs = inspection.applicable_tabs - ["inspection", "results"]

    ui_ordered_tabs.each do |tab_name|
      assessment_key = :"#{tab_name}_assessment"
      next unless inspection.assessment_applicable?(assessment_key)

      assessment = inspection.send(assessment_key)
      next unless assessment

      # Generate the section using the generic renderer
      renderer = AssessmentRenderer.new
      renderer.generate_assessment_section(pdf, tab_name, assessment)
      # Deep copy the blocks to avoid reference issues
      renderer.current_assessment_blocks.each do |block|
        assessment_renderer.current_assessment_blocks << {
          title: block[:title],
          fields: block[:fields].dup
        }
      end
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
