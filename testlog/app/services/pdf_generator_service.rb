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
      generate_inspection_qr_code(pdf, inspection)

      # Add DRAFT watermark overlay for draft inspections
      add_draft_watermark(pdf) if inspection.status == "draft"

      # Footer
      generate_inspection_pdf_footer(pdf)
    end
  end

  def self.generate_unit_report(unit)
    require "prawn/table"

    Prawn::Document.new do |pdf|
      setup_pdf_fonts(pdf)
      generate_unit_pdf_header(pdf, unit)
      generate_unit_details(pdf, unit)
      generate_unit_inspection_history(pdf, unit)
      generate_unit_qr_code(pdf, unit)
      generate_unit_footer(pdf)
    end
  end

  def self.generate_equipment_report(equipment)
    require "prawn/table"

    Prawn::Document.new do |pdf|
      setup_pdf_fonts(pdf)
      generate_equipment_pdf_header(pdf, equipment)
      generate_equipment_details(pdf, equipment)
      generate_equipment_inspection_history(pdf, equipment) if equipment.inspections.any?
      generate_equipment_qr_code(pdf, equipment)
      generate_equipment_footer(pdf)
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
      pdf.text "Issued by: #{inspection.inspector_company.name}", size: 12, style: :bold
    end
    pdf.move_down 5

    # Issue date
    pdf.text "Issued #{inspection.inspection_date&.strftime("%d/%m/%Y") || "N/A"}",
      size: 14, style: :bold, color: "CC0000"
    pdf.move_down 5

    # RPII Registration Number
    if inspection.inspector_company&.rpii_registration_number.present?
      pdf.text "RPII Reg Number: #{inspection.inspector_company.rpii_registration_number}",
        size: 14, style: :bold, color: "CC0000"
    end
    pdf.move_down 5

    # Place of Inspection
    if inspection.inspection_location.present?
      pdf.text "Place of Inspection: #{inspection.inspection_location}",
        size: 8, style: :bold, color: "CC0000"
    end
    pdf.move_down 5

    # Unique Report Number
    pdf.text "Unique Report Number: #{inspection.id}", size: 12, style: :bold, color: "CC0000"
    pdf.move_down 20
  end

  def self.generate_inspection_equipment_details(pdf, inspection)
    pdf.text I18n.t("pdf.inspection.equipment_details"), size: 12, style: :bold
    pdf.move_down 5

    unit = inspection.unit

    if unit
      # Description/Name
      pdf.text "Description: #{truncate_text(unit.name || unit.description || "N/A", 66)}", size: 8

      # Manufacturer
      manufacturer_text = unit.manufacturer.presence || I18n.t("pdf.inspection.fields.not_specified")
      pdf.text "#{I18n.t("pdf.inspection.fields.manufacturer")}: #{manufacturer_text}", size: 8

      # Size dimensions
      dimensions = []
      dimensions << "Width: #{unit.width}" if unit.width.present?
      dimensions << "Length: #{unit.length}" if unit.length.present?
      dimensions << "Height: #{unit.height}" if unit.height.present?

      if dimensions.any?
        pdf.text "Size (m): #{dimensions.join(" ")}", size: 8
      end

      # Serial Number
      pdf.text "Serial Number / Asset ID: #{unit.serial_number || "N/A"}", size: 8

      # Owner
      pdf.text "Owner: #{unit.owner || "N/A"}", size: 8 if unit.owner.present?

      # Unit Type / Has Slide
      unit_type = unit.has_slide? ? "Unit with Slide" : "Standard Unit"
      pdf.text "Type: #{unit_type}", size: 8
    else
      pdf.text "No unit associated with this inspection", size: 8, style: :italic
    end

    pdf.move_down 15
  end

  def self.generate_inspection_test_results(pdf, inspection)
    pdf.text I18n.t("pdf.inspection.inspection_results"), size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    results = [
      [I18n.t("pdf.inspection.fields.inspection_date"), inspection.inspection_date&.strftime("%d/%m/%Y")],
      [I18n.t("pdf.inspection.fields.reinspection_due"), inspection.reinspection_date&.strftime("%d/%m/%Y")],
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

  def self.generate_inspection_qr_code(pdf, inspection)
    pdf.move_down 20
    pdf.text I18n.t("pdf.inspection.verification"), size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    # Generate QR code
    qr_code_png = QrCodeService.generate_qr_code(inspection)
    qr_code_temp_file = Tempfile.new(["qr_code", ".png"])

    begin
      qr_code_temp_file.binmode
      qr_code_temp_file.write(qr_code_png)
      qr_code_temp_file.close

      # Add QR code image and URL text
      pdf.image qr_code_temp_file.path, position: :center, width: 180
      pdf.move_down 5
      pdf.text I18n.t("pdf.inspection.scan_text"), align: :center, size: 10
      pdf.text "#{ENV["BASE_URL"]}/r/#{inspection.id}",
        align: :center, size: 10, style: :italic
    ensure
      qr_code_temp_file.unlink
    end
  end

  def self.generate_inspection_pdf_footer(pdf)
    pdf.move_down 30
    pdf.text "#{I18n.t("pdf.inspection.generated_text")} #{Time.now.strftime("%d/%m/%Y at %H:%M")}",
      size: 10, align: :center, style: :italic
    pdf.text I18n.t("pdf.inspection.footer_text"), size: 10, align: :center, style: :italic
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

  # Equipment report methods
  def self.generate_equipment_pdf_header(pdf, equipment)
    pdf.text I18n.t("pdf.equipment.title"), size: 20, style: :bold, align: :center
    pdf.move_down 20

    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 70) do
      pdf.stroke_bounds
      pdf.move_down 5
      pdf.text "Equipment: #{equipment.name}", align: :center, size: 14, style: :bold
      pdf.move_down 2
      pdf.text "#{I18n.t("pdf.equipment.fields.serial_number")}: #{equipment.serial}", align: :center, size: 14
      pdf.move_down 2
      if equipment.last_due_date
        pdf.text "#{I18n.t("pdf.equipment.next_due")}: #{equipment.last_due_date.strftime("%d/%m/%Y")}",
          align: :center, size: 14,
          color: (equipment.last_due_date < Date.today) ? "CC0000" : "000000"
      end
    end
    pdf.move_down 20
  end

  def self.generate_equipment_details(pdf, equipment)
    pdf.text I18n.t("pdf.equipment.details"), size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    data = [
      [I18n.t("pdf.equipment.fields.name"), equipment.name],
      [I18n.t("pdf.equipment.fields.serial_number"), equipment.serial],
      [I18n.t("pdf.equipment.fields.manufacturer"), equipment.manufacturer.presence || I18n.t("pdf.equipment.fields.not_specified")],
      [I18n.t("pdf.equipment.fields.location"), equipment.location]
    ]

    # Add next inspection due if available
    if equipment.last_due_date
      data << [I18n.t("pdf.equipment.fields.next_inspection_due"), equipment.last_due_date.strftime("%d/%m/%Y")]
    end

    create_pdf_table(pdf, data)
    pdf.move_down 20
  end

  def self.generate_equipment_inspection_history(pdf, equipment)
    pdf.text I18n.t("pdf.equipment.inspection_history"), size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    # Create table headers
    headers = [
      I18n.t("pdf.equipment.fields.date"),
      I18n.t("pdf.equipment.fields.inspector"),
      I18n.t("pdf.equipment.fields.result"),
      I18n.t("pdf.equipment.fields.comments")
    ]

    # Create table data from inspections
    inspections_data = equipment.inspections.order(inspection_date: :desc).map do |inspection|
      [
        inspection.inspection_date&.strftime("%d/%m/%Y") || I18n.t("pdf.equipment.fields.na"),
        inspection.inspector_company.name,
        inspection.passed ? I18n.t("pdf.equipment.fields.pass") : I18n.t("pdf.equipment.fields.fail"),
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
        inspection = equipment.inspections.order(inspection_date: :desc)[index]
        table.row(index + 1).column(2).background_color = inspection.passed ? "CCFFCC" : "FFCCCC"
      end

      # Set column widths
      table.column(0).width = 75  # Date
      table.column(1).width = 85  # Inspector
      table.column(2).width = 60  # Result
      table.column(3).width = pdf.bounds.width - 220  # Comments - remaining width
    end
  end

  def self.generate_equipment_qr_code(pdf, equipment)
    pdf.move_down 20
    pdf.text I18n.t("pdf.equipment.verification"), size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    # Generate QR code
    qr_code_png = QrCodeService.generate_qr_code(equipment)
    qr_code_temp_file = Tempfile.new(["qr_code", ".png"])

    begin
      qr_code_temp_file.binmode
      qr_code_temp_file.write(qr_code_png)
      qr_code_temp_file.close

      # Add QR code image and URL text
      pdf.image qr_code_temp_file.path, position: :center, width: 180
      pdf.move_down 5
      pdf.text I18n.t("pdf.equipment.scan_text"), align: :center, size: 10
      pdf.text "#{ENV["BASE_URL"]}/u/#{equipment.id}",
        align: :center, size: 10, style: :italic
    ensure
      qr_code_temp_file.unlink
    end
  end

  def self.generate_equipment_footer(pdf)
    pdf.move_down 30
    pdf.text "#{I18n.t("pdf.equipment.generated_text")} #{Time.now.strftime("%d/%m/%Y at %H:%M")}",
      size: 10, align: :center, style: :italic
    pdf.text I18n.t("pdf.equipment.footer_text"), size: 10, align: :center, style: :italic
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
      [I18n.t("pdf.unit.fields.serial_number"), unit.serial_number || unit.serial],
      [I18n.t("pdf.unit.fields.manufacturer"), unit.manufacturer.presence || I18n.t("pdf.unit.fields.not_specified")],
      [I18n.t("pdf.unit.fields.has_slide"), unit.has_slide? ? "Yes" : "No"],
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
    completed_inspections = unit.inspections.where(status: "complete").order(inspection_date: :desc)

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

  def self.generate_unit_qr_code(pdf, unit)
    pdf.move_down 20
    pdf.text I18n.t("pdf.unit.verification"), size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    # Generate QR code
    qr_code_png = QrCodeService.generate_qr_code(unit)
    qr_code_temp_file = Tempfile.new(["qr_code", ".png"])

    begin
      qr_code_temp_file.binmode
      qr_code_temp_file.write(qr_code_png)
      qr_code_temp_file.close

      # Add QR code image and URL text
      pdf.image qr_code_temp_file.path, position: :center, width: 180
      pdf.move_down 5
      pdf.text I18n.t("pdf.unit.scan_text"), align: :center, size: 10
      pdf.text "#{ENV["BASE_URL"]}/u/#{unit.id}",
        align: :center, size: 10, style: :italic
    ensure
      qr_code_temp_file.unlink
    end
  end

  def self.generate_unit_footer(pdf)
    pdf.move_down 30
    pdf.text "#{I18n.t("pdf.unit.generated_text")} #{Time.now.strftime("%d/%m/%Y at %H:%M")}",
      size: 10, align: :center, style: :italic
    pdf.text I18n.t("pdf.unit.footer_text"), size: 10, align: :center, style: :italic
  end

  # Assessment section generators
  def self.generate_user_height_section(pdf, inspection)
    pdf.text "User Height/Count", size: 12, style: :bold
    pdf.move_down 5

    assessment = inspection.user_height_assessment

    if assessment
      # Containing Wall Height
      pdf.text "Containing wall height: #{format_measurement(assessment.containing_wall_height, "m")} #{truncate_text(assessment.containing_wall_height_comment, 60)}", size: 8

      # Platform Height
      pdf.text "Platform height: #{format_measurement(assessment.platform_height, "m")} #{truncate_text(assessment.platform_height_comment, 60)}", size: 8

      # Permanent Roof
      if !assessment.permanent_roof.nil?
        pdf.text "Permanent roof: #{assessment.permanent_roof ? "Yes" : "No"} #{truncate_text(assessment.permanent_roof_comment, 60)}", size: 8
      end

      # User Height
      pdf.text "User height: #{format_measurement(assessment.user_height, "m")} #{truncate_text(assessment.user_height_comment, 60)}", size: 8

      # Play Area Dimensions
      pdf.text "Play area length: #{format_measurement(assessment.play_area_length, "m")} #{truncate_text(assessment.play_area_length_comment, 60)}", size: 8
      pdf.text "Play area width: #{format_measurement(assessment.play_area_width, "m")} #{truncate_text(assessment.play_area_width_comment, 60)}", size: 8

      # Negative Adjustment
      if assessment.negative_adjustment.present?
        pdf.text "Negative adjustment: #{format_measurement(assessment.negative_adjustment, "m²")} #{truncate_text(assessment.negative_adjustment_comment, 60)}", size: 8
      end

      pdf.move_down 5

      # User Capacities
      pdf.text "User capacities:", size: 8, style: :bold
      pdf.text "• 1.0m users: #{assessment.users_at_1000mm || "N/A"}", size: 8
      pdf.text "• 1.2m users: #{assessment.users_at_1200mm || "N/A"}", size: 8
      pdf.text "• 1.5m users: #{assessment.users_at_1500mm || "N/A"}", size: 8
      pdf.text "• 1.8m users: #{assessment.users_at_1800mm || "N/A"}", size: 8
    else
      pdf.text "No user height assessment data available", size: 8, style: :italic
    end

    pdf.move_down 15
  end

  def self.generate_slide_section(pdf, inspection)
    pdf.text "Slide", size: 12, style: :bold
    pdf.move_down 5

    assessment = inspection.slide_assessment

    if assessment
      # Platform Height
      pdf.text "Slide platform height: #{format_measurement(assessment.slide_platform_height, "m")} #{truncate_text(assessment.slide_platform_height_comment, 60)}", size: 8

      # Wall Height
      pdf.text "Slide wall height: #{format_measurement(assessment.slide_wall_height, "m")} #{truncate_text(assessment.slide_wall_height_comment, 60)}", size: 8

      # First Metre Height
      pdf.text "Slide 1st metre wall height: #{format_measurement(assessment.slide_first_metre_height, "m")} #{truncate_text(assessment.slide_first_metre_height_comment, 60)}", size: 8

      # Beyond First Metre
      pdf.text "Slide wall height after 1st metre: #{format_measurement(assessment.slide_beyond_first_metre_height, "m")} #{truncate_text(assessment.slide_beyond_first_metre_height_comment, 60)}", size: 8

      # Permanent Roof
      if !assessment.slide_permanent_roof.nil?
        pdf.text "Slide permanent roof: #{assessment.slide_permanent_roof ? "Yes" : "No"} #{truncate_text(assessment.slide_permanent_roof_comment, 60)}", size: 8
      end

      # Clamber Netting
      pdf.text "Clamber netting suitable: #{format_pass_fail(assessment.clamber_netting_pass)} #{truncate_text(assessment.clamber_netting_comment, 60)}", size: 8

      # Runout
      pdf.text "Run-out: #{format_measurement(assessment.runout_value, "m")} - #{format_pass_fail(assessment.runout_pass)} #{truncate_text(assessment.runout_comment, 60)}", size: 8

      # Slip Sheet
      pdf.text "Slip sheet where applicable: #{format_pass_fail(assessment.slip_sheet_pass)} #{truncate_text(assessment.slip_sheet_comment, 60)}", size: 8
    else
      pdf.text "No slide assessment data available", size: 8, style: :italic
    end

    pdf.move_down 15
  end

  def self.generate_structure_section(pdf, inspection)
    pdf.text "Structure", size: 12, style: :bold
    pdf.move_down 5

    assessment = inspection.structure_assessment

    if assessment
      # Critical checks
      pdf.text "Seam integrity: #{format_pass_fail(assessment.seam_integrity_pass)} #{truncate_text(assessment.seam_integrity_comment, 60)}", size: 8
      pdf.text "Lock stitch: #{format_pass_fail(assessment.lock_stitch_pass)} #{truncate_text(assessment.lock_stitch_comment, 60)}", size: 8
      pdf.text "Stitch length: #{format_measurement(assessment.stitch_length, "mm")} - #{format_pass_fail(assessment.stitch_length_pass)} #{truncate_text(assessment.stitch_length_comment, 60)}", size: 8
      pdf.text "Air loss: #{format_pass_fail(assessment.air_loss_pass)} #{truncate_text(assessment.air_loss_comment, 60)}", size: 8
      pdf.text "Straight walls: #{format_pass_fail(assessment.straight_walls_pass)} #{truncate_text(assessment.straight_walls_comment, 60)}", size: 8
      pdf.text "Sharp edges: #{format_pass_fail(assessment.sharp_edges_pass)} #{truncate_text(assessment.sharp_edges_comment, 60)}", size: 8
      pdf.text "Blower tube length: #{format_measurement(assessment.blower_tube_length, "m")} - #{format_pass_fail(assessment.blower_tube_length_pass)} #{truncate_text(assessment.blower_tube_length_comment, 60)}", size: 8
      pdf.text "Unit stable: #{format_pass_fail(assessment.unit_stable_pass)} #{truncate_text(assessment.unit_stable_comment, 60)}", size: 8
      pdf.text "Evacuation time <30s: #{format_pass_fail(assessment.evacuation_time_pass)} #{truncate_text(assessment.evacuation_time_comment, 60)}", size: 8
    else
      pdf.text "No structure assessment data available", size: 8, style: :italic
    end

    pdf.move_down 15
  end

  def self.generate_anchorage_section(pdf, inspection)
    pdf.text "Anchorage", size: 12, style: :bold
    pdf.move_down 5

    assessment = inspection.anchorage_assessment
    if assessment
      pdf.text "Number of anchors: Low: #{assessment.num_low_anchors || "N/A"}, High: #{assessment.num_high_anchors || "N/A"} - #{format_pass_fail(assessment.num_anchors_pass)}", size: 8
      pdf.text "Anchor type: #{format_pass_fail(assessment.anchor_type_pass)}", size: 8
      pdf.text "Pull strength: #{format_pass_fail(assessment.pull_strength_pass)}", size: 8
      pdf.text "Anchor degree: #{format_pass_fail(assessment.anchor_degree_pass)}", size: 8
      pdf.text "Anchor accessories: #{format_pass_fail(assessment.anchor_accessories_pass)}", size: 8
    else
      pdf.text "No anchorage assessment data available", size: 8, style: :italic
    end

    pdf.move_down 15
  end

  def self.generate_enclosed_section(pdf, inspection)
    pdf.text "Totally Enclosed", size: 12, style: :bold
    pdf.move_down 5

    assessment = inspection.enclosed_assessment
    if assessment
      pdf.text "Exit number: #{assessment.exit_number || "N/A"} - #{format_pass_fail(assessment.exit_number_pass)}", size: 8
      pdf.text "Exits visible: #{format_pass_fail(assessment.exit_visible_pass)}", size: 8
    else
      pdf.text "No enclosed assessment data available", size: 8, style: :italic
    end

    pdf.move_down 15
  end

  def self.generate_materials_section(pdf, inspection)
    pdf.text "Materials", size: 12, style: :bold
    pdf.move_down 5

    assessment = inspection.materials_assessment
    if assessment
      pdf.text "Fabric: #{format_pass_fail(assessment.fabric_pass)}", size: 8
      pdf.text "Fire retardant: #{format_pass_fail(assessment.fire_retardant_pass)}", size: 8
      pdf.text "Thread: #{format_pass_fail(assessment.thread_pass)}", size: 8
      pdf.text "Rope size: #{format_measurement(assessment.rope_size, "mm")} - #{format_pass_fail(assessment.rope_size_pass)}", size: 8
    else
      pdf.text "No materials assessment data available", size: 8, style: :italic
    end

    pdf.move_down 15
  end

  def self.generate_fan_section(pdf, inspection)
    pdf.text "Fan/Blower", size: 12, style: :bold
    pdf.move_down 5

    assessment = inspection.fan_assessment
    if assessment
      pdf.text "Blower flap: #{format_pass_fail(assessment.blower_flap_pass)}", size: 8
      pdf.text "Finger guard: #{format_pass_fail(assessment.blower_finger_pass)}", size: 8
      pdf.text "PAT test: #{format_pass_fail(assessment.pat_pass)}", size: 8
      pdf.text "Visual inspection: #{format_pass_fail(assessment.blower_visual_pass)}", size: 8
    else
      pdf.text "No fan assessment data available", size: 8, style: :italic
    end

    pdf.move_down 15
  end

  def self.generate_risk_assessment_section(pdf, inspection)
    # This section doesn't exist in the current model
    # Placeholder for future implementation
  end

  def self.generate_final_result(pdf, inspection)
    pdf.text "Final Result", size: 14, style: :bold
    pdf.move_down 5

    result_text = inspection.passed? ? "PASSED" : "FAILED"
    result_color = inspection.passed? ? "008000" : "CC0000"

    pdf.text result_text, size: 16, style: :bold, color: result_color
    pdf.move_down 10

    pdf.text "Status: #{inspection.status.humanize}", size: 10
    pdf.move_down 15
  end

  # Helper methods
  def self.truncate_text(text, max_length)
    return "" if text.nil?
    (text.length > max_length) ? "#{text[0...max_length]}..." : text
  end

  def self.format_pass_fail(value)
    case value
    when true then "Pass"
    when false then "Fail"
    else "N/A"
    end
  end

  def self.format_measurement(value, unit = "")
    return "N/A" if value.nil?
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
            pdf.text_box "DRAFT",
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
