class PdfGeneratorService
  class AssessmentColumns
    # Include configuration for column spacing and font sizes
    include Configuration

    # Define assessment layout constants (matching AssessmentRenderer)
    ASSESSMENT_MARGIN_AFTER_TITLE = 3
    ASSESSMENT_MARGIN_AFTER = 16
    ASSESSMENT_TITLE_SIZE = 9

    attr_reader :assessment_blocks, :assessment_results_height, :photo_height

    def initialize(assessment_blocks, assessment_results_height, photo_height = 0)
      @assessment_blocks = assessment_blocks
      @assessment_results_height = assessment_results_height
      @photo_height = photo_height
    end

    def render(pdf)
      # Try progressively smaller font sizes
      font_size = Configuration::ASSESSMENT_FIELD_TEXT_SIZE_PREFERRED
      min_font_size = Configuration::MIN_ASSESSMENT_FONT_SIZE

      Rails.logger.debug "=== AssessmentColumns Debug ===" if !Rails.env.production?
      Rails.logger.debug { "Assessment blocks count: #{assessment_blocks.size}" } if !Rails.env.production?
      Rails.logger.debug { "Assessment results height: #{assessment_results_height}" } if !Rails.env.production?
      Rails.logger.debug { "Photo height: #{photo_height}" } if !Rails.env.production?

      while font_size >= min_font_size
        Rails.logger.debug { "Trying font size: #{font_size}" } if !Rails.env.production?
        if content_fits_with_font_size?(pdf, font_size)
          Rails.logger.debug { "Success! Font size #{font_size} fits" } if !Rails.env.production?
          render_with_font_size(pdf, font_size)
          return true
        end
        font_size -= 1
      end

      # If we still can't fit, render with minimum font size anyway
      Rails.logger.debug { "Could not fit with any font size, using minimum: #{min_font_size}" } if !Rails.env.production?
      render_with_font_size(pdf, min_font_size)
      false
    end

    private

    def content_fits_with_font_size?(pdf, font_size)
      # Calculate total content height
      total_height = calculate_total_content_height(font_size)

      # Calculate column capacity
      columns = calculate_column_boxes(pdf)
      total_capacity = columns.sum { |col| col[:height] }

      total_height <= total_capacity
    end

    def calculate_total_content_height(font_size)
      total_height = 0
      line_height = calculate_line_height(font_size)
      title_line_height = calculate_line_height(ASSESSMENT_TITLE_SIZE)

      @assessment_blocks.each do |block|
        # Title height
        total_height += title_line_height + ASSESSMENT_MARGIN_AFTER_TITLE

        # Fields height
        total_height += block[:fields].size * line_height

        # Block margin
        total_height += ASSESSMENT_MARGIN_AFTER
      end

      total_height
    end

    def render_with_font_size(pdf, font_size)
      # Calculate column dimensions
      columns = calculate_column_boxes(pdf)

      # Save the starting position
      start_y = pdf.cursor

      # Track content placement across columns
      content_blocks = prepare_content_blocks(font_size)
      place_content_in_columns(pdf, content_blocks, columns, start_y, font_size)

      # Move cursor to end of assessment area
      pdf.move_cursor_to(start_y - assessment_results_height)
    end

    def prepare_content_blocks(font_size)
      blocks = []

      @assessment_blocks.each do |block|
        # Add title
        blocks << {
          type: :title,
          text: block[:title],
          height: calculate_line_height(ASSESSMENT_TITLE_SIZE) + ASSESSMENT_MARGIN_AFTER_TITLE
        }

        # Add fields
        block[:fields].each do |field|
          blocks << {
            type: :field,
            text: field,
            height: calculate_line_height(font_size)
          }
        end

        # Add margin after block
        blocks << {
          type: :margin,
          height: ASSESSMENT_MARGIN_AFTER
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
        if content[:type] != :margin
          column = columns[current_column]
          render_content_at_position(pdf, content, column, column_y, font_size)
        end

        # Update position
        column_y -= content[:height]
      end
    end

    def render_content_at_position(pdf, content, column, y_pos, font_size)
      # Save original state
      original_y = pdf.cursor
      pdf.bounds.width
      pdf.bounds.left

      # Move to position and render
      pdf.move_cursor_to y_pos

      # Calculate actual x position
      actual_x = column[:x]

      # Use a formatted text box to position content precisely
      if content[:type] == :title
        pdf.formatted_text_box(
          [{text: content[:text], styles: [:bold]}],
          at: [actual_x, y_pos],
          width: column[:width],
          size: ASSESSMENT_TITLE_SIZE
        )
      else
        # Parse inline formatting for fields
        pdf.formatted_text_box(
          parse_inline_formatting(content[:text]),
          at: [actual_x, y_pos],
          width: column[:width],
          size: font_size
        )
      end

      # Restore cursor
      pdf.move_cursor_to original_y
    end

    def parse_inline_formatting(text)
      # Simple parser for Prawn inline formatting
      # This handles basic HTML-like tags that Prawn understands
      if text.include?("<")
        # For now, just strip tags and return plain text
        # In a real implementation, you'd parse the tags properly
        [{text: text.gsub(/<[^>]+>/, "")}]
      else
        [{text: text}]
      end
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

      if !Rails.env.production?
        Rails.logger.debug "=== Column Layout Debug ==="
        Rails.logger.debug { "Column width: #{column_width}" }
        Rails.logger.debug { "Columns 1-3 height: #{assessment_results_height}" }
        Rails.logger.debug { "Column 4 height: #{fourth_column_height}" }
        Rails.logger.debug { "Photo height impact: #{photo_height}" }
      end

      columns
    end

    def calculate_line_height(font_size)
      font_size * 1.2
    end
  end
end
