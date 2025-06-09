class PdfGeneratorService
  def self.generate_inspection_report(inspection)
    require "prawn/table"

    Prawn::Document.new do |pdf|
      setup_pdf_fonts(pdf)

      # Header section
      generate_inspection_pdf_header(pdf, inspection)

      # Unit details section
      generate_inspection_equipment_details(pdf, inspection)

      # Inspection results section
      generate_inspection_test_results(pdf, inspection)

      # User Height/Count Assessment section
      generate_user_height_section(pdf, inspection)

      # Slide Assessment section (if unit has slide)
      generate_slide_section(pdf, inspection) if inspection.unit&.has_slide?

      # Structure Assessment section
      generate_structure_section(pdf, inspection)

      # Start two-column layout for remaining sections
      pdf.column_box([0, pdf.cursor], columns: 2, width: pdf.bounds.width, height: 400) do
        # Anchorage Assessment
        generate_anchorage_section(pdf, inspection)

        # Totally Enclosed section (if applicable)
        generate_enclosed_section(pdf, inspection) if inspection.unit&.is_totally_enclosed?

        # Materials Assessment
        generate_materials_section(pdf, inspection)

        # Fan/Blower Assessment
        generate_fan_section(pdf, inspection)
      end

      # Risk Assessment section
      generate_risk_assessment_section(pdf, inspection)

      # Testimony/Comments section
      generate_inspection_comments(pdf, inspection)

      # Final Result
      generate_final_result(pdf, inspection)

      # QR Code
      generate_qr_code_section(pdf, inspection, "inspection")

      # Add DRAFT watermark overlay for draft inspections
      add_draft_watermark(pdf) unless inspection.complete?

      # Footer
      generate_footer(pdf, "inspection")
    end
  end

  def self.generate_unit_report(unit)
    require "prawn/table"

    Prawn::Document.new do |pdf|
      setup_pdf_fonts(pdf)
      generate_unit_pdf_header(pdf, unit)
      generate_unit_details(pdf, unit)
      generate_unit_inspection_history(pdf, unit)
      generate_qr_code_section(pdf, unit, "unit")
      generate_footer(pdf, "unit")
    end
  end

  def self.setup_pdf_fonts(pdf)
    font_path = Rails.root.join("app", "assets", "fonts")
    pdf.font_families.update(
      "NotoSans" => {
        normal: "#{font_path}/NotoSans-Regular.ttf",
        bold: "#{font_path}/NotoSans-Bold.ttf",
        italic: "#{font_path}/NotoSans-Regular.ttf",
        bold_italic: "#{font_path}/NotoSans-Bold.ttf"
      },
      "NotoEmoji" => {
        normal: "#{font_path}/NotoEmoji-Regular.ttf"
      }
    )
    pdf.font "NotoSans"
  end

  def self.generate_inspection_pdf_header(pdf, inspection)
    # Add unit photo to top right if available
    add_unit_photo(pdf, inspection.unit)

    # Inspection Report title
    pdf.text I18n.t("pdf.inspection.title"), size: 14, style: :bold, color: "CC0000"
    pdf.move_down 5

    # Issued by company
    if inspection.inspector_company&.name.present?
      pdf.text "#{I18n.t("pdf.inspection.fields.issued_by")}: #{inspection.inspector_company.name}", size: 12, style: :bold
    end
    pdf.move_down 5

    # Issue date
    pdf.text "#{I18n.t("pdf.inspection.fields.issued")} #{inspection.inspection_date&.strftime("%d/%m/%Y") || I18n.t("pdf.inspection.fields.na")}",
      size: 14, style: :bold, color: "CC0000"
    pdf.move_down 5

    # RPII Registration Number
    if inspection.inspector_company&.rpii_registration_number.present?
      pdf.text "#{I18n.t("pdf.inspection.fields.rpii_reg_number")}: #{inspection.inspector_company.rpii_registration_number}",
        size: 14, style: :bold, color: "CC0000"
    end
    pdf.move_down 5

    # Place of Inspection
    if inspection.inspection_location.present?
      pdf.text "#{I18n.t("pdf.inspection.fields.place_of_inspection")}: #{inspection.inspection_location}",
        size: 8, style: :bold, color: "CC0000"
    end
    pdf.move_down 5

    # Unique Report Number
    pdf.text "#{I18n.t("pdf.inspection.fields.unique_report_number")}: #{inspection.id}", size: 12, style: :bold, color: "CC0000"
    pdf.move_down 20
  end

  def self.generate_inspection_equipment_details(pdf, inspection)
    pdf.text I18n.t("pdf.inspection.equipment_details"), size: 12, style: :bold
    pdf.move_down 5

    unit = inspection.unit

    if unit
      # Description/Name
      pdf.text "#{I18n.t("pdf.inspection.fields.description")}: #{truncate_text(unit.name || unit.description || I18n.t("pdf.inspection.fields.na"), 66)}", size: 8

      # Manufacturer
      manufacturer_text = unit.manufacturer.presence || I18n.t("pdf.inspection.fields.not_specified")
      pdf.text "#{I18n.t("pdf.inspection.fields.manufacturer")}: #{manufacturer_text}", size: 8

      # Size dimensions
      dimensions = []
      dimensions << "Width: #{unit.width}" if unit.width.present?
      dimensions << "Length: #{unit.length}" if unit.length.present?
      dimensions << "Height: #{unit.height}" if unit.height.present?

      if dimensions.any?
        pdf.text "#{I18n.t("pdf.inspection.fields.size_m")}: #{dimensions.join(" ")}", size: 8
      end

      # Serial Number
      pdf.text "#{I18n.t("pdf.inspection.fields.serial_number_asset_id")}: #{unit.serial || I18n.t("pdf.inspection.fields.na")}", size: 8

      # Owner
      pdf.text "#{I18n.t("pdf.inspection.fields.owner")}: #{unit.owner || I18n.t("pdf.inspection.fields.na")}", size: 8 if unit.owner.present?

      # Unit Type / Has Slide
      unit_type = unit.has_slide? ? I18n.t("pdf.inspection.fields.unit_with_slide") : I18n.t("pdf.inspection.fields.standard_unit")
      pdf.text "#{I18n.t("pdf.inspection.fields.type")}: #{unit_type}", size: 8
    else
      pdf.text I18n.t("pdf.inspection.fields.no_unit_associated"), size: 8, style: :italic
    end

    pdf.move_down 15
  end

  def self.generate_inspection_test_results(pdf, inspection)
    pdf.text I18n.t("pdf.inspection.inspection_results"), size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    results = [
      [I18n.t("pdf.inspection.fields.inspection_date"), inspection.inspection_date&.strftime("%d/%m/%Y")],
      [I18n.t("pdf.inspection.fields.inspector"), inspection.inspector_company.name],
      [I18n.t("pdf.inspection.fields.overall_result"), inspection.passed ? I18n.t("pdf.inspection.fields.pass") : I18n.t("pdf.inspection.fields.fail")]
    ]

    create_pdf_table(pdf, results) do |table|
      table.row(results.length - 1).background_color = inspection.passed ? "CCFFCC" : "FFCCCC"
    end
  end

  def self.generate_inspection_comments(pdf, inspection)
    pdf.move_down 20
    pdf.text I18n.t("pdf.inspection.comments"), size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10
    pdf.text inspection.comments
  end

  def self.create_pdf_table(pdf, data)
    table = pdf.table(data, width: pdf.bounds.width) do |t|
      t.cells.borders = []
      t.cells.padding = [5, 10]
      t.columns(0).font_style = :bold
      t.columns(0).width = 150
      t.row(0..data.length - 1).background_color = "EEEEEE"
      t.row(0..data.length - 1).borders = [:bottom]
      t.row(0..data.length - 1).border_color = "DDDDDD"
    end

    yield table if block_given?
    table
  end

  # Unit report methods (updated from equipment)
  def self.generate_unit_pdf_header(pdf, unit)
    # Add unit photo to top right if available
    add_unit_photo(pdf, unit)

    pdf.text I18n.t("pdf.unit.title"), size: 20, style: :bold, align: :center
    pdf.move_down 20

    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 70) do
      pdf.stroke_bounds
      pdf.move_down 5
      pdf.text "#{I18n.t("pdf.unit.fields.name").titleize}: #{unit.name}", align: :center, size: 14, style: :bold
      pdf.move_down 2
      pdf.text "#{I18n.t("pdf.unit.fields.serial_number")}: #{unit.serial}", align: :center, size: 14
      pdf.move_down 2
      if unit.next_inspection_due
        pdf.text "#{I18n.t("pdf.unit.next_due")}: #{unit.next_inspection_due.strftime("%d/%m/%Y")}",
          align: :center, size: 14,
          color: (unit.next_inspection_due < Date.today) ? "CC0000" : "000000"
      end
    end
    pdf.move_down 20
  end

  def self.generate_unit_details(pdf, unit)
    pdf.text I18n.t("pdf.unit.details"), size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    data = [
      [I18n.t("pdf.unit.fields.name"), unit.name],
      [I18n.t("pdf.unit.fields.serial_number"), unit.serial],
      [I18n.t("pdf.unit.fields.manufacturer"), unit.manufacturer.presence || I18n.t("pdf.unit.fields.not_specified")],
      [I18n.t("pdf.unit.fields.has_slide"), unit.has_slide? ? I18n.t("shared.yes") : I18n.t("shared.no")],
      [I18n.t("pdf.unit.fields.owner"), unit.owner],
      [I18n.t("pdf.unit.fields.dimensions"), unit.dimensions]
    ]

    # Add next inspection due if available
    if unit.next_inspection_due
      data << [I18n.t("pdf.unit.fields.next_inspection_due"), unit.next_inspection_due.strftime("%d/%m/%Y")]
    end

    create_pdf_table(pdf, data)
    pdf.move_down 20
  end

  def self.generate_unit_inspection_history(pdf, unit)
    pdf.text I18n.t("pdf.unit.inspection_history"), size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    # Check for completed inspections
    completed_inspections = unit.inspections.complete.order(inspection_date: :desc)

    if completed_inspections.empty?
      pdf.text I18n.t("pdf.unit.no_completed_inspections"), size: 10, style: :italic
      pdf.move_down 10
    else
      # Create table headers
      headers = [
        I18n.t("pdf.unit.fields.date"),
        I18n.t("pdf.unit.fields.inspector"),
        I18n.t("pdf.unit.fields.result"),
        I18n.t("pdf.unit.fields.comments")
      ]

      # Create table data from inspections
      inspections_data = completed_inspections.map do |inspection|
        [
          inspection.inspection_date&.strftime("%d/%m/%Y") || I18n.t("pdf.unit.fields.na"),
          inspection.inspector_company.name,
          inspection.passed ? I18n.t("pdf.unit.fields.pass") : I18n.t("pdf.unit.fields.fail"),
          inspection.comments.to_s.truncate(30)
        ]
      end

      # Combine headers and data
      table_data = [headers] + inspections_data

      # Create table
      pdf.table(table_data, width: pdf.bounds.width) do |table|
        table.cells.padding = [5, 5]
        table.row(0).font_style = :bold
        table.row(0).background_color = "DDDDDD"

        # Color code pass/fail cells
        inspections_data.each_with_index do |_, index|
          inspection = completed_inspections[index]
          table.row(index + 1).column(2).background_color = inspection.passed ? "CCFFCC" : "FFCCCC"
        end

        # Set column widths
        table.column(0).width = 75  # Date
        table.column(1).width = 85  # Inspector
        table.column(2).width = 60  # Result
        table.column(3).width = pdf.bounds.width - 220  # Comments - remaining width
      end
    end
  end

  # Assessment section generators
  def self.generate_user_height_section(pdf, inspection)
    generate_assessment_section(pdf, "user_height", inspection.user_height_assessment) do |assessment, type|
      # Standard measurement fields
      measurement_fields = [
        [:containing_wall_height, "m"],
        [:platform_height, "m"],
        [:tallest_user_height, "m"],
        [:play_area_length, "m"],
        [:play_area_width, "m"]
      ]
      
      measurement_fields.each do |field, unit|
        add_field_with_comment(pdf, assessment, field, unit, type)
      end

      # Permanent Roof
      if !assessment.permanent_roof.nil?
        add_boolean_field_with_comment(pdf, assessment, :permanent_roof, type)
      end

      # Negative Adjustment
      if assessment.negative_adjustment.present?
        add_field_with_comment(pdf, assessment, :negative_adjustment, "m²", type)
      end

      pdf.move_down 5

      # User Capacities
      pdf.text I18n.t("inspections.assessments.user_height.sections.user_capacities"), size: 8, style: :bold
      
      user_capacity_heights = [1000, 1200, 1500, 1800]
      user_capacity_heights.each do |height|
        field_name = "users_at_#{height}mm"
        value = assessment.send(field_name) || I18n.t("pdf.inspection.fields.na")
        pdf.text "• #{I18n.t("inspections.assessments.user_height.fields.#{field_name}")}: #{value}", size: 8
      end
    end
  end

  def self.generate_slide_section(pdf, inspection)
    generate_assessment_section(pdf, "slide", inspection.slide_assessment) do |assessment, type|
      # Height measurement fields
      height_fields = [
        [:slide_platform_height, "m"],
        [:slide_wall_height, "m"],
        [:slide_first_metre_height, "m"],
        [:slide_beyond_first_metre_height, "m"]
      ]
      
      height_fields.each do |field, unit|
        add_field_with_comment(pdf, assessment, field, unit, type)
      end

      # Permanent Roof
      if !assessment.slide_permanent_roof.nil?
        add_boolean_field_with_comment(pdf, assessment, :slide_permanent_roof, type)
      end

      # Pass/fail fields
      pass_fail_fields = [:clamber_netting_pass, :slip_sheet_pass]
      pass_fail_fields.each do |field|
        add_pass_fail_field_with_comment(pdf, assessment, field, type)
      end

      # Runout (special case with measurement and pass/fail)
      add_measurement_pass_fail_field(pdf, assessment, :runout_value, "m", :runout_pass, type)
    end
  end

  def self.generate_structure_section(pdf, inspection)
    generate_assessment_section(pdf, "structure", inspection.structure_assessment) do |assessment, type|
      # Simple pass/fail fields
      pass_fail_fields = [
        :seam_integrity_pass,
        :lock_stitch_pass,
        :air_loss_pass,
        :straight_walls_pass,
        :sharp_edges_pass,
        :unit_stable_pass,
        :evacuation_time_pass
      ]
      
      pass_fail_fields.each do |field|
        add_pass_fail_field_with_comment(pdf, assessment, field, type)
      end
      
      # Measurement fields with pass/fail
      measurement_fields = [
        [:stitch_length, "mm", :stitch_length_pass],
        [:blower_tube_length, "m", :blower_tube_length_pass],
        [:unit_pressure_value, "Pa", :unit_pressure_pass]
      ]
      
      measurement_fields.each do |value_field, unit, pass_field|
        add_measurement_pass_fail_field(pdf, assessment, value_field, unit, pass_field, type)
      end
    end
  end

  def self.generate_anchorage_section(pdf, inspection)
    generate_assessment_section(pdf, "anchorage", inspection.anchorage_assessment) do |assessment, type|
      # Number of anchors with special formatting
      label = I18n.t("inspections.assessments.anchorage.fields.num_anchors_pass")
      anchor_text = "#{label}: #{I18n.t("inspections.assessments.anchorage.fields.num_low_anchors")}: #{assessment.num_low_anchors || I18n.t("pdf.inspection.fields.na")}, #{I18n.t("inspections.assessments.anchorage.fields.num_high_anchors")}: #{assessment.num_high_anchors || I18n.t("pdf.inspection.fields.na")}"
      add_text_pass_fail_field(pdf, anchor_text, assessment, :num_anchors_pass)

      # Pass/fail fields
      pass_fail_fields = [
        :anchor_type_pass,
        :pull_strength_pass,
        :anchor_degree_pass,
        :anchor_accessories_pass
      ]
      
      pass_fail_fields.each do |field|
        add_pass_fail_field_with_comment(pdf, assessment, field, type)
      end
    end
  end

  def self.generate_enclosed_section(pdf, inspection)
    generate_assessment_section(pdf, "enclosed", inspection.enclosed_assessment) do |assessment, type|
      # Exit number with pass/fail
      label = I18n.t("inspections.assessments.enclosed.fields.exit_number")
      exit_text = "#{label}: #{assessment.exit_number || I18n.t("pdf.inspection.fields.na")}"
      add_text_pass_fail_field(pdf, exit_text, assessment, :exit_number_pass)

      add_pass_fail_field_with_comment(pdf, assessment, :exit_visible_pass, type)
    end
  end

  def self.generate_materials_section(pdf, inspection)
    generate_assessment_section(pdf, "materials", inspection.materials_assessment) do |assessment, type|
      # Pass/fail fields
      pass_fail_fields = [:fabric_pass, :fire_retardant_pass, :thread_pass]
      pass_fail_fields.each do |field|
        add_pass_fail_field_with_comment(pdf, assessment, field, type)
      end
      
      # Rope size with measurement
      add_measurement_pass_fail_field(pdf, assessment, :rope_size, "mm", :rope_size_pass, type)
    end
  end

  def self.generate_fan_section(pdf, inspection)
    generate_assessment_section(pdf, "fan", inspection.fan_assessment) do |assessment, type|
      # Pass/fail fields
      pass_fail_fields = [
        :blower_flap_pass,
        :blower_finger_pass,
        :pat_pass,
        :blower_visual_pass
      ]
      
      pass_fail_fields.each do |field|
        add_pass_fail_field_with_comment(pdf, assessment, field, type)
      end

      # Optional text fields
      optional_fields = [
        [:blower_serial, nil],
        [:fan_size_comment, 60]
      ]
      
      optional_fields.each do |field, truncate_length|
        if assessment.send(field).present?
          label = I18n.t("inspections.assessments.fan.fields.#{field}")
          value = assessment.send(field)
          value = truncate_text(value, truncate_length) if truncate_length
          pdf.text "#{label}: #{value}", size: 8
        end
      end
    end
  end

  def self.generate_risk_assessment_section(pdf, inspection)
    # This section doesn't exist in the current model
    # Placeholder for future implementation
  end

  def self.generate_final_result(pdf, inspection)
    pdf.text I18n.t("pdf.inspection.final_result"), size: 14, style: :bold
    pdf.move_down 5

    result_text = inspection.passed? ? I18n.t("pdf.inspection.fields.passed") : I18n.t("pdf.inspection.fields.failed")
    result_color = inspection.passed? ? "008000" : "CC0000"

    pdf.text result_text, size: 16, style: :bold, color: result_color
    pdf.move_down 10

    pdf.text "#{I18n.t("pdf.inspection.fields.status")}: #{inspection.complete? ? I18n.t("pdf.inspection.fields.complete") : I18n.t("pdf.inspection.fields.draft")}", size: 10
    pdf.move_down 15
  end

  # Generic helper methods for DRY code
  def self.generate_assessment_section(pdf, assessment_type, assessment)
    title = I18n.t("inspections.assessments.#{assessment_type}.title")
    pdf.text title, size: 12, style: :bold
    pdf.move_down 5

    if assessment
      yield(assessment, assessment_type)
    else
      pdf.text I18n.t("pdf.inspection.no_assessment_data", assessment_type: title), size: 8, style: :italic
    end

    pdf.move_down 15
  end

  # Generic field rendering method that handles all field types
  def self.add_field(pdf, assessment, field_name, assessment_type, options = {})
    # Extract options with defaults
    unit = options[:unit]
    pass_field = options[:pass_field]
    custom_label = options[:label]
    custom_text = options[:text]
    
    # Get the label
    label = custom_label || I18n.t("inspections.assessments.#{assessment_type}.fields.#{field_name}")
    
    # Get the value
    value = assessment.send(field_name) unless custom_text
    
    # Format the value based on field type
    formatted_value = if custom_text
      custom_text
    elsif unit
      format_measurement(value, unit)
    elsif field_name.to_s.include?("_pass")
      format_pass_fail(value)
    elsif [true, false].include?(value)
      value ? I18n.t("shared.yes") : I18n.t("shared.no")
    else
      value || I18n.t("pdf.inspection.fields.na")
    end
    
    # Build the text parts
    text_parts = []
    text_parts << "#{label}:" unless custom_text
    text_parts << formatted_value
    
    # Add pass/fail if specified
    if pass_field
      pass_fail = assessment.send(pass_field)
      text_parts << "-"
      text_parts << format_pass_fail(pass_fail)
    end
    
    # Add comment if it exists
    comment_field = derive_comment_field_name(field_name, pass_field)
    if assessment.respond_to?(comment_field)
      comment = assessment.send(comment_field)
      text_parts << truncate_text(comment, 60) if comment.present?
    end
    
    # Render the complete text
    pdf.text text_parts.join(" "), size: 8
  end

  # Derive the comment field name based on the main field or pass field
  def self.derive_comment_field_name(field_name, pass_field = nil)
    if pass_field
      # Use pass field as base, removing _pass suffix
      base_name = pass_field.to_s.gsub(/_pass$/, "")
    else
      # Use field name as base, removing _pass suffix if present
      base_name = field_name.to_s.gsub(/_pass$/, "")
    end
    "#{base_name}_comment"
  end

  # Wrapper methods for backward compatibility and clarity
  def self.add_field_with_comment(pdf, assessment, field_name, unit, assessment_type)
    add_field(pdf, assessment, field_name, assessment_type, unit: unit)
  end

  def self.add_boolean_field_with_comment(pdf, assessment, field_name, assessment_type)
    add_field(pdf, assessment, field_name, assessment_type)
  end

  def self.add_pass_fail_field_with_comment(pdf, assessment, field_name, assessment_type)
    add_field(pdf, assessment, field_name, assessment_type)
  end

  def self.add_measurement_pass_fail_field(pdf, assessment, value_field, unit, pass_field, assessment_type)
    add_field(pdf, assessment, value_field, assessment_type, unit: unit, pass_field: pass_field)
  end

  def self.add_text_pass_fail_field(pdf, text, assessment, pass_field)
    pass_fail = assessment.send(pass_field)
    # Remove _pass suffix to get the base field name for comment
    base_field_name = pass_field.to_s.gsub(/_pass$/, "")
    comment = assessment.send("#{base_field_name}_comment") if assessment.respond_to?("#{base_field_name}_comment")
    full_text = "#{text} - #{format_pass_fail(pass_fail)} #{truncate_text(comment, 60)}"
    pdf.text full_text, size: 8
  end

  # Generic QR code generation
  def self.generate_qr_code_section(pdf, record, type)
    pdf.move_down 20
    pdf.text I18n.t("pdf.#{type}.verification"), size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    # Generate QR code
    qr_code_png = QrCodeService.generate_qr_code(record)
    qr_code_temp_file = Tempfile.new(["qr_code_#{type}_#{record.id}_#{Process.pid}", ".png"])

    begin
      qr_code_temp_file.binmode
      qr_code_temp_file.write(qr_code_png)
      qr_code_temp_file.close

      # Add QR code image and URL text
      pdf.image qr_code_temp_file.path, position: :center, width: 180
      pdf.move_down 5
      pdf.text I18n.t("pdf.#{type}.scan_text"), align: :center, size: 10

      # Determine URL prefix based on type
      url_prefix = (type == "inspection") ? "r" : "u"
      pdf.text "#{ENV["BASE_URL"]}/#{url_prefix}/#{record.id}",
        align: :center, size: 10, style: :italic
    ensure
      qr_code_temp_file.close unless qr_code_temp_file.closed?
      qr_code_temp_file.unlink if File.exist?(qr_code_temp_file.path)
    end
  end

  # Generic footer
  def self.generate_footer(pdf, type)
    pdf.move_down 30
    pdf.text "#{I18n.t("pdf.#{type}.generated_text")} #{Time.now.strftime("%d/%m/%Y at %H:%M")}",
      size: 10, align: :center, style: :italic
    pdf.text I18n.t("pdf.#{type}.footer_text"), size: 10, align: :center, style: :italic
  end

  # Helper methods
  def self.truncate_text(text, max_length)
    return "" if text.nil?
    (text.length > max_length) ? "#{text[0...max_length]}..." : text
  end

  def self.format_pass_fail(value)
    case value
    when true then I18n.t("pdf.inspection.fields.pass")
    when false then I18n.t("pdf.inspection.fields.fail")
    else I18n.t("pdf.inspection.fields.na")
    end
  end

  def self.format_measurement(value, unit = "")
    return I18n.t("pdf.inspection.fields.na") if value.nil?
    "#{value}#{unit}"
  end

  def self.add_draft_watermark(pdf)
    # Add 3x3 grid of DRAFT watermarks to each page
    (1..pdf.page_count).each do |page_num|
      pdf.go_to_page(page_num)

      pdf.transparent(0.3) do
        pdf.fill_color "FF0000"

        # 3x3 grid positions
        y_positions = [0.10, 0.30, 0.50, 0.70, 0.9].map { |pct| pdf.bounds.height * pct }
        x_positions = [0.15, 0.50, 0.85].map { |pct| pdf.bounds.width * pct - 50 }

        y_positions.each do |y|
          x_positions.each do |x|
            pdf.text_box I18n.t("pdf.inspection.watermark.draft"),
              at: [x, y],
              width: 100,
              height: 60,
              size: 24,
              style: :bold,
              align: :center,
              valign: :top
          end
        end
      end

      pdf.fill_color "000000"
    end
  end

  def self.add_unit_photo(pdf, unit, x_position = nil, y_position = nil)
    return unless unit&.photo&.attached?

    # Default position: top right corner
    x_pos = x_position || (pdf.bounds.width - 130)
    y_pos = y_position || pdf.cursor

    begin
      pdf.image unit.photo, at: [x_pos, y_pos], width: 120, height: 90
    rescue => e
      # If image fails to load, just continue without it
      Rails.logger.warn "Failed to add unit photo to PDF: #{e.message}"
    end
  end
end
