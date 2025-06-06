class PdfGeneratorService
  def self.generate_inspection_certificate(inspection)
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

  def self.generate_equipment_certificate(equipment)
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
    pdf.text "Inspection Certificate", size: 20, style: :bold, align: :center
    pdf.move_down 20

    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 50) do
      pdf.stroke_bounds
      pdf.move_down 5
      pdf.text "Serial Number: #{inspection.serial}", align: :center, size: 14
      pdf.move_down 2
      pdf.text (inspection.passed ? "PASSED" : "FAILED").to_s, align: :center, size: 14,
        style: :bold, color: inspection.passed ? "009900" : "CC0000"
    end
    pdf.move_down 20
  end

  def self.generate_inspection_equipment_details(pdf, inspection)
    pdf.text "Equipment Details", size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    data = [
      ["Serial Number", inspection.serial],
      ["Manufacturer", inspection.manufacturer.presence || "Not specified"],
      ["Location", inspection.location]
    ]

    create_pdf_table(pdf, data)
    pdf.move_down 20
  end

  def self.generate_inspection_test_results(pdf, inspection)
    pdf.text "Inspection Results", size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    results = [
      ["Inspection Date", inspection.inspection_date&.strftime("%d/%m/%Y")],
      ["Re-inspection Due", inspection.reinspection_date&.strftime("%d/%m/%Y")],
      ["Inspector", inspection.inspector],
      ["Overall Result", inspection.passed ? "PASS" : "FAIL"]
    ]

    create_pdf_table(pdf, results) do |table|
      table.row(results.length - 1).background_color = inspection.passed ? "CCFFCC" : "FFCCCC"
    end
  end

  def self.generate_inspection_comments(pdf, inspection)
    pdf.move_down 20
    pdf.text "Comments", size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10
    pdf.text inspection.comments
  end

  def self.generate_inspection_qr_code(pdf, inspection)
    pdf.move_down 20
    pdf.text "Certificate Verification", size: 14, style: :bold
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
      pdf.text "Scan to verify certificate or visit:", align: :center, size: 10
      pdf.text "#{ENV["BASE_URL"]}/c/#{inspection.id}",
        align: :center, size: 10, style: :italic
    ensure
      qr_code_temp_file.unlink
    end
  end

  def self.generate_inspection_pdf_footer(pdf)
    pdf.move_down 30
    pdf.text "This certificate was generated on #{Time.now.strftime("%d/%m/%Y at %H:%M")}",
      size: 10, align: :center, style: :italic
    pdf.text "Inspection Logger", size: 10, align: :center, style: :italic
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

  # Equipment certificate methods
  def self.generate_equipment_pdf_header(pdf, equipment)
    pdf.text "Equipment History Report", size: 20, style: :bold, align: :center
    pdf.move_down 20

    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 70) do
      pdf.stroke_bounds
      pdf.move_down 5
      pdf.text "Equipment: #{equipment.name}", align: :center, size: 14, style: :bold
      pdf.move_down 2
      pdf.text "Serial: #{equipment.serial}", align: :center, size: 14
      pdf.move_down 2
      if equipment.last_due_date
        pdf.text "Next Inspection Due: #{equipment.last_due_date.strftime("%d/%m/%Y")}",
          align: :center, size: 14,
          color: (equipment.last_due_date < Date.today) ? "CC0000" : "000000"
      end
    end
    pdf.move_down 20
  end

  def self.generate_equipment_details(pdf, equipment)
    pdf.text "Equipment Details", size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    data = [
      ["Name", equipment.name],
      ["Serial Number", equipment.serial],
      ["Manufacturer", equipment.manufacturer.presence || "Not specified"],
      ["Location", equipment.location]
    ]

    # Add next inspection due if available
    if equipment.last_due_date
      data << ["Next Inspection Due", equipment.last_due_date.strftime("%d/%m/%Y")]
    end

    create_pdf_table(pdf, data)
    pdf.move_down 20
  end

  def self.generate_equipment_inspection_history(pdf, equipment)
    pdf.text "Inspection History", size: 14, style: :bold
    pdf.stroke_horizontal_rule
    pdf.move_down 10

    # Create table headers
    headers = [
      "Date",
      "Inspector",
      "Result",
      "Comments"
    ]

    # Create table data from inspections
    inspections_data = equipment.inspections.order(inspection_date: :desc).map do |inspection|
      [
        inspection.inspection_date&.strftime("%d/%m/%Y") || "N/A",
        inspection.inspector,
        inspection.passed ? "PASS" : "FAIL",
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
    pdf.text "Certificate Verification", size: 14, style: :bold
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
      pdf.text "Scan to view equipment history or visit:", align: :center, size: 10
      pdf.text "#{ENV["BASE_URL"]}/e/#{equipment.id}",
        align: :center, size: 10, style: :italic
    ensure
      qr_code_temp_file.unlink
    end
  end

  def self.generate_equipment_footer(pdf)
    pdf.move_down 30
    pdf.text "This report was generated on #{Time.now.strftime("%d/%m/%Y at %H:%M")}",
      size: 10, align: :center, style: :italic
    pdf.text "Inspection Logger", size: 10, align: :center, style: :italic
  end
end
