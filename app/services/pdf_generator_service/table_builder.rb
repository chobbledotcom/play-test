# frozen_string_literal: true

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

      # Check if it's a 2-column table (unit PDF) or 4-column table (inspection PDF)
      is_unit_pdf = data.first.length == 2

      table = pdf.table(data, width: pdf.bounds.width) do |t|
        t.cells.borders = []
        t.cells.padding = UNIT_TABLE_CELL_PADDING
        t.cells.size = UNIT_TABLE_TEXT_SIZE

        t.columns(0).font_style = :bold
        if is_unit_pdf
          # Simple 2-column layout for unit PDFs
          t.columns(0).width = UNIT_LABEL_COLUMN_WIDTH
        else
          # 4-column layout for inspection PDFs
          # Make label columns (0 and 2) bold
          t.columns(2).font_style = :bold
          # Set column widths - labels just fit content, values take remaining space
          t.columns(0).width = UNIT_LABEL_COLUMN_WIDTH   # Description label
          t.columns(2).width = UNIT_LABEL_COLUMN_WIDTH   # Serial/Type/Owner labels
          remaining_width = pdf.bounds.width - (UNIT_LABEL_COLUMN_WIDTH * 2) # Total minus both label columns
          t.columns(1).width = remaining_width / 2  # Description value
          t.columns(3).width = remaining_width / 2  # Serial/Type/Owner values
        end

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
        I18n.t("pdf.inspection.fields.inspection_location")
      ]

      # Data rows
      inspections.each do |inspection|
        inspector_name = inspection.user.name || I18n.t("pdf.unit.fields.na")
        rpii_number = inspection.user.rpii_inspector_number

        # Combine inspector name with RPII number if present
        inspector_text = if rpii_number.present?
          "#{inspector_name} (#{I18n.t("pdf.inspection.fields.rpii_inspector_no")} #{rpii_number})"
        else
          inspector_name
        end

        table_data << [
          Utilities.format_date(inspection.inspection_date),
          if inspection.passed
            I18n.t("shared.pass_pdf")
          else
            I18n.t("shared.fail_pdf")
          end,
          inspector_text,
          inspection.inspection_location || I18n.t("pdf.unit.fields.na")
        ]
      end

      # Create table with enhanced styling
      table = pdf.table(table_data, width: pdf.bounds.width) do |t|
        t.cells.padding = NICE_TABLE_CELL_PADDING
        t.cells.size = HISTORY_TABLE_TEXT_SIZE
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

          # Color and style the result column (index 1)
          result_cell = t.row(i).column(1)
          if table_data[i][1] == I18n.t("shared.pass_pdf")
            result_cell.text_color = PASS_COLOR
            result_cell.font_style = :bold
          elsif table_data[i][1] == I18n.t("shared.fail_pdf")
            result_cell.text_color = FAIL_COLOR
            result_cell.font_style = :bold
          end
        end

        # Column widths - specific widths for date and result; others fill remaining space
        remaining_width = pdf.bounds.width - HISTORY_DATE_COLUMN_WIDTH - HISTORY_RESULT_COLUMN_WIDTH
        inspector_width = remaining_width * HISTORY_INSPECTOR_WIDTH_PERCENT
        location_width = remaining_width * HISTORY_LOCATION_WIDTH_PERCENT

        t.column_widths = [HISTORY_DATE_COLUMN_WIDTH, HISTORY_RESULT_COLUMN_WIDTH, inspector_width, location_width]
      end

      pdf.move_down 15
      table
    end

    def self.build_unit_details_table(unit, context)
      # Get dimensions from last inspection if available
      last_inspection = unit.last_inspection
      if context == :unit
        build_unit_details_table_for_unit_pdf(unit, last_inspection)
      else
        build_unit_details_table_with_inspection(unit, last_inspection, context)
      end
    end

    def self.build_unit_details_table_for_unit_pdf(unit, last_inspection)
      dimensions = []

      if last_inspection
        if last_inspection.width.present?
          dimensions << "#{I18n.t("pdf.dimensions.width")}: #{Utilities.format_dimension(last_inspection.width)}"
        end
        if last_inspection.length.present?
          dimensions << "#{I18n.t("pdf.dimensions.length")}: #{Utilities.format_dimension(last_inspection.length)}"
        end
        if last_inspection.height.present?
          dimensions << "#{I18n.t("pdf.dimensions.height")}: #{Utilities.format_dimension(last_inspection.height)}"
        end
      end
      dimensions_text = dimensions.any? ? dimensions.join(" ") : ""

      # Build simple two-column table for unit PDFs
      [
        [I18n.t("pdf.inspection.fields.description"),
          Utilities.truncate_text(unit.name || unit.description || "", UNIT_NAME_MAX_LENGTH)],
        [I18n.t("pdf.inspection.fields.manufacturer"), unit.manufacturer.presence || ""],
        [I18n.t("pdf.inspection.fields.owner"), unit.owner.presence || ""],
        [I18n.t("pdf.inspection.fields.serial"), unit.serial || ""],
        [I18n.t("pdf.inspection.fields.size_m"), dimensions_text]
      ]
    end

    def self.build_unit_details_table_with_inspection(unit, last_inspection, context)
      dimensions = []

      if last_inspection
        if last_inspection.width.present?
          dimensions << "#{I18n.t("pdf.dimensions.width")}: #{Utilities.format_dimension(last_inspection.width)}"
        end
        if last_inspection.length.present?
          dimensions << "#{I18n.t("pdf.dimensions.length")}: #{Utilities.format_dimension(last_inspection.length)}"
        end
        if last_inspection.height.present?
          dimensions << "#{I18n.t("pdf.dimensions.height")}: #{Utilities.format_dimension(last_inspection.height)}"
        end
      end
      dimensions_text = dimensions.any? ? dimensions.join(" ") : ""

      # Get inspector details from current inspection (for inspection PDF) or last inspection (for unit PDF)
      inspection = if context == :inspection
        last_inspection
      else
        unit.last_inspection
      end
      inspector_name = inspection&.user&.name || ""
      rpii_number = inspection&.user&.rpii_inspector_number

      # Combine inspector name with RPII number if present
      inspector_text = if rpii_number.present?
        "#{inspector_name} (#{I18n.t("pdf.inspection.fields.rpii_inspector_no")} #{rpii_number})"
      else
        inspector_name
      end

      inspection_location = inspection&.inspection_location || ""
      issued_date = if inspection&.inspection_date
        Utilities.format_date(inspection.inspection_date)
      else
        ""
      end

      # Build the table rows
      [
        [
          I18n.t("pdf.inspection.fields.description"),
          Utilities.truncate_text(unit.name || unit.description || "", UNIT_NAME_MAX_LENGTH),
          I18n.t("pdf.inspection.fields.inspected_by"),
          inspector_text
        ],
        [
          I18n.t("pdf.inspection.fields.manufacturer"),
          unit.manufacturer.presence || "",
          I18n.t("pdf.inspection.fields.owner"),
          unit.owner.presence || ""
        ],
        [
          I18n.t("pdf.inspection.fields.size_m"),
          dimensions_text,
          I18n.t("pdf.inspection.fields.inspection_location"),
          inspection_location
        ],
        [
          I18n.t("pdf.inspection.fields.serial"),
          unit.serial || "",
          I18n.t("pdf.inspection.fields.issued_date"),
          issued_date
        ]
      ]
    end
  end
end
