class PdfGeneratorService
  def self.generate_inspection_report(inspection)
    require "prawn/table"

    Prawn::Document.new do |pdf|
      setup_pdf_fonts(pdf)
      generate_inspection_pdf_header(pdf, inspection)
      generate_inspection_equipment_details(pdf, inspection)
      generate_inspection_test_results(pdf, inspection)
      generate_inspection_comments(pdf, inspection) if inspection.comments.present?
      generate_inspection_qr_code(pdf, inspection)
      generate_inspection_pdf_footer(pdf)
    end
  end

  def self.generate_unit_report(unit)
    require "prawn/table"

    Prawn::Document.new do |pdf|
      setup_pdf_fonts(pdf)
      generate_unit_pdf_header(pdf, unit)
      generate_unit_details(pdf, unit)
      generate_unit_inspection_history(pdf, unit) if unit.inspections.any?
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
    pdf.text I18n.t("pdf.inspection.title"), size: 20, style: :bold, align: :center
    pdf.move_down 20

    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 50) do
      pdf.stroke_bounds
      pdf.move_down 5
      pdf.text "#{I18n.t("pdf.inspection.fields.serial_number")}: #{inspection.serial}", align: :center, size: 14
      pdf.move_down 2
      status_text = inspection.passed ? I18n.t("pdf.inspection.passed") : I18n.t("pdf.inspection.failed")
      pdf.text status_text, align: :center, size: 14,
        style: :bold, color: inspection.passed ? "009900" : "CC0000"
    end
    pdf.move_down 20
  end

  def self.generate_inspection_equipment_details(pdf, inspection)
    pdf.text I18n.t("pdf.inspection.equipment_details"), size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    data = [
      [I18n.t("pdf.inspection.fields.serial_number"), inspection.serial],
      [I18n.t("pdf.inspection.fields.manufacturer"), inspection.manufacturer.presence || I18n.t("pdf.inspection.fields.not_specified")],
      [I18n.t("pdf.inspection.fields.inspection_location"), inspection.inspection_location]
    ]

    create_pdf_table(pdf, data)
    pdf.move_down 20
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

    # Create table headers
    headers = [
      I18n.t("pdf.unit.fields.date"),
      I18n.t("pdf.unit.fields.inspector"),
      I18n.t("pdf.unit.fields.result"),
      I18n.t("pdf.unit.fields.comments")
    ]

    # Create table data from inspections
    inspections_data = unit.inspections.order(inspection_date: :desc).map do |inspection|
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
        inspection = unit.inspections.order(inspection_date: :desc)[index]
        table.row(index + 1).column(2).background_color = inspection.passed ? "CCFFCC" : "FFCCCC"
      end

      # Set column widths
      table.column(0).width = 75  # Date
      table.column(1).width = 85  # Inspector
      table.column(2).width = 60  # Result
      table.column(3).width = pdf.bounds.width - 220  # Comments - remaining width
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
end
