# typed: false

class PdfGeneratorService
  class DebugInfoRenderer
    include Configuration

    def self.add_debug_info_page(pdf, queries)
      return if queries.blank?

      pdf.start_new_page
      render_debug_header(pdf)
      render_debug_summary(pdf, queries)
      render_debug_table(pdf, queries)
    end

    def self.render_debug_header(pdf)
      pdf.text I18n.t("debug.title"), size: HEADER_TEXT_SIZE, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 10
    end

    def self.render_debug_summary(pdf, queries)
      total_rows = queries.sum { |q| q[:row_count] || 0 }
      pdf.text "#{I18n.t("debug.query_count")}: #{queries.size}", size: NICE_TABLE_TEXT_SIZE
      pdf.text "#{I18n.t("debug.total_rows")}: #{total_rows}", size: NICE_TABLE_TEXT_SIZE
      pdf.move_down 10
    end

    def self.render_debug_table(pdf, queries)
      table_data = build_debug_table_data(queries)
      pdf.table(table_data, width: pdf.bounds.width) { |t| style_debug_table(t, table_data) }
    end

    def self.build_debug_table_data(queries)
      header = [I18n.t("debug.query"), I18n.t("debug.duration"), I18n.t("debug.rows"), I18n.t("debug.name")]
      rows = queries.map { |q| [q[:sql], "#{q[:duration]} ms", q[:row_count] || 0, q[:name] || ""] }
      [header] + rows
    end

    def self.style_debug_table(table, table_data)
      style_debug_table_header(table)
      style_debug_table_cells(table)
      apply_debug_column_widths(table)
      apply_debug_row_colors(table, table_data.length)
    end

    def self.style_debug_table_header(table)
      table.row(0).background_color = "333333"
      table.row(0).text_color = "FFFFFF"
      table.row(0).font_style = :bold
    end

    def self.style_debug_table_cells(table)
      table.cells.borders = [:bottom]
      table.cells.border_color = "DDDDDD"
      table.cells.padding = TABLE_CELL_PADDING
      table.cells.size = 8
    end

    def self.apply_debug_column_widths(table)
      pdf_width = table.cells.column(0).first.parent.width
      table.columns(0).width = pdf_width * 0.5
      table.columns(1).width = pdf_width * 0.15
      table.columns(2).width = pdf_width * 0.1
      table.columns(3).width = pdf_width * 0.25
    end

    def self.apply_debug_row_colors(table, row_count)
      (1..row_count - 1).each do |i|
        table.row(i).background_color = i.odd? ? "FFFFFF" : "F5F5F5"
      end
    end
  end
end
