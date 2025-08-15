# typed: false
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

      table = create_styled_unit_table(pdf, data)
      yield table if block_given?
      pdf.move_down 15
      table
    end

    def self.create_styled_unit_table(pdf, data)
      is_unit_pdf = data.first.length == 2

      pdf.table(data, width: pdf.bounds.width) do |t|
        apply_unit_table_base_styling(t, data.length)
        apply_unit_table_column_styling(t, is_unit_pdf, pdf.bounds.width)
      end
    end

    def self.apply_unit_table_base_styling(table, row_count)
      table.cells.borders = []
      table.cells.padding = UNIT_TABLE_CELL_PADDING
      table.cells.size = UNIT_TABLE_TEXT_SIZE

      table.row(0..row_count - 1).background_color = "EEEEEE"
      table.row(0..row_count - 1).borders = [:bottom]
      table.row(0..row_count - 1).border_color = "DDDDDD"
    end

    def self.apply_unit_table_column_styling(table, is_unit_pdf, pdf_width)
      table.columns(0).font_style = :bold

      if is_unit_pdf
        table.columns(0).width = I18n.t("pdf.table.unit_label_column_width_left")
      else
        apply_four_column_styling(table, pdf_width)
      end
    end

    def self.apply_four_column_styling(table, pdf_width)
      table.columns(2).font_style = :bold

      left_width = I18n.t("pdf.table.unit_label_column_width_left")
      right_width = I18n.t("pdf.table.unit_label_column_width_right")

      table.columns(0).width = left_width
      table.columns(2).width = right_width

      remaining_width = pdf_width - (left_width + right_width)
      table.columns(1).width = remaining_width / 2
      table.columns(3).width = remaining_width / 2
    end

    def self.create_inspection_history_table(pdf, title, inspections)
      pdf.text title, size: HEADER_TEXT_SIZE, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      table_data = build_inspection_history_data(inspections)
      table = create_styled_history_table(pdf, table_data)

      pdf.move_down 15
      table
    end

    def self.build_inspection_history_data(inspections)
      header = [
        I18n.t("pdf.unit.fields.date"),
        I18n.t("pdf.unit.fields.result"),
        I18n.t("pdf.unit.fields.inspector")
      ]

      data_rows = inspections.map do |inspection|
        [
          Utilities.format_date(inspection.inspection_date),
          inspection_result_text(inspection),
          inspector_text(inspection)
        ]
      end

      [header] + data_rows
    end

    def self.inspection_result_text(inspection)
      if inspection.passed
        I18n.t("shared.pass_pdf")
      else
        I18n.t("shared.fail_pdf")
      end
    end

    def self.inspector_text(inspection)
      inspector_name = inspection.user.name
      rpii_number = inspection.user.rpii_inspector_number

      if rpii_number.present?
        I18n.t("pdf.unit.fields.inspector_with_rpii",
          name: inspector_name,
          rpii_label: I18n.t("pdf.inspection.fields.rpii_inspector_no"),
          rpii_number: rpii_number)
      else
        inspector_name
      end
    end

    def self.create_styled_history_table(pdf, table_data)
      pdf.table(table_data, width: pdf.bounds.width) do |t|
        apply_history_table_base_styling(t)
        apply_history_table_row_styling(t, table_data)
        apply_history_table_column_widths(t, pdf.bounds.width)
      end
    end

    def self.apply_history_table_base_styling(table)
      table.cells.padding = NICE_TABLE_CELL_PADDING
      table.cells.size = HISTORY_TABLE_TEXT_SIZE
      table.cells.border_width = 0.5
      table.cells.border_color = "CCCCCC"

      table.row(0).background_color = HISTORY_TABLE_HEADER_COLOR
      table.row(0).font_style = :bold
    end

    def self.apply_history_table_row_styling(table, table_data)
      (1...table_data.length).each do |i|
        apply_row_background_color(table, i)
        apply_result_cell_styling(table, i, table_data[i][1])
      end
    end

    def self.apply_row_background_color(table, row_index)
      color = if row_index.odd?
        HISTORY_TABLE_ROW_COLOR
      else
        HISTORY_TABLE_ALT_ROW_COLOR
      end
      table.row(row_index).background_color = color
    end

    def self.apply_result_cell_styling(table, row_index, result_text)
      result_cell = table.row(row_index).column(1)

      if result_text == I18n.t("shared.pass_pdf")
        result_cell.text_color = PASS_COLOR
        result_cell.font_style = :bold
      elsif result_text == I18n.t("shared.fail_pdf")
        result_cell.text_color = FAIL_COLOR
        result_cell.font_style = :bold
      end
    end

    def self.apply_history_table_column_widths(table, pdf_width)
      date_width = HISTORY_DATE_COLUMN_WIDTH
      result_width = HISTORY_RESULT_COLUMN_WIDTH
      inspector_width = pdf_width - date_width - result_width

      table.column_widths = [date_width, result_width, inspector_width]
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
          dimensions << "#{ChobbleForms::FieldUtils.form_field_label(:inspection, :width).sub(" (m)", "")}: #{Utilities.format_dimension(last_inspection.width)}"
        end
        if last_inspection.length.present?
          dimensions << "#{ChobbleForms::FieldUtils.form_field_label(:inspection, :length).sub(" (m)", "")}: #{Utilities.format_dimension(last_inspection.length)}"
        end
        if last_inspection.height.present?
          dimensions << "#{ChobbleForms::FieldUtils.form_field_label(:inspection, :height).sub(" (m)", "")}: #{Utilities.format_dimension(last_inspection.height)}"
        end
      end
      dimensions_text = dimensions.any? ? dimensions.join(" ") : ""

      # Build simple two-column table for unit PDFs
      [
        [ChobbleForms::FieldUtils.form_field_label(:units, :name),
          Utilities.truncate_text(unit.name, UNIT_NAME_MAX_LENGTH)],
        [ChobbleForms::FieldUtils.form_field_label(:units, :manufacturer), unit.manufacturer],
        [ChobbleForms::FieldUtils.form_field_label(:units, :operator), unit.operator],
        [ChobbleForms::FieldUtils.form_field_label(:units, :serial), unit.serial],
        [I18n.t("pdf.inspection.fields.size_m"), dimensions_text]
      ]
    end

    def self.build_unit_details_table_with_inspection(unit, last_inspection, context)
      dimensions = []

      if last_inspection
        if last_inspection.width.present?
          dimensions << "#{ChobbleForms::FieldUtils.form_field_label(:inspection, :width).sub(" (m)", "")}: #{Utilities.format_dimension(last_inspection.width)}"
        end
        if last_inspection.length.present?
          dimensions << "#{ChobbleForms::FieldUtils.form_field_label(:inspection, :length).sub(" (m)", "")}: #{Utilities.format_dimension(last_inspection.length)}"
        end
        if last_inspection.height.present?
          dimensions << "#{ChobbleForms::FieldUtils.form_field_label(:inspection, :height).sub(" (m)", "")}: #{Utilities.format_dimension(last_inspection.height)}"
        end
      end
      dimensions_text = dimensions.any? ? dimensions.join(" ") : ""

      # Get inspector details from current inspection (for inspection PDF) or last inspection (for unit PDF)
      inspection = if context == :inspection
        last_inspection
      else
        unit.last_inspection
      end
      inspector_name = inspection&.user&.name
      rpii_number = inspection&.user&.rpii_inspector_number

      # Combine inspector name with RPII number if present
      inspector_text = if rpii_number.present?
        "#{inspector_name} (#{I18n.t("pdf.inspection.fields.rpii_inspector_no")} #{rpii_number})"
      else
        inspector_name
      end

      issued_date = if inspection&.inspection_date
        Utilities.format_date(inspection.inspection_date)
      end

      # Build the table rows
      [
        [
          ChobbleForms::FieldUtils.form_field_label(:units, :name),
          Utilities.truncate_text(unit.name, UNIT_NAME_MAX_LENGTH),
          I18n.t("pdf.inspection.fields.inspected_by"),
          inspector_text
        ],
        [
          ChobbleForms::FieldUtils.form_field_label(:units, :description),
          unit.description,
          ChobbleForms::FieldUtils.form_field_label(:units, :manufacturer),
          unit.manufacturer
        ],
        [
          I18n.t("pdf.inspection.fields.size_m"),
          dimensions_text,
          ChobbleForms::FieldUtils.form_field_label(:units, :operator),
          unit.operator
        ],
        [
          ChobbleForms::FieldUtils.form_field_label(:units, :serial),
          unit.serial,
          I18n.t("pdf.inspection.fields.issued_date"),
          issued_date
        ]
      ]
    end
  end
end
