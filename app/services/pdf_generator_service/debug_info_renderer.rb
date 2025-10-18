# typed: false

class PdfGeneratorService
  class DebugInfoRenderer
    include Configuration

    def self.add_debug_info_page(pdf, queries)
      return if queries.blank?

      # Start a new page for debug info
      pdf.start_new_page

      # Header
      pdf.text I18n.t("debug.title"), size: HEADER_TEXT_SIZE, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      # Summary info
      total_rows = queries.sum { |q| q[:row_count] || 0 }
      pdf.text "#{I18n.t("debug.query_count")}: #{queries.size}", size: NICE_TABLE_TEXT_SIZE
      pdf.text "#{I18n.t("debug.total_rows")}: #{total_rows}", size: NICE_TABLE_TEXT_SIZE
      pdf.move_down 10

      # Build table data
      table_data = [
        [I18n.t("debug.query"), I18n.t("debug.duration"), I18n.t("debug.rows"), I18n.t("debug.name")]
      ]

      queries.each do |query|
        table_data << [
          query[:sql],
          "#{query[:duration]} ms",
          query[:row_count] || 0,
          query[:name] || ""
        ]
      end

      # Create the table
      pdf.table(table_data, width: pdf.bounds.width) do |t|
        # Header row styling
        t.row(0).background_color = "333333"
        t.row(0).text_color = "FFFFFF"
        t.row(0).font_style = :bold

        # General styling
        t.cells.borders = [:bottom]
        t.cells.border_color = "DDDDDD"
        t.cells.padding = TABLE_CELL_PADDING
        t.cells.size = 8

        # Column widths
        t.columns(0).width = pdf.bounds.width * 0.5  # Query column gets most space
        t.columns(1).width = pdf.bounds.width * 0.15  # Duration
        t.columns(2).width = pdf.bounds.width * 0.1  # Rows
        t.columns(3).width = pdf.bounds.width * 0.25  # Name

        # Alternating row colors
        (1..table_data.length - 1).each do |i|
          t.row(i).background_color = i.odd? ? "FFFFFF" : "F5F5F5"
        end
      end
    end
  end
end
