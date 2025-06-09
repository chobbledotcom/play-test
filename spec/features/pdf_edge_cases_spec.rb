require "rails_helper"
require "pdf/inspector"

RSpec.feature "PDF Edge Cases and Stress Testing", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  before do
    sign_in(user)
  end

  feature "Extreme text handling" do
    scenario "handles 5000+ character text fields" do
      extremely_long_text = "Lorem ipsum " * 500  # ~5500 characters

      inspection.update(
        inspection_location: "Location: #{extremely_long_text}",
        comments: "Comments: #{extremely_long_text}"
      )

      page.driver.browser.get("/inspections/#{inspection.id}/report")

      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
      expect(page.driver.response.body[0..3]).to eq("%PDF")

      # PDF should be generated without errors
      expect { PDF::Inspector::Text.analyze(page.driver.response.body) }.not_to raise_error
    end

    scenario "handles mixed Unicode, emoji, and special characters" do
      mixed_content = "测试 🎈 Ñoël Zürich ¡Hola! 数学 symbols: ∑∆π€£¥ emojis: 🏭🔧⚡🎯"

      inspection.update(
        inspection_location: mixed_content,
        comments: "#{mixed_content} with more content"
      )

      page.driver.browser.get("/inspections/#{inspection.id}/report")

      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")

      pdf_text = PDF::Inspector::Text.analyze(page.driver.response.body).strings.join(" ")
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
        inspection.update(comments: content)

        page.driver.browser.get("/inspections/#{inspection.id}/report")

        expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
        expect(page.driver.response.body[0..3]).to eq("%PDF")
      end
    end
  end

  feature "Numeric precision and edge values" do
    scenario "handles extreme numeric precision" do
      # Create assessments with extreme values
      create(:user_height_assessment, :extreme_values, inspection: inspection)

      page.driver.browser.get("/inspections/#{inspection.id}/report")

      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
      expect(page.driver.response.body[0..3]).to eq("%PDF")

      # Just verify PDF was generated successfully with extreme numeric values
      expect { PDF::Inspector::Text.analyze(page.driver.response.body) }.not_to raise_error
    end

    scenario "handles nil and blank numeric values" do
      create(:user_height_assessment, :edge_case_values, inspection: inspection)

      page.driver.browser.get("/inspections/#{inspection.id}/report")

      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")

      pdf_text = PDF::Inspector::Text.analyze(page.driver.response.body).strings.join(" ")
      expect(pdf_text).to include("N/A").or include("0")
    end
  end

  feature "Large data sets and performance" do
    scenario "handles inspection with all assessment types and maximum data" do
      # Create unit with all features
      full_unit = create(:unit, :maximum_size_full_featured, user: user)

      full_inspection = create(:inspection, :completed, user: user, unit: full_unit)

      # Create all assessment types with full data
      create(:user_height_assessment, inspection: full_inspection)
      create(:slide_assessment, inspection: full_inspection)
      create(:structure_assessment, inspection: full_inspection)
      create(:anchorage_assessment, inspection: full_inspection)
      create(:materials_assessment, inspection: full_inspection)
      create(:fan_assessment, inspection: full_inspection)
      create(:enclosed_assessment, inspection: full_inspection)

      # Add maximum length comments to all assessments
      long_comment = "Detailed assessment comment " * 50
      full_inspection.user_height_assessment.update(
        containing_wall_height_comment: long_comment,
        platform_height_comment: long_comment,
        tallest_user_height_comment: long_comment
      )

      start_time = Time.current
      page.driver.browser.get("/inspections/#{full_inspection.id}/report")
      generation_time = Time.current - start_time

      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
      expect(generation_time).to be < 10.seconds  # Should generate within 10 seconds

      # Verify PDF contains all sections
      pdf_text = PDF::Inspector::Text.analyze(page.driver.response.body).strings.join(" ")
      expect(pdf_text).to include("User Height")
      expect(pdf_text).to include("Slide")
      expect(pdf_text).to include("Structure")
      expect(pdf_text).to include("Anchorage")
      expect(pdf_text).to include("Materials")
      expect(pdf_text).to include("Fan/Blower")
      expect(pdf_text).to include("Totally Enclosed")
    end

    scenario "generates PDFs with reasonable file sizes" do
      page.driver.browser.get("/inspections/#{inspection.id}/report")

      pdf_size = page.driver.response.body.bytesize
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
          new_page.driver.browser.get("/inspections/#{inspection.id}/report")

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
        page.driver.browser.get("/inspections/#{inspection.id}/report")
        expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")

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

      page.driver.browser.get("/inspections/#{inspection.id}/report")

      # Should still generate PDF, just with "N/A" or safe defaults
      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
      expect(page.driver.response.body[0..3]).to eq("%PDF")
    end
  end
end
