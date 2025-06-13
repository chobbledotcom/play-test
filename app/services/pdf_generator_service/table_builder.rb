class PdfGeneratorService
  class TableBuilder
    include Configuration

    def self.create_pdf_table(pdf, data)
      table = pdf.table(data, width: pdf.bounds.width) do |t|
        t.cells.borders = []
        t.cells.padding = TABLE_CELL_PADDING
        t.columns(0).font_style = :bold
        t.columns(0).width = TABLE_FIRST_COLUMN_WIDTH
        t.row(0..data.length - 1).background_color = "EEEEEE"
        t.row(0..data.length - 1).borders = [:bottom]
        t.row(0..data.length - 1).border_color = "DDDDDD"
      end

      yield table if block_given?
      table
    end

    def self.create_nice_box_table(pdf, title, data)
      pdf.text title, size: HEADER_TEXT_SIZE, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      table = pdf.table(data, width: pdf.bounds.width) do |t|
        t.cells.borders = []
        t.cells.padding = NICE_TABLE_CELL_PADDING
        t.cells.size = NICE_TABLE_TEXT_SIZE
        t.columns(0).font_style = :bold
        t.columns(0).width = TABLE_FIRST_COLUMN_WIDTH
        t.row(0..data.length - 1).background_color = "EEEEEE"
        t.row(0..data.length - 1).borders = [:bottom]
        t.row(0..data.length - 1).border_color = "DDDDDD"
      end

      yield table if block_given?
      pdf.move_down 15
      table
    end

    def self.create_unit_details_table(pdf, title, data)
      pdf.text title, size: HEADER_TEXT_SIZE, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      table = pdf.table(data, width: pdf.bounds.width) do |t|
        t.cells.borders = []
        t.cells.padding = UNIT_TABLE_CELL_PADDING
        t.cells.size = UNIT_TABLE_TEXT_SIZE
        # Make label columns (0 and 2) bold
        t.columns(0).font_style = :bold
        t.columns(2).font_style = :bold
        # Set column widths - labels just fit content, values take remaining space
        t.columns(0).width = UNIT_LABEL_COLUMN_WIDTH   # Description label
        t.columns(2).width = UNIT_LABEL_COLUMN_WIDTH   # Serial/Type/Owner labels
        remaining_width = pdf.bounds.width - (UNIT_LABEL_COLUMN_WIDTH * 2)  # Total minus both label columns
        t.columns(1).width = remaining_width / 2  # Description value
        t.columns(3).width = remaining_width / 2  # Serial/Type/Owner values
        t.row(0..data.length - 1).background_color = "EEEEEE"
        t.row(0..data.length - 1).borders = [:bottom]
        t.row(0..data.length - 1).border_color = "DDDDDD"
      end

      yield table if block_given?
      pdf.move_down 15
      table
    end

    def self.create_inspection_history_table(pdf, title, inspections)
      pdf.text title, size: HEADER_TEXT_SIZE, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      # Prepare table data with header row
      table_data = []

      # Header row
      table_data << [
        I18n.t("pdf.unit.fields.date"),
        I18n.t("pdf.unit.fields.result"),
        I18n.t("pdf.unit.fields.inspector"),
        I18n.t("pdf.inspection.fields.rpii_inspector_no"),
        I18n.t("pdf.inspection.fields.inspection_location")
      ]

      # Data rows
      inspections.each do |inspection|
        table_data << [
          inspection.inspection_date&.strftime("%d/%m/%Y") || I18n.t("pdf.unit.fields.na"),
          inspection.passed ? I18n.t("shared.pass") : I18n.t("shared.fail"),
          inspection.user.name || I18n.t("pdf.unit.fields.na"),
          inspection.user.rpii_inspector_number || I18n.t("pdf.unit.fields.na"),
          inspection.inspection_location || I18n.t("pdf.unit.fields.na")
        ]
      end

      # Create table with enhanced styling
      table = pdf.table(table_data, width: pdf.bounds.width) do |t|
        t.cells.padding = NICE_TABLE_CELL_PADDING
        t.cells.size = NICE_TABLE_TEXT_SIZE
        t.cells.border_width = 0.5
        t.cells.border_color = "CCCCCC"

        # Header row styling
        t.row(0).background_color = HISTORY_TABLE_HEADER_COLOR
        t.row(0).font_style = :bold

        # Alternating row colors for data rows (skip header row)
        (1...table_data.length).each do |i|
          t.row(i).background_color = if i.odd?
            HISTORY_TABLE_ROW_COLOR
          else
            HISTORY_TABLE_ALT_ROW_COLOR
          end
        end

        # Color and style the result column (index 1)
        (1...table_data.length).each do |i|
          result_cell = t.row(i).column(1)
          if table_data[i][1] == I18n.t("shared.pass")
            result_cell.text_color = PASS_COLOR
            result_cell.font_style = :bold
          elsif table_data[i][1] == I18n.t("shared.fail")
            result_cell.text_color = FAIL_COLOR
            result_cell.font_style = :bold
          end
        end

        # Column widths - specific widths for date, result, RPII number; others fill remaining space
        remaining_width = pdf.bounds.width - HISTORY_DATE_COLUMN_WIDTH - HISTORY_RESULT_COLUMN_WIDTH - HISTORY_RPII_COLUMN_WIDTH
        inspector_width = remaining_width * HISTORY_INSPECTOR_WIDTH_PERCENT
        location_width = remaining_width * HISTORY_LOCATION_WIDTH_PERCENT

        t.column_widths = [HISTORY_DATE_COLUMN_WIDTH, HISTORY_RESULT_COLUMN_WIDTH, inspector_width, HISTORY_RPII_COLUMN_WIDTH, location_width]
      end

      pdf.move_down 15
      table
    end

    def self.build_unit_details_table(unit, context)
      # Get dimensions from last inspection if available
      last_inspection = unit.last_inspection
      dimensions = []

      if last_inspection
        dimensions << "#{I18n.t("pdf.dimensions.width")}: #{Utilities.format_dimension(last_inspection.width)}" if last_inspection.width.present?
        dimensions << "#{I18n.t("pdf.dimensions.length")}: #{Utilities.format_dimension(last_inspection.length)}" if last_inspection.length.present?
        dimensions << "#{I18n.t("pdf.dimensions.height")}: #{Utilities.format_dimension(last_inspection.height)}" if last_inspection.height.present?
      end
      dimensions_text = dimensions.any? ? dimensions.join(" ") : ""

      # Unit Type / Has Slide - use last inspection data if available
      unit_type = if last_inspection
        last_inspection.has_slide? ? I18n.t("pdf.inspection.fields.unit_with_slide") : I18n.t("pdf.inspection.fields.standard_unit")
      else
        I18n.t("pdf.inspection.fields.standard_unit")
      end

      # Use the same format for both inspection and unit PDFs (the inspection format is better)
      [
        [
          I18n.t("pdf.inspection.fields.description"),
          Utilities.truncate_text(unit.name || unit.description || "", UNIT_NAME_MAX_LENGTH),
          I18n.t("pdf.inspection.fields.serial"),
          unit.serial || ""
        ],
        [
          I18n.t("pdf.inspection.fields.manufacturer"),
          unit.manufacturer.presence || "",
          I18n.t("pdf.inspection.fields.type"),
          unit_type
        ],
        [
          I18n.t("pdf.inspection.fields.size_m"),
          dimensions_text,
          I18n.t("pdf.inspection.fields.owner"),
          unit.owner.presence || ""
        ]
      ]
    end
  end
end
