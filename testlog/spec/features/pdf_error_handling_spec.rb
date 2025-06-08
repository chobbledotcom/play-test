require "rails_helper"

RSpec.feature "PDF Error Handling", type: :feature do
  let(:user) { create(:user) }

  feature "Authentication and Authorization" do
    scenario "allows public access to completed inspection report without authentication" do
      inspection = create(:inspection, :completed)

      visit "/r/#{inspection.id}"

      expect(page.response_headers["Content-Type"]).to include("application/pdf")
    end

    scenario "allows access to other users' inspection reports via public URL" do
      other_user = create(:user)
      other_inspection = create(:inspection, :completed, user: other_user)

      # Don't sign in - access as public

      visit "/r/#{other_inspection.id}"

      expect(page.response_headers["Content-Type"]).to include("application/pdf")
    end
  end

  feature "Edge Cases" do
    before { sign_in(user) }

    scenario "handles inspection with very long text fields" do
      # Create unit with extremely long fields
      long_text = "A" * 5000
      unit = create(:unit,
        user: user,
        name: long_text,
        manufacturer: long_text,
        description: long_text,
        notes: long_text)

      inspection = create(:inspection, :completed,
        user: user,
        unit: unit,
        inspection_location: long_text,
        comments: long_text)

      # Create assessments with long comments
      create(:structure_assessment,
        inspection: inspection,
        seam_integrity_comment: long_text,
        lock_stitch_comment: long_text)

      page.driver.browser.get("/inspections/#{inspection.id}/report")

      # Should still generate PDF without error
      expect(page.driver.response.status).to eq(200)
      expect(page.driver.response.headers["Content-Type"]).to include("application/pdf")

      # PDF should be valid
      expect { PDF::Inspector::Text.analyze(page.driver.response.body) }.not_to raise_error
    end

    scenario "handles special characters in text fields" do
      special_chars = "Test™ © ® → ← ↑ ↓ • × ÷ ≠ ≤ ≥ € £ ¥ § ¶"
      unit = create(:unit,
        user: user,
        name: special_chars,
        manufacturer: "Émojï Mfg 🎪🎈🎯")

      inspection = create(:inspection, :completed,
        user: user,
        unit: unit,
        inspection_location: "Café ñoño à la française")

      page.driver.browser.get("/inspections/#{inspection.id}/report")

      expect(page.driver.response.status).to eq(200)

      # Check PDF content includes special characters
      pdf = PDF::Inspector::Text.analyze(page.driver.response.body)
      text_content = pdf.strings.join(" ")

      # Some special characters might be replaced or handled differently
      expect(text_content).to include("Test")
      expect(text_content).to include("Caf")
    end

    scenario "handles nil values gracefully" do
      # Create inspection with minimal data
      inspection = create(:inspection, :completed,
        user: user,
        unit: nil,
        inspection_location: "Test Location",
        comments: nil)

      page.driver.browser.get("/r/#{inspection.id}")

      expect(page.driver.response.status).to eq(200)

      # Should generate valid PDF even with nil values
      expect { PDF::Inspector::Text.analyze(page.driver.response.body) }.not_to raise_error
    end

    scenario "handles decimal values with extreme precision" do
      unit = create(:unit,
        user: user,
        width: 5.123456789,
        length: 10.987654321,
        height: 3.14159265359)

      inspection = create(:inspection, :completed, user: user, unit: unit)

      create(:structure_assessment,
        inspection: inspection,
        stitch_length: 12.3456789,
        unit_pressure_value: 2.71828182846)

      page.driver.browser.get("/inspections/#{inspection.id}/report")

      expect(page.driver.response.status).to eq(200)

      pdf = PDF::Inspector::Text.analyze(page.driver.response.body)
      text_content = pdf.strings.join(" ")

      # Should format numbers appropriately
      expect(text_content).to match(/5\.\d+/)
      expect(text_content).to match(/10\.\d+/)
    end

    scenario "handles concurrent PDF generation requests" do
      inspection = create(:inspection, :completed, user: user)

      # Simulate multiple concurrent requests
      threads = []
      results = []

      3.times do
        threads << Thread.new do
          response = page.driver.browser.get("/inspections/#{inspection.id}/report")
          results << response
        end
      end

      threads.each(&:join)

      # All requests should succeed
      results.each do |response|
        expect(response.status).to eq(200)
        expect(response.headers["Content-Type"]).to include("application/pdf")
      end
    end
  end

  feature "Status-based Access Control" do
    before { sign_in(user) }

    scenario "prevents PDF generation for draft inspections" do
      draft = create(:inspection, status: "draft", user: user)

      page.driver.browser.get("/r/#{draft.id}")

      expect(page.driver.response.status).to eq(404)
    end

    scenario "prevents public access to draft inspection PDFs" do
      draft = create(:inspection, :draft, user: user)

      # Log out
      visit logout_path

      # Try public URL
      visit "/r/#{draft.id}"

      expect(page).to have_http_status(:not_found)
    end

    scenario "allows public access only to completed inspections" do
      completed = create(:inspection, :completed, user: user)
      in_progress = create(:inspection, :in_progress, user: user)

      visit logout_path

      # Completed should work
      visit "/r/#{completed.id}"
      expect(page.response_headers["Content-Type"]).to include("application/pdf")

      # In progress should not
      visit "/r/#{in_progress.id}"
      expect(page).to have_http_status(:not_found)
    end
  end

  feature "File Size and Performance" do
    before { sign_in(user) }

    scenario "generates reasonably sized PDFs" do
      # Create inspection with lots of data
      unit = create(:unit, user: user)
      inspection = create(:inspection, :completed, user: user, unit: unit)

      # Add all assessments
      create(:user_height_assessment, :complete, inspection: inspection)
      create(:structure_assessment, :complete, inspection: inspection)
      create(:anchorage_assessment, :complete, inspection: inspection)
      create(:materials_assessment, :complete, inspection: inspection)
      create(:fan_assessment, :complete, inspection: inspection)

      page.driver.browser.get("/inspections/#{inspection.id}/report")

      pdf_size = page.driver.response.body.bytesize

      # PDF should be reasonable size (less than 5MB)
      expect(pdf_size).to be < 5_000_000
      expect(pdf_size).to be > 1000 # But not empty
    end

    scenario "generates PDF within reasonable time" do
      inspection = create(:inspection, :completed, user: user)

      start_time = Time.current
      page.driver.browser.get("/inspections/#{inspection.id}/report")
      end_time = Time.current

      # Should generate within 5 seconds
      expect(end_time - start_time).to be < 5.seconds
    end
  end

  private

  def sign_in(user)
    visit login_path
    fill_in I18n.t("session.login.email"), with: user.email
    fill_in I18n.t("session.login.password"), with: "password123"
    click_button I18n.t("session.login.submit")
  end
end
