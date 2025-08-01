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
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: FOOTER_HEIGHT) do
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

      # Calculate widths
      disclaimer_width = pdf.bounds.width * DISCLAIMER_TEXT_WIDTH_PERCENT
      signature_width = pdf.bounds.width * (1 - DISCLAIMER_TEXT_WIDTH_PERCENT)

      # Both disclaimer and signature should be vertically aligned
      # Calculate the y position for the top of the content area
      content_top_y = pdf.cursor

      # Disclaimer text on the left with fixed height
      pdf.bounding_box([0, content_top_y], width: disclaimer_width, height: DISCLAIMER_TEXT_HEIGHT) do
        pdf.text_box I18n.t("pdf.disclaimer.text"),
          size: DISCLAIMER_TEXT_SIZE,
          inline_format: true,
          valign: :top  # Align to top of the box
      end

      # Signature on the right if user has one
      if user&.signature&.attached?
        # Position signature aligned with disclaimer text area
        render_user_signature(pdf, user, disclaimer_width, signature_width, content_top_y)
      end
    end

    def self.render_disclaimer_header(pdf)
      pdf.text I18n.t("pdf.disclaimer.header"),
        size: DISCLAIMER_HEADER_SIZE,
        style: :bold
      pdf.stroke_horizontal_rule
    end

    def self.render_disclaimer_text(pdf)
      pdf.text I18n.t("pdf.disclaimer.text"),
        size: DISCLAIMER_TEXT_SIZE,
        inline_format: true
    end

    def self.render_user_signature(pdf, user, x_offset, available_width, content_top_y)
      signature_attachment = user.signature

      begin
        # Process signature image
        image = ImageProcessor.create_image(signature_attachment)

        # Calculate dimensions to fit within constraints
        signature_dimensions = calculate_signature_dimensions(image, available_width)
        width, height = signature_dimensions

        # Position signature aligned with disclaimer text
        # x_position is offset from left + remaining space to align right
        x_position = x_offset + available_width - width
        # y_position aligns with the disclaimer text area
        # Since we want them vertically aligned, position from same top y
        y_position = content_top_y

        # Add border around signature
        border_padding = 2
        border_x = x_position - border_padding
        border_y = y_position + border_padding
        border_width = width + (border_padding * 2)
        border_height = height + (border_padding * 2)

        # Draw border
        pdf.stroke_color "CCCCCC"
        pdf.line_width = 1
        pdf.stroke_rectangle [border_x, border_y], border_width, border_height

        # Render the signature
        ImageProcessor.render_processed_image(
          pdf, image, x_position, y_position, width, height, signature_attachment
        )

        # Add caption below signature
        caption_y = y_position - height - 10
        pdf.text_box I18n.t("pdf.signature.caption"),
          at: [border_x, caption_y],
          width: border_width,
          height: 20,
          size: DISCLAIMER_TEXT_SIZE,
          align: :center,
          valign: :top

        # Reset stroke color to default
        pdf.stroke_color "000000"
      rescue => e
        Rails.logger.error "Failed to render signature: #{e.message}"
      end
    end

    def self.calculate_signature_dimensions(image, max_width)
      # Use existing fit_dimensions method from PositionCalculator
      PositionCalculator.fit_dimensions(
        image.width,
        image.height,
        max_width - FOOTER_INTERNAL_PADDING,  # Leave some padding
        SIGNATURE_HEIGHT
      )
    end

    private_class_method :should_render_footer?, :render_footer_content,
      :render_disclaimer_header, :render_disclaimer_text,
      :render_user_signature, :calculate_signature_dimensions
  end
end
