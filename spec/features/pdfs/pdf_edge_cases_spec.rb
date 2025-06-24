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
      unit_with_photo = create(:unit, user: user)
      unit_with_photo.photo.attach(
        io: Rails.root.join("spec/fixtures/files/test_image.jpg").open,
        filename: "test_image.jpg",
        content_type: "image/jpeg"
      )

      complete_inspection = create(
        :inspection,
        :completed,
        user: user,
        unit: unit_with_photo
      )

      complete_inspection.user_height_assessment.update(
        containing_wall_height_comment: "Wall height measured from ground level",
        platform_height_comment: "Platform stable and level"
      )
      complete_inspection.slide_assessment.update(
        slide_platform_height_comment: "Platform height measured accurately",
        runout_comment: "Runout area clear and sufficient"
      )

      start_time = Time.current

      pdf_data = get_pdf(inspection_path(complete_inspection, format: :pdf))

      generation_time = Time.current - start_time

      expect_valid_pdf(pdf_data)
      expect(generation_time).to be < 2.seconds
      expect(pdf_data.bytesize).to be < 1.megabytes
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
