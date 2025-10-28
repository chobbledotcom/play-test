# typed: false

class PdfGeneratorService
  class PhotosRenderer
    def self.generate_photos_page(pdf, inspection)
      return unless has_photos?(inspection)

      pdf.start_new_page
      add_photos_header(pdf)

      max_photo_height = calculate_max_photo_height(pdf)
      process_all_photos(pdf, inspection, max_photo_height)
    end

    def self.has_photos?(inspection)
      inspection.photo_1.attached? ||
        inspection.photo_2.attached? ||
        inspection.photo_3.attached?
    end

    def self.add_photos_header(pdf)
      header_options = {
        size: Configuration::HEADER_TEXT_SIZE,
        style: :bold
      }
      pdf.text I18n.t("pdf.inspection.photos_section"), header_options
      pdf.stroke_horizontal_rule
      pdf.move_down 15
    end

    def self.calculate_max_photo_height(pdf)
      height_percent = Configuration::PHOTO_MAX_HEIGHT_PERCENT
      pdf.bounds.height * height_percent
    end

    def self.process_all_photos(pdf, inspection, max_photo_height)
      current_y = pdf.cursor

      photo_fields.each do |photo_field, label|
        photo = inspection.send(photo_field)
        next unless photo.attached?

        current_y = handle_page_break_if_needed(
          pdf, current_y, max_photo_height
        )

        render_photo(pdf, photo, label, max_photo_height)
        current_y = pdf.cursor - Configuration::PHOTO_SPACING
        pdf.move_down Configuration::PHOTO_SPACING
      end
    end

    def self.photo_fields
      [
        [:photo_1, I18n.t("pdf.inspection.fields.photo_1_label")],
        [:photo_2, I18n.t("pdf.inspection.fields.photo_2_label")],
        [:photo_3, I18n.t("pdf.inspection.fields.photo_3_label")]
      ]
    end

    def self.handle_page_break_if_needed(pdf, current_y, max_photo_height)
      needed_space = calculate_needed_space(max_photo_height)

      if current_y < needed_space
        pdf.start_new_page
        pdf.cursor
      else
        current_y
      end
    end

    def self.calculate_needed_space(max_photo_height)
      label_size = Configuration::PHOTO_LABEL_SIZE
      label_spacing = Configuration::PHOTO_LABEL_SPACING
      photo_spacing = Configuration::PHOTO_SPACING
      max_photo_height + label_size + label_spacing + photo_spacing
    end

    def self.render_photo(pdf, photo, label, max_height)
      photo.blob.download
      processed_image = ImageProcessor.process_image_with_orientation(photo)

      image_width, image_height = calculate_photo_dimensions_from_blob(
        photo, pdf.bounds.width, max_height
      )
      x_position = (pdf.bounds.width - image_width) / 2

      render_image_to_pdf(
        pdf, processed_image, x_position, image_width, image_height, photo
      )

      add_photo_label(pdf, label, image_height)
    rescue Prawn::Errors::UnsupportedImageType => e
      raise ImageError.build_detailed_error(e, photo)
    end

    def self.calculate_photo_dimensions_from_blob(photo, max_width, max_height)
      original_width = photo.blob.metadata[:width].to_f
      original_height = photo.blob.metadata[:height].to_f

      width_scale = max_width / original_width
      height_scale = max_height / original_height
      scale = [width_scale, height_scale].min

      [original_width * scale, original_height * scale]
    end

    def self.render_image_to_pdf(pdf, image_data, x_position, width, height,
      photo)
      image_options = {
        at: [x_position, pdf.cursor],
        width: width,
        height: height
      }
      pdf.image StringIO.new(image_data), image_options
    rescue Prawn::Errors::UnsupportedImageType => e
      raise ImageError.build_detailed_error(e, photo)
    end

    def self.add_photo_label(pdf, label, image_height)
      pdf.move_down image_height + Configuration::PHOTO_LABEL_SPACING
      label_options = {
        size: Configuration::PHOTO_LABEL_SIZE,
        align: :center
      }
      pdf.text label, label_options
    end
  end
end
