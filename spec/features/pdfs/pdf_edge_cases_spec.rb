require "rails_helper"

RSpec.feature "PDF Edge Cases and Stress Testing", type: :feature do
  let(:inspection) { create(:inspection, :completed) }
  let(:user) { inspection.user }
  let(:unit) { inspection.unit }

  before do
    sign_in(user)
  end

  feature "Large data sets and performance" do
    scenario "handles inspection with all assessment types and maximum data" do
      full_unit = create(:unit, :with_all_fields, user: user)

      full_inspection = create(:inspection, :completed, user: user, unit: full_unit)

      long_comment = "Detailed assessment comment " * 50
      full_inspection.user_height_assessment.update(
        containing_wall_height_comment: long_comment,
        platform_height_comment: long_comment,
        tallest_user_height_comment: long_comment
      )

      start_time = Time.current
      pdf_text = test_pdf_content(inspection_path(full_inspection, format: :pdf))
      generation_time = Time.current - start_time

      expect(generation_time).to be < 10.seconds  # Should generate within 10 seconds

      %w[User\ Height Slide Structure Anchorage Materials Fan/Blower Totally\ Enclosed].each do |section|
        expect(pdf_text).to include(section)
      end
    end

    scenario "logs PDF generation time for complete inspection with photo" do
      # Create unit with photo
      unit_with_photo = create(:unit, user: user)
      unit_with_photo.photo.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
        filename: "test_image.jpg",
        content_type: "image/jpeg"
      )
      
      # Create complete inspection with all assessments filled
      complete_inspection = create(:inspection, :completed, user: user, unit: unit_with_photo)
      
      # Add some comments to make it more realistic
      complete_inspection.user_height_assessment.update(
        containing_wall_height_comment: "Wall height measured from ground level",
        platform_height_comment: "Platform stable and level"
      )
      complete_inspection.slide_assessment.update(
        slide_platform_height_comment: "Platform height measured accurately",
        runout_comment: "Runout area clear and sufficient"
      )
      
      # Measure PDF generation time
      start_time = Time.current
      
      # Generate PDF
      pdf_data = get_pdf(inspection_path(complete_inspection, format: :pdf))
      
      generation_time = Time.current - start_time
      
      # Log the generation time
      Rails.logger.info "=" * 60
      Rails.logger.info "PDF GENERATION PERFORMANCE TEST"
      Rails.logger.info "=" * 60
      Rails.logger.info "Inspection ID: #{complete_inspection.id}"
      Rails.logger.info "Unit has photo: #{unit_with_photo.photo.attached?}"
      Rails.logger.info "Photo size: #{unit_with_photo.photo.blob.byte_size} bytes" if unit_with_photo.photo.attached?
      Rails.logger.info "PDF size: #{pdf_data.bytesize} bytes (#{(pdf_data.bytesize / 1024.0).round(2)} KB)"
      Rails.logger.info "Generation time: #{(generation_time * 1000).round(2)} ms"
      Rails.logger.info "=" * 60
      
      # Also output to console for visibility during test runs
      puts "\n" + "=" * 60
      puts "PDF GENERATION PERFORMANCE TEST"
      puts "=" * 60
      puts "Inspection ID: #{complete_inspection.id}"
      puts "Unit has photo: #{unit_with_photo.photo.attached?}"
      puts "Photo size: #{unit_with_photo.photo.blob.byte_size} bytes" if unit_with_photo.photo.attached?
      puts "PDF size: #{pdf_data.bytesize} bytes (#{(pdf_data.bytesize / 1024.0).round(2)} KB)"
      puts "Generation time: #{(generation_time * 1000).round(2)} ms"
      puts "=" * 60 + "\n"
      
      # Verify PDF is valid
      expect_valid_pdf(pdf_data)
      
      # Performance expectations
      expect(generation_time).to be < 5.seconds  # Should be faster than 5 seconds
      expect(pdf_data.bytesize).to be < 5.megabytes  # Should be under 5MB even with photo
    end

    scenario "generates PDFs with reasonable file sizes" do
      pdf_data = get_pdf(inspection_path(inspection, format: :pdf))
      pdf_size = pdf_data.bytesize

      expect(pdf_size).to be < 2.megabytes  # Should be under 2MB for basic inspection
      expect(pdf_size).to be > 1.kilobyte   # Should have substantial content
    end
  end


  feature "Memory and resource management" do
    scenario "cleans up temporary files during PDF generation" do
      process_pattern = "/tmp/*qr_code*#{inspection.id}_#{Process.pid}*"

      10.times do
        temp_files_before = Dir.glob(process_pattern).size
        get_pdf(inspection_path(inspection, format: :pdf))

        sleep(0.01)

        temp_files_after = Dir.glob(process_pattern).size
        expect(temp_files_after).to eq(temp_files_before)
      end
    end
  end

end
