class PdfGeneratorService
  class PhotosRenderer
    include Configuration

    def self.generate_photos_page(pdf, inspection)
      return unless has_photos?(inspection)

      # Start a new page for photos
      pdf.start_new_page

      # Add photos header
      pdf.text I18n.t("pdf.inspection.photos_section"), size: HEADER_TEXT_SIZE, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 15

      # Calculate maximum photo height (25% of page)
      max_photo_height = pdf.bounds.height * PHOTO_MAX_HEIGHT_PERCENT

      # Current Y position for placing photos
      current_y = pdf.cursor

      # Process each photo
      [
        [:photo_1, I18n.t("pdf.inspection.fields.photo_1_label")],
        [:photo_2, I18n.t("pdf.inspection.fields.photo_2_label")],
        [:photo_3, I18n.t("pdf.inspection.fields.photo_3_label")]
      ].each do |photo_field, label|
        photo = inspection.send(photo_field)
        next unless photo.attached?

        # Check if we have enough space, otherwise start new page
        needed_space = max_photo_height + PHOTO_LABEL_SIZE + PHOTO_LABEL_SPACING + PHOTO_SPACING
        if current_y < needed_space
          pdf.start_new_page
          current_y = pdf.cursor
        end

        # Process and render the photo
        begin
          render_photo(pdf, photo, label, max_photo_height)
          current_y = pdf.cursor - PHOTO_SPACING
          pdf.move_down PHOTO_SPACING
        rescue => e
          Rails.logger.error "Error rendering photo #{photo_field}: #{e.message}"
          # Continue with next photo if one fails
        end
      end
    end

    private

    def self.has_photos?(inspection)
      inspection.photo_1.attached? || inspection.photo_2.attached? || inspection.photo_3.attached?
    end

    def self.render_photo(pdf, photo, label, max_height)
      # Download and process the image
      photo.blob.download
      processed_image = ImageProcessor.process_image_with_orientation(photo)

      # Create temporary file for the processed image
      temp_file = Tempfile.new(["pdf_photo_#{photo.id}_#{Process.pid}", ".jpg"])
      begin
        temp_file.binmode
        temp_file.write(processed_image)
        temp_file.close

        # Calculate image dimensions maintaining aspect ratio
        image_width, image_height = calculate_photo_dimensions(temp_file.path, pdf.bounds.width, max_height)

        # Center the image horizontally
        x_position = (pdf.bounds.width - image_width) / 2

        # Render the image
        pdf.image temp_file.path, at: [x_position, pdf.cursor], width: image_width, height: image_height

        # Move cursor down by image height
        pdf.move_down image_height + PHOTO_LABEL_SPACING

        # Add centered label below the photo
        pdf.text label, size: PHOTO_LABEL_SIZE, align: :center
      ensure
        temp_file.close unless temp_file.closed?
        temp_file.unlink if File.exist?(temp_file.path)
      end
    end

    def self.calculate_photo_dimensions(image_path, max_width, max_height)
      # Use ImageMagick to get image dimensions
      image = MiniMagick::Image.open(image_path)
      original_width = image.width.to_f
      original_height = image.height.to_f

      # Calculate scale factors for both width and height constraints
      width_scale = max_width / original_width
      height_scale = max_height / original_height

      # Use the smaller scale factor to ensure image fits within both constraints
      scale = [width_scale, height_scale].min

      # Calculate final dimensions
      final_width = original_width * scale
      final_height = original_height * scale

      [final_width, final_height]
    end
  end
end
