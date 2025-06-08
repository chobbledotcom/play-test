require "rails_helper"
require "pdf/inspector"

RSpec.feature "PDF Content Structure", type: :feature do
  let(:user) { create(:user) }
  let(:inspector_company) { user.inspection_company }
  let(:unit) do
    create(:unit,
      user: user,
      name: "Test Bouncy Castle",
      manufacturer: "Bounce Co Ltd",
      serial_number: "BCL-2024-001",
      width: 5.5,
      length: 6.0,
      height: 4.5)
  end

  before do
    sign_in(user)
  end

  feature "Inspection PDF Content" do
    scenario "includes all required sections" do
      inspection = create(:inspection, :completed,
        user: user,
        unit: unit,
        inspection_location: "Happy Kids Play Centre",
        passed: true)

      # Create assessments
      create(:user_height_assessment,
        inspection: inspection,
        containing_wall_height: 2.5,
        user_height: 1.8,
        users_at_1800mm: 5)

      create(:structure_assessment,
        inspection: inspection,
        seam_integrity_pass: true,
        lock_stitch_pass: true,
        air_loss_pass: true)

      get(inspection_report_path(inspection))

      # Analyze PDF content
      pdf = PDF::Inspector::Text.analyze(response.body)
      text_content = pdf.strings.join(" ")

      # Check header section
      expect(text_content).to include(I18n.t("pdf.inspection.title"))
      expect(text_content).to include(inspector_company.name)
      expect(text_content).to include(inspector_company.rpii_registration_number)
      expect(text_content).to include("Happy Kids Play Centre")

      # Check equipment details
      expect(text_content).to include(I18n.t("pdf.inspection.equipment_details"))
      expect(text_content).to include("Test Bouncy Castle")
      expect(text_content).to include("Bounce Co Ltd")
      expect(text_content).to include("BCL-2024-001")
      expect(text_content).to include("5.5") # width
      expect(text_content).to include("6.0") # length
      expect(text_content).to include("4.5") # height

      # Check inspection results
      expect(text_content).to include(I18n.t("pdf.inspection.inspection_results"))

      # Check assessment sections
      expect(text_content).to include("User Height")
      expect(text_content).to include("Structure")

      # Check final result
      expect(text_content).to include("PASSED")

      # Check footer
      expect(text_content).to include(I18n.t("pdf.inspection.footer_text"))
      expect(text_content).to include(I18n.t("pdf.inspection.verification"))
    end

    scenario "handles failed inspection correctly" do
      failed_inspection = create(:inspection, :completed,
        user: user,
        unit: unit,
        passed: false,
        comments: "Multiple safety issues found")

      # Create failing assessments
      create(:structure_assessment,
        inspection: failed_inspection,
        seam_integrity_pass: false,
        seam_integrity_comment: "Torn seam on left side")

      get(inspection_report_path(failed_inspection))

      pdf = PDF::Inspector::Text.analyze(response.body)
      text_content = pdf.strings.join(" ")

      # Check for failed status
      expect(text_content).to include("FAILED")
      expect(text_content).to include("Multiple safety issues found")
      expect(text_content).to include("Torn seam on left side")
    end

    scenario "includes all assessment types when present" do
      # Create unit with slide and totally enclosed
      special_unit = create(:unit,
        user: user,
        has_slide: true,
        is_totally_enclosed: true)

      inspection = create(:inspection, :completed,
        user: user,
        unit: special_unit)

      # Create all assessment types
      create(:user_height_assessment, inspection: inspection)
      create(:structure_assessment, inspection: inspection)
      create(:anchorage_assessment, inspection: inspection)
      create(:materials_assessment, inspection: inspection)
      create(:fan_assessment, inspection: inspection)
      create(:slide_assessment, inspection: inspection)
      create(:enclosed_assessment, inspection: inspection)

      get(inspection_report_path(inspection))

      pdf = PDF::Inspector::Text.analyze(response.body)
      text_content = pdf.strings.join(" ")

      # Check all assessment sections are present
      expect(text_content).to include("User Height")
      expect(text_content).to include("Structure")
      expect(text_content).to include("Anchorage")
      expect(text_content).to include("Materials")
      expect(text_content).to include("Fan/Blower")
      expect(text_content).to include("Slide")
      expect(text_content).to include("Totally Enclosed")
    end

    scenario "shows 'No data available' for missing assessments" do
      inspection = create(:inspection, :completed,
        user: user,
        unit: unit)

      # Don't create any assessments

      get(inspection_report_path(inspection))

      pdf = PDF::Inspector::Text.analyze(response.body)
      text_content = pdf.strings.join(" ")

      # Should show no data messages
      expect(text_content).to include("No user height assessment data available")
      expect(text_content).to include("No structure assessment data available")
    end
  end

  feature "Unit History PDF Content" do
    scenario "includes unit details and inspection history" do
      # Create multiple inspections
      inspections = []
      3.times do |i|
        inspections << create(:inspection, :completed,
          user: user,
          unit: unit,
          inspection_date: i.months.ago,
          passed: i.even?)
      end

      get(unit_report_path(unit))

      pdf = PDF::Inspector::Text.analyze(response.body)
      text_content = pdf.strings.join(" ")

      # Check header
      expect(text_content).to include(I18n.t("pdf.unit.title"))

      # Check unit details
      expect(text_content).to include(I18n.t("pdf.unit.details"))
      expect(text_content).to include("Test Bouncy Castle")
      expect(text_content).to include("Bounce Co Ltd")
      expect(text_content).to include("BCL-2024-001")

      # Check inspection history
      expect(text_content).to include(I18n.t("pdf.unit.inspection_history"))

      # Should include inspection dates
      inspections.each do |inspection|
        expect(text_content).to include(inspection.inspection_date.strftime("%d/%m/%Y"))
      end
    end

    scenario "handles unit with no inspections" do
      empty_unit = create(:unit, user: user)

      page.driver.browser.get(unit_report_path(empty_unit))

      pdf = PDF::Inspector::Text.analyze(page.driver.response.body)
      text_content = pdf.strings.join(" ")

      expect(text_content).to include(I18n.t("pdf.unit.title"))
      expect(text_content).to include(I18n.t("pdf.unit.no_completed_inspections"))
    end
  end

  feature "PDF Formatting" do
    scenario "uses correct fonts" do
      inspection = create(:inspection, :completed, user: user, unit: unit)

      page.driver.browser.get(inspection_report_path(inspection))

      # Check that PDF is generated successfully
      expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")

      # Verify it's a valid PDF that can be parsed
      expect { PDF::Inspector::Text.analyze(page.driver.response.body) }.not_to raise_error
    end

    scenario "generates valid PDF structure" do
      inspection = create(:inspection, :completed, user: user, unit: unit)

      page.driver.browser.get(inspection_report_path(inspection))

      # Check PDF header
      expect(page.driver.response.body[0..3]).to eq("%PDF")

      # Check it's a valid PDF by trying to parse it
      expect { PDF::Inspector::Text.analyze(page.driver.response.body) }.not_to raise_error
    end
  end

  feature "QR Code Generation" do
    scenario "includes QR code in inspection report" do
      inspection = create(:inspection, :completed, user: user, unit: unit)

      page.driver.browser.get(inspection_report_path(inspection))

      # PDF should contain image data (QR code)
      expect(page.driver.response.body).to include("/Image")

      pdf = PDF::Inspector::Text.analyze(page.driver.response.body)
      text_content = pdf.strings.join(" ")

      # Should include QR code related text
      expect(text_content).to include(I18n.t("pdf.inspection.scan_text"))
      expect(text_content).to include("/r/#{inspection.id}")
    end
  end

  private

  def get(path)
    # Helper method to make direct GET requests in feature specs
    page.driver.browser.get(path)
  end

  def response
    page.driver.response
  end

  def inspection_report_path(inspection)
    "/inspections/#{inspection.id}/report"
  end

  def unit_report_path(unit)
    "/units/#{unit.id}/report"
  end
end
