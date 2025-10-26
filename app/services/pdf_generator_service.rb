# typed: false
# frozen_string_literal: true

class PdfGeneratorService
  include Configuration

  def self.generate_inspection_report(
    inspection,
    debug_enabled: false,
    debug_queries: []
  )
    require "prawn/table"

    Prawn::Document.new(page_size: "A4", page_layout: :portrait) do |pdf|
      generate_inspection_report_content(
        pdf,
        inspection,
        debug_enabled,
        debug_queries
      )
    end
  end

  def self.generate_inspection_report_content(
    pdf,
    inspection,
    debug_enabled,
    debug_queries
  )
    Configuration.setup_pdf_fonts(pdf)
    assessment_blocks = []

    generate_inspection_header_and_sections(
      pdf,
      inspection,
      assessment_blocks
    )
    footer_data = measure_and_render_footer_components(pdf, inspection)
    render_assessment_blocks_in_columns(
      pdf,
      assessment_blocks,
      footer_data[:disclaimer],
      footer_data[:photo]
    )

    add_inspection_overlays_and_pages(
      pdf,
      inspection,
      debug_enabled,
      debug_queries
    )
  end

  def self.generate_inspection_header_and_sections(pdf, inspection, assessment_blocks)
    HeaderGenerator.generate_inspection_pdf_header(pdf, inspection)
    generate_inspection_unit_details(pdf, inspection)
    generate_risk_assessment_section(pdf, inspection)
    generate_assessments_in_ui_order(inspection, assessment_blocks)
  end

  def self.measure_and_render_footer_components(pdf, inspection)
    cursor_before_footer = pdf.cursor
    DisclaimerFooterRenderer.render_disclaimer_footer(pdf, inspection.user)
    disclaimer_height = DisclaimerFooterRenderer.measure_footer_height(unbranded: false)
    photo_height = ImageProcessor.measure_unit_photo_height(pdf, inspection.unit, 4)
    ImageProcessor.add_unit_photo_footer(pdf, inspection.unit, 4) if inspection.unit&.photo
    pdf.move_cursor_to(cursor_before_footer)
    {disclaimer: disclaimer_height, photo: photo_height}
  end

  def self.add_inspection_overlays_and_pages(pdf, inspection, debug_enabled, debug_queries)
    Utilities.add_draft_watermark(pdf) if !inspection.complete? && !Rails.env.test?
    PhotosRenderer.generate_photos_page(pdf, inspection)
    DebugInfoRenderer.add_debug_info_page(pdf, debug_queries) if debug_enabled && debug_queries.present?
  end

  def self.generate_unit_report(unit, debug_enabled: false, debug_queries: [])
    require "prawn/table"
    unbranded = Rails.configuration.units.reports_unbranded
    completed_inspections = load_completed_inspections(unit)

    Prawn::Document.new(page_size: "A4", page_layout: :portrait) do |pdf|
      Configuration.setup_pdf_fonts(pdf)
      generate_unit_report_content(pdf, unit, completed_inspections, unbranded)
      add_unit_footer_and_photo(pdf, unit, unbranded)
      DebugInfoRenderer.add_debug_info_page(pdf, debug_queries) if debug_enabled && debug_queries.present?
    end
  end

  def self.load_completed_inspections(unit)
    unit.inspections
      .includes(:user, inspector_company: {logo_attachment: :blob})
      .complete
      .order(inspection_date: :desc)
  end

  def self.generate_unit_report_content(pdf, unit, completed_inspections, unbranded)
    HeaderGenerator.generate_unit_pdf_header(pdf, unit, unbranded: unbranded)
    generate_unit_details_with_inspection(pdf, unit, completed_inspections.first)
    generate_unit_inspection_history_with_data(pdf, unit, completed_inspections)
  end

  def self.add_unit_footer_and_photo(pdf, unit, unbranded)
    DisclaimerFooterRenderer.render_disclaimer_footer(pdf, unit.user, unbranded: unbranded)
    ImageProcessor.add_unit_photo_footer(pdf, unit, 3) if unit.photo
  end

  def self.generate_inspection_unit_details(pdf, inspection)
    unit = inspection.unit

    return unless unit

    unit_data = TableBuilder.build_unit_details_table_with_inspection(unit, inspection, :inspection)
    TableBuilder.create_unit_details_table(pdf, I18n.t("pdf.inspection.equipment_details"), unit_data)

    # Hide the table entirely when no unit is associated
  end

  def self.generate_unit_details(pdf, unit)
    unit_data = TableBuilder.build_unit_details_table(unit, :unit)
    TableBuilder.create_unit_details_table(pdf, I18n.t("pdf.unit.details"), unit_data)
  end

  def self.generate_unit_details_with_inspection(pdf, unit, _last_inspection)
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
      TableBuilder.create_nice_box_table(pdf, I18n.t("pdf.unit.inspection_history"),
        [[I18n.t("pdf.unit.no_completed_inspections"), ""]])
    else
      TableBuilder.create_inspection_history_table(pdf, I18n.t("pdf.unit.inspection_history"), completed_inspections)
    end
  end

  def self.generate_unit_inspection_history_with_data(pdf, _unit, completed_inspections)
    if completed_inspections.empty?
      TableBuilder.create_nice_box_table(pdf, I18n.t("pdf.unit.inspection_history"),
        [[I18n.t("pdf.unit.no_completed_inspections"), ""]])
    else
      TableBuilder.create_inspection_history_table(pdf, I18n.t("pdf.unit.inspection_history"), completed_inspections)
    end
  end

  def self.generate_risk_assessment_section(pdf, inspection)
    return if inspection.risk_assessment.blank?

    pdf.text I18n.t("pdf.inspection.risk_assessment"), size: HEADER_TEXT_SIZE, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    render_risk_assessment_text_box(pdf, inspection.risk_assessment)
  end

  def self.render_risk_assessment_text_box(pdf, text)
    line_height = 10 * 1.2
    max_height = line_height * 4

    pdf.text_box text,
      at: [0, pdf.cursor],
      width: pdf.bounds.width,
      height: max_height,
      size: 10,
      overflow: :shrink_to_fit,
      min_font_size: 5

    pdf.move_down max_height + 15
  end

  def self.generate_assessments_in_ui_order(inspection, assessment_blocks)
    # Get the UI order from applicable_tabs (excluding non-assessment tabs)
    ui_ordered_tabs = inspection.applicable_tabs - %w[inspection results]

    ui_ordered_tabs.each do |tab_name|
      assessment_key = :"#{tab_name}_assessment"
      next unless inspection.assessment_applicable?(assessment_key)

      assessment = inspection.send(assessment_key)
      next unless assessment

      # Build blocks for this assessment and add to the main array
      blocks = AssessmentBlockBuilder.build_from_assessment(tab_name, assessment)
      assessment_blocks.concat(blocks)
    end
  end

  def self.render_assessment_blocks_in_columns(pdf, assessment_blocks, disclaimer_height, photo_height)
    return if assessment_blocks.empty?

    pdf.text I18n.t("pdf.inspection.assessments_section"), size: 12, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 15

    available_height = calculate_available_assessment_height(pdf, disclaimer_height)
    renderer = AssessmentColumns.new(assessment_blocks, available_height, photo_height)
    renderer.render(pdf)
    pdf.move_down 20
  end

  def self.calculate_available_assessment_height(pdf, disclaimer_height)
    available = (pdf.page_number == 1) ? (pdf.cursor - disclaimer_height) : pdf.cursor
    return available if available >= 100

    pdf.start_new_page
    pdf.cursor
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
