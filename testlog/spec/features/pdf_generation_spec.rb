require "rails_helper"

RSpec.feature "PDF Generation", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user, manufacturer: "Test Manufacturer", serial: "TEST123", serial_number: "SN-TEST123") }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  before do
    sign_in(user)
  end

  feature "Inspection PDF Report" do
    scenario "generates PDF from inspection show page" do
      visit inspection_path(inspection)

      # For complete inspections, check if PDF is embedded
      if inspection.status == "complete"
        expect(page).to have_css("iframe")
        expect(page).to have_link(short_report_url(inspection)) # Public report link
      end

      # Access PDF directly via report route
      page.driver.browser.get(report_inspection_path(inspection))

      # Verify PDF response
      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
      expect(page.driver.response.body[0..3]).to eq("%PDF")
    end

    scenario "generates PDF with complete assessment data" do
      # Create inspection with all assessments
      inspection = create(:inspection, :completed, user: user, unit: unit)

      # Create all assessment types
      create(:user_height_assessment, :complete, inspection: inspection)
      create(:structure_assessment, :passed, inspection: inspection)
      create(:anchorage_assessment, :passed, inspection: inspection)
      create(:materials_assessment, :passed, inspection: inspection)
      create(:fan_assessment, :passed, inspection: inspection)

      if unit.has_slide?
        create(:slide_assessment, :complete, inspection: inspection)
      end

      if unit.is_totally_enclosed?
        create(:enclosed_assessment, :passed, inspection: inspection)
      end

      page.driver.browser.get(report_inspection_path(inspection))

      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
    end

    scenario "handles inspection without unit gracefully" do
      inspection_without_unit = create(:inspection, :completed, user: user, unit: nil)

      # Access PDF directly
      page.driver.browser.get(report_inspection_path(inspection_without_unit))

      # Should generate PDF without errors
      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
      expect(page.driver.response.body[0..3]).to eq("%PDF")
    end

    scenario "shows correct status for draft inspection" do
      draft_inspection = create(:inspection, status: "draft", user: user, unit: unit)

      # Draft inspections cannot generate PDFs
      page.driver.browser.get(report_inspection_path(draft_inspection))

      expect(page.driver.response.status).to eq(404)
    end

    scenario "generates PDF for complete inspection" do
      # Create a complete inspection
      complete_inspection = create(:inspection, :complete, user: user, unit: unit)

      visit inspection_path(complete_inspection)

      # Complete inspections should show PDF in iframe
      expect(page).to have_css("iframe")

      # Access PDF directly
      page.driver.browser.get(report_inspection_path(complete_inspection))

      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
    end
  end

  feature "Unit PDF Report" do
    scenario "generates PDF from unit show page" do
      # Create some inspections for the unit
      create_list(:inspection, 3, :completed, user: user, unit: unit)

      visit unit_path(unit)

      # Access PDF directly
      page.driver.browser.get(report_unit_path(unit))

      # Verify PDF response
      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
      expect(page.driver.response.body[0..3]).to eq("%PDF")
    end

    scenario "handles unit with no inspections" do
      unit_without_inspections = create(:unit, user: user)

      # Access PDF directly
      page.driver.browser.get(report_unit_path(unit_without_inspections))

      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
      expect(page.driver.response.body[0..3]).to eq("%PDF")
    end
  end

  feature "Public Report Access" do
    scenario "allows public access to completed inspection report" do
      completed_inspection = create(:inspection, :completed, user: user, unit: unit)

      # Log out first
      visit logout_path

      # Visit public report URL
      visit "/r/#{completed_inspection.id}"

      # Should get PDF without login
      expect(page.response_headers["Content-Type"]).to eq("application/pdf")
      expect(page.body[0..3]).to eq("%PDF")
    end

    scenario "denies public access to draft inspection report" do
      draft_inspection = create(:inspection, status: "draft", user: user, unit: unit)

      # Log out first
      visit logout_path

      # Visit public report URL
      page.driver.browser.get("/r/#{draft_inspection.id}")

      # Should return 404
      expect(page.driver.response.status).to eq(404)
    end

    scenario "handles uppercase inspection IDs" do
      completed_inspection = create(:inspection, :completed, user: user, unit: unit)

      visit logout_path
      visit "/R/#{completed_inspection.id.upcase}"

      expect(page.response_headers["Content-Type"]).to eq("application/pdf")
    end
  end

  feature "PDF Content Validation" do
    scenario "PDF contains required inspection information" do
      # Create inspection with specific data
      inspection = create(:inspection, :completed,
        user: user,
        unit: unit,
        inspection_location: "Test Location",
        passed: true)

      # Get PDF content directly
      page.driver.browser.get(report_inspection_path(inspection))

      pdf_content = PDF::Inspector::Text.analyze(page.driver.response.body)
      text_content = pdf_content.strings.join(" ")

      # Check for required content
      expect(text_content).to include(I18n.t("pdf.inspection.title"))
      expect(text_content).to include(unit.manufacturer)
      expect(text_content).to include(unit.serial_number)
      expect(text_content).to include("Test Location")
      expect(text_content).to include(inspection.inspector_company.name)
    end

    scenario "PDF handles missing optional fields gracefully" do
      # Create minimal inspection
      minimal_unit = create(:unit, user: user, manufacturer: "Minimal Manufacturer")
      minimal_inspection = create(:inspection, :completed,
        user: user,
        unit: minimal_unit,
        comments: nil)

      page.driver.browser.get(report_inspection_path(minimal_inspection))

      pdf_content = PDF::Inspector::Text.analyze(page.driver.response.body)
      pdf_content.strings.join(" ")

      # Should generate PDF successfully even with nil comments
      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
    end
  end

  feature "Error Handling" do
    scenario "handles non-existent inspection gracefully" do
      visit "/inspections/NONEXISTENT/report"
      expect(page).to have_http_status(:not_found)
    end

    scenario "handles unauthorized access" do
      other_user = create(:user)
      other_inspection = create(:inspection, :completed, user: other_user)

      # Public reports are accessible without login
      visit logout_path
      page.driver.browser.get(report_inspection_path(other_inspection))

      # Should get PDF without login (public access)
      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
    end
  end

  private

  def sign_in(user)
    visit login_path
    fill_in I18n.t("session.login.email"), with: user.email
    fill_in I18n.t("session.login.password"), with: "password123"
    click_button I18n.t("session.login.submit")
  end

  def inspection_report_path(inspection)
    report_inspection_path(inspection)
  end

  def short_report_url(inspection)
    "/r/#{inspection.id}"
  end
end
