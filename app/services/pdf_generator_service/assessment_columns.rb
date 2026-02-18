# typed: false

class PdfGeneratorService
  class AssessmentColumns
    # Include configuration for column spacing and font sizes
    include Configuration

    attr_reader :assessment_blocks, :assessment_results_height, :photo_height

    def initialize(assessment_blocks, assessment_results_height, photo_height)
      @assessment_blocks = assessment_blocks
      @assessment_results_height = assessment_results_height
      @photo_height = photo_height
    end

    def render(pdf)
      # Try progressively smaller font sizes
      font_size = Configuration::ASSESSMENT_FIELD_TEXT_SIZE_PREFERRED
      min_font_size = Configuration::MIN_ASSESSMENT_FONT_SIZE

      while font_size >= min_font_size
        if content_fits_with_font_size?(pdf, font_size)
          render_with_font_size(pdf, font_size)
          return true
        end
        font_size -= 1
      end

      # If we still can't fit, render with minimum font size anyway
      render_with_font_size(pdf, min_font_size)
      false
    end

    private

    def content_fits_with_font_size?(pdf, font_size)
      # Calculate total content height
      total_height = calculate_total_content_height(font_size, pdf)

      # Calculate column capacity
      columns = calculate_column_boxes(pdf)
      total_capacity = columns.sum { |col| col[:height] }

      total_height <= total_capacity
    end

    def calculate_total_content_height(font_size, pdf)
      renderer = AssessmentBlockRenderer.new(font_size: font_size)
      total_height = 0

      @assessment_blocks.each do |block|
        # Add height for this block using actual PDF document
        total_height += renderer.height_for(block, pdf)
      end

      total_height
    end

    def render_with_font_size(pdf, font_size)
      # Calculate column dimensions
      columns = calculate_column_boxes(pdf)

      # Save the starting position
      start_y = pdf.cursor

      # Track content placement across columns
      content_blocks = prepare_content_blocks(pdf, font_size)
      place_content_in_columns(pdf, content_blocks, columns, start_y, font_size)

      # Move cursor to end of assessment area
      pdf.move_cursor_to(start_y - assessment_results_height)
    end

    def prepare_content_blocks(pdf, font_size)
      blocks = []
      renderer = AssessmentBlockRenderer.new(font_size: font_size)

      @assessment_blocks.each do |block|
        # Get rendered fragments and height for this block
        fragments = renderer.render_fragments(block)
        height = renderer.height_for(block, pdf)

        blocks << {
          type: block.type,
          fragments: fragments,
          height: height,
          font_size: renderer.font_size_for(block)
        }
      end

      blocks
    end

    def place_content_in_columns(pdf, content_blocks, columns, start_y, font_size)
      current_column = 0
      column_y = start_y

      content_blocks.each do |content|
        # Check if we need to move to next column
        if current_column < columns.size
          available = column_y - (start_y - columns[current_column][:height])

          if available < content[:height]
            # Move to next column
            current_column += 1
            column_y = start_y

            # Stop if we run out of columns
            break if current_column >= columns.size
          end
        else
          break
        end

        # Render content in current column
        column = columns[current_column]
        render_content_at_position(pdf, content, column, column_y, font_size)

        # Update position
        column_y -= content[:height]
      end
    end

    def render_content_at_position(pdf, content, column, y_pos, font_size)
      # Save original state
      original_y = pdf.cursor
      original_fill_color = pdf.fill_color

      # Calculate actual x position
      actual_x = column[:x]

      # Use the font size from the content block if available
      text_size = content[:font_size] || font_size

      formatted_text = AssessmentBlockRenderer
        .fragments_to_formatted_text(content[:fragments])

      # Render as single formatted text box for proper wrapping
      pdf.formatted_text_box(
        formatted_text,
        at: [actual_x, y_pos],
        width: column[:width],
        size: text_size,
        overflow: :truncate
      )

      # Restore original state
      pdf.fill_color original_fill_color
      pdf.move_cursor_to original_y
    end

    def calculate_column_boxes(pdf)
      total_spacer_width = Configuration::ASSESSMENT_COLUMN_SPACER * 3
      column_width = (pdf.bounds.width - total_spacer_width) / 4.0

      columns = []

      # First three columns - full height
      3.times do |i|
        x = i * (column_width + Configuration::ASSESSMENT_COLUMN_SPACER)
        columns << {
          x: x,
          y: pdf.cursor,
          width: column_width,
          height: assessment_results_height
        }
      end

      # Fourth column - reduced by photo height
      fourth_column_height = [assessment_results_height - photo_height - 5, 0].max # 5pt buffer
      columns << {
        x: 3 * (column_width + Configuration::ASSESSMENT_COLUMN_SPACER),
        y: pdf.cursor,
        width: column_width,
        height: fourth_column_height
      }

      columns
    end

    def calculate_line_height(font_size)
      font_size * 1.2
    end
  end
end
