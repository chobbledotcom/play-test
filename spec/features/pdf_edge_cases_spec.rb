require "rails_helper"
require "pdf/inspector"

RSpec.feature "PDF Edge Cases and Stress Testing", type: :feature do
  let(:inspection) { create_completed_inspection }
  let(:user) { inspection.user }
  let(:unit) { inspection.unit }

  before do
    sign_in(user)
  end

  feature "Extreme text handling" do
    scenario "handles 5000+ character text fields" do
      extremely_long_text = "Lorem ipsum " * 500  # ~5500 characters

      inspection.update(
        inspection_location: "Location: #{extremely_long_text}"
      )

      pdf_data = get_pdf(inspection_path(inspection, format: :pdf))
      expect_valid_pdf(pdf_data)
    end

    scenario "handles mixed Unicode, emoji, and special characters" do
      mixed_content = "测试 🎈 Ñoël Zürich ¡Hola! 数学 symbols: ∑∆π€£¥ emojis: 🏭🔧⚡🎯"

      inspection.update(
        inspection_location: mixed_content
      )

      pdf_text = get_pdf_text(inspection_path(inspection, format: :pdf))
      expect(pdf_text).to be_present
      expect(pdf_text.encoding.name).to eq("UTF-8")
    end

    scenario "handles malformed or potentially dangerous text" do
      dangerous_content = [
        "'; DROP TABLE inspections; --",
        "\x00\x01\x02null bytes",
        "\\n\\r\\t escape sequences",
        "\u202E\u202D bidirectional overrides",
        "Normal text with \u0000 null in middle"
      ]

      dangerous_content.each do |content|
        inspection.update(risk_assessment: content)
        get_pdf(inspection_path(inspection, format: :pdf))
      end
    end
  end

  feature "Numeric precision and edge values" do
    scenario "handles extreme numeric precision" do
      # Update only the specific fields with extreme values, keeping other required fields intact
      inspection.user_height_assessment.update!(
        containing_wall_height: 999.999999,
        platform_height: 0.000001,
        tallest_user_height: 1.23456789,
        play_area_length: 999999.123456,
        play_area_width: 0.000000001
      )

      pdf_data = get_pdf(inspection_path(inspection, format: :pdf))
      expect_valid_pdf(pdf_data)
    end

    scenario "handles nil and blank numeric values" do
      # For this test, we want to test PDF generation with some nil values
      # but keep the inspection valid by only nullifying optional fields
      inspection.user_height_assessment.update!(
        platform_height_comment: nil,
        containing_wall_height_comment: "",
        negative_adjustment: 0,
        users_at_1000mm: 0
      )

      pdf_text = get_pdf_text(inspection_path(inspection, format: :pdf))
      expect(pdf_text).to be_present
      # The PDF should handle these edge cases gracefully
    end
  end

  feature "Large data sets and performance" do
    scenario "handles inspection with all assessment types and maximum data" do
      # Create unit with all features
      full_unit = create(:unit, :with_all_fields, user: user)

      full_inspection = create_completed_inspection(traits: [:with_complete_assessments, :with_slide, :totally_enclosed], user: user, unit: full_unit)

      # Add maximum length comments to all assessments
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

      # Verify PDF contains all sections
      %w[User\ Height Slide Structure Anchorage Materials Fan/Blower Totally\ Enclosed].each do |section|
        expect(pdf_text).to include(section)
      end
    end

    scenario "generates PDFs with reasonable file sizes" do
      pdf_data = get_pdf(inspection_path(inspection, format: :pdf))
      pdf_size = pdf_data.bytesize

      expect(pdf_size).to be < 2.megabytes  # Should be under 2MB for basic inspection
      expect(pdf_size).to be > 1.kilobyte   # Should have substantial content
    end
  end

  feature "Concurrent access" do
    scenario "handles multiple simultaneous PDF requests" do
      threads = []
      results = []

      # Simulate 5 concurrent PDF generation requests
      5.times do |i|
        threads << Thread.new do
          # Each thread uses a fresh browser session
          new_page = Capybara::Session.new(:rack_test, Capybara.app)
          new_page.driver.browser.get(inspection_path(inspection, format: :pdf))

          results << {
            status: new_page.driver.response.status,
            content_type: new_page.driver.response.headers["Content-Type"],
            pdf_valid: new_page.driver.response.body[0..3] == "%PDF"
          }
        end
      end

      threads.each(&:join)

      # All requests should succeed
      expect(results.size).to eq(5)
      results.each do |result|
        expect(result[:status]).to eq(200)
        expect(result[:content_type]).to eq("application/pdf")
        expect(result[:pdf_valid]).to be true
      end
    end
  end

  feature "Memory and resource management" do
    scenario "cleans up temporary files during PDF generation" do
      # Monitor temporary file creation more specifically for this process
      process_pattern = "/tmp/*qr_code*#{inspection.id}_#{Process.pid}*"

      10.times do
        temp_files_before = Dir.glob(process_pattern).size
        get_pdf(inspection_path(inspection, format: :pdf))

        # Allow a brief moment for cleanup
        sleep(0.01)

        # Should not leave files for this specific process/inspection combo
        temp_files_after = Dir.glob(process_pattern).size
        expect(temp_files_after).to eq(temp_files_before)
      end
    end
  end

  feature "Error recovery" do
    scenario "handles corrupted assessment data gracefully" do
      # Create assessment with potentially problematic data
      assessment = build(:user_height_assessment, inspection: inspection)
      assessment.save!(validate: false)  # Bypass validations

      # Manually corrupt some data in the database
      assessment.update_columns(
        containing_wall_height: "invalid_number",
        users_at_1000mm: -999
      )

      # Should still generate PDF, just with "N/A" or safe defaults
      pdf_data = get_pdf(inspection_path(inspection, format: :pdf))
      expect_valid_pdf(pdf_data)
    end
  end
end
