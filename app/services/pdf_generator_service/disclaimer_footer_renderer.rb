class PdfGeneratorService
  class DisclaimerFooterRenderer
    include Configuration

    def self.render_disclaimer_footer(pdf, user)
      return unless should_render_footer?(pdf)

      # Save current position
      original_y = pdf.cursor

      # Move to footer position
      footer_y = FOOTER_HEIGHT
      pdf.move_cursor_to footer_y

      # Create bounding box for footer
      bounding_box_width = pdf.bounds.width
      bounding_box_at = [0, pdf.cursor]
      pdf.bounding_box(bounding_box_at,
        width: bounding_box_width,
        height: FOOTER_HEIGHT) do
        # Add top padding
        pdf.move_down FOOTER_TOP_PADDING
        render_footer_content(pdf, user)
      end

      # Restore position
      pdf.move_cursor_to original_y
    end

    def self.should_render_footer?(pdf)
      # Only render on first page
      pdf.page_number == 1
    end

    def self.render_footer_content(pdf, user)
      # Render disclaimer header
      render_disclaimer_header(pdf)

      pdf.move_down FOOTER_INTERNAL_PADDING

      # Calculate widths based on whether signature exists
      has_signature = user&.signature&.attached?
      bounds_width = pdf.bounds.width
      disclaimer_width = calculate_disclaimer_width(
        has_signature, bounds_width
      )
      signature_width = bounds_width * (1 - DISCLAIMER_TEXT_WIDTH_PERCENT)

      # Both disclaimer and signature should be vertically aligned
      # Calculate the y position for the top of the content area
      content_top_y = pdf.cursor

      # Disclaimer text on the left with fixed height
      render_disclaimer_text_box(pdf, content_top_y, disclaimer_width)

      # Signature on the right if user has one
      if has_signature
        # Position signature aligned with disclaimer text area
        render_user_signature(
          pdf, user, disclaimer_width, signature_width, content_top_y
        )
      end
    end

    def self.render_disclaimer_header(pdf)
      pdf.text I18n.t("pdf.disclaimer.header"),
        size: DISCLAIMER_HEADER_SIZE,
        style: :bold
      pdf.stroke_horizontal_rule
    end

    def self.render_disclaimer_text_box(pdf, y_pos, width)
      pdf.bounding_box([0, y_pos],
        width: width,
        height: DISCLAIMER_TEXT_HEIGHT) do
        pdf.text_box I18n.t("pdf.disclaimer.text"),
          size: DISCLAIMER_TEXT_SIZE,
          inline_format: true,
          valign: :top  # Align to top of the box
      end
    end

    def self.calculate_disclaimer_width(has_signature, bounds_width)
      if has_signature
        bounds_width * DISCLAIMER_TEXT_WIDTH_PERCENT
      else
        bounds_width
      end
    end

    def self.render_user_signature(pdf, user, x_offset, available_width,
      content_top_y)
      signature_attachment = user.signature

      begin
        # Process signature image
        image = ImageProcessor.create_image(signature_attachment)

        # Calculate dimensions to fit within constraints
        dims = calculate_signature_dimensions(image, available_width)
        width, height = dims

        # Add border around signature with more padding
        border_padding = 5

        # Calculate positions
        positions = calculate_signature_positions(
          x_offset, available_width, width, height,
          border_padding, content_top_y
        )

        # Draw border and signature
        draw_signature_border(pdf, positions)
        render_signature_image(
          pdf, image, positions, signature_attachment
        )
        render_signature_caption(pdf, positions)

        # Reset stroke color to default
        pdf.stroke_color "000000"
      rescue => e
        error_msg = "Failed to render signature: #{e.message}"
        Rails.logger.error error_msg
      end
    end

    def self.calculate_signature_dimensions(image, max_width)
      # Use existing fit_dimensions method from PositionCalculator
      # Account for border padding (5px on each side = 10px total)
      border_total_padding = 10
      max_available = max_width - FOOTER_INTERNAL_PADDING - border_total_padding
      PositionCalculator.fit_dimensions(
        image.width,
        image.height,
        max_available,  # Leave padding for border
        SIGNATURE_HEIGHT
      )
    end

    def self.calculate_signature_positions(x_offset, available_width, width,
      height, border_padding, content_top_y)
      # Position signature aligned with disclaimer text
      # Shift left to account for border and padding
      border_width_total = border_padding * 2
      x_position = x_offset + available_width - width - border_width_total
      # y_position aligns with the disclaimer text area
      y_position = content_top_y

      # Calculate border position
      border_x = x_position
      border_y = y_position + border_padding
      border_width = width + border_width_total
      border_height = height + border_width_total

      # Adjust signature position to be inside the border
      sig_x = x_position + border_padding

      {
        x_position: sig_x,
        y_position: y_position,
        border_x: border_x,
        border_y: border_y,
        border_width: border_width,
        border_height: border_height,
        width: width,
        height: height,
        border_padding: border_padding
      }
    end

    def self.draw_signature_border(pdf, positions)
      pdf.stroke_color "CCCCCC"
      pdf.line_width = 1
      border_rect = [
        positions[:border_x],
        positions[:border_y]
      ]
      pdf.stroke_rectangle border_rect,
        positions[:border_width],
        positions[:border_height]
    end

    def self.render_signature_image(pdf, image, positions,
      signature_attachment)
      ImageProcessor.render_processed_image(
        pdf, image,
        positions[:x_position],
        positions[:y_position],
        positions[:width],
        positions[:height],
        signature_attachment
      )
    end

    def self.render_signature_caption(pdf, positions)
      caption_y = positions[:y_position] - positions[:height] -
        positions[:border_padding] - 4
      pdf.text_box I18n.t("pdf.signature.caption"),
        at: [positions[:border_x], caption_y],
        width: positions[:border_width],
        height: 20,
        size: DISCLAIMER_TEXT_SIZE,
        align: :center,
        valign: :top
    end

    private_class_method :should_render_footer?, :render_footer_content,
      :render_disclaimer_header, :render_disclaimer_text_box,
      :calculate_disclaimer_width,
      :render_user_signature, :calculate_signature_dimensions,
      :calculate_signature_positions, :draw_signature_border,
      :render_signature_image, :render_signature_caption
  end
end
