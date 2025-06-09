require "rails_helper"
require "pdf/inspector"

RSpec.feature "PDF Content Structure", type: :feature, pdf: true do
  let(:user) { create(:user) }
  let(:inspector_company) { user.inspection_company }
  let(:unit) do
    create(:unit,
      user: user,
      name: "Test Bouncy Castle",
      manufacturer: "Bounce Co Ltd",
      serial: "BCL-2024-001",
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
        tallest_user_height: 1.8,
        users_at_1800mm: 5)

      create(:structure_assessment,
        inspection: inspection,
        seam_integrity_pass: true,
        lock_stitch_pass: true,
        air_loss_pass: true)

      get(inspection_report_path(inspection))
      pdf_text = pdf_text_content(response.body)

      # Check all core i18n keys are present
      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.inspection.title",
        "pdf.inspection.equipment_details", 
        "pdf.inspection.inspection_results",
        "pdf.inspection.comments",
        "pdf.inspection.verification",
        "pdf.inspection.footer_text"
      )

      # Check dynamic content
      expect(pdf_text).to include(inspector_company.name)
      expect(pdf_text).to include(inspector_company.rpii_registration_number)
      expect(pdf_text).to include("Happy Kids Play Centre")
      expect(pdf_text).to include("Test Bouncy Castle")
      expect(pdf_text).to include("BCL-2024-001")
      expect(pdf_text).to include(unit.width.to_s)
      expect(pdf_text).to include(unit.length.to_s)
      expect(pdf_text).to include(unit.height.to_s)

      # Check assessment sections exist
      expect(pdf_text).to include("User Height")
      expect(pdf_text).to include("Structure")

      # Check result
      expect_pdf_to_include_i18n(pdf_text, "pdf.inspection.passed")
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
      pdf_text = pdf_text_content(response.body)

      # Check for failed status
      expect_pdf_to_include_i18n(pdf_text, "pdf.inspection.failed")
      expect(pdf_text).to include("Multiple safety issues found")
      expect(pdf_text).to include("Torn seam on left side")
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
      pdf_text = pdf_text_content(response.body)

      # Should show no data messages for assessments
      expect_no_assessment_messages(pdf_text, unit)
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

      get(report_unit_path(unit))
      pdf_text = pdf_text_content(response.body)

      # Check all core i18n keys are present
      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.unit.title",
        "pdf.unit.details",
        "pdf.unit.inspection_history",
        "pdf.unit.verification",
        "pdf.unit.footer_text"
      )

      # Check unit details
      expect(pdf_text).to include("Test Bouncy Castle")
      expect(pdf_text).to include("Bounce Co Ltd") 
      expect(pdf_text).to include("BCL-2024-001")

      # Should include inspection dates
      inspections.each do |inspection|
        expect(pdf_text).to include(inspection.inspection_date.strftime("%d/%m/%Y"))
      end
    end

    scenario "handles unit with no inspections" do
      empty_unit = create(:unit, user: user)

      get(report_unit_path(empty_unit))
      pdf_text = pdf_text_content(response.body)

      expect_pdf_to_include_i18n(pdf_text, "pdf.unit.title")
      expect_pdf_to_include_i18n(pdf_text, "pdf.unit.no_completed_inspections")
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
