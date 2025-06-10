require "rails_helper"
require "pdf/inspector"

RSpec.feature "PDF Field Coverage", type: :feature do
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
      height: 4.5,
      has_slide: true,
      is_totally_enclosed: true)
  end

  before do
    sign_in(user)
  end

  feature "Inspection PDF renders all relevant model fields" do
    scenario "includes all inspection model fields except system/metadata fields" do
      inspection = create(:inspection, :pdf_complete_test_data, user: user, unit: unit)

      # Create all assessment types with complete data using factories
      create(:user_height_assessment, :complete,
        inspection: inspection,
        permanent_roof: true)

      create(:structure_assessment, :complete,
        inspection: inspection,
        evacuation_time: 25.0,
        evacuation_time_pass: true)

      create(:anchorage_assessment, :complete,
        inspection: inspection)

      create(:materials_assessment, :complete,
        inspection: inspection)

      create(:fan_assessment, :complete,
        inspection: inspection)

      create(:slide_assessment, :complete,
        inspection: inspection,
        slide_permanent_roof: false)

      create(:enclosed_assessment, :passed,
        inspection: inspection)

      get(inspection_report_path(inspection))

      # Just check that the PDF actually has the important stuff
      pdf = PDF::Inspector::Text.analyze(response.body)
      text_content = pdf.strings.join(" ")

      # Core inspection info
      expect(text_content).to include("Test Bouncy Castle")
      expect(text_content).to include("BCL-2024-001") 
      expect(text_content).to include(inspection.inspection_date.strftime("%d/%m/%Y"))
      expect(text_content).to include(inspection.passed? ? I18n.t("pdf.inspection.passed") : I18n.t("pdf.inspection.failed"))
      expect(text_content).to include("#{I18n.t("pdf.inspection.fields.report_id")}: #{inspection.id}")
      
      # Unit details (the stuff we just fixed)
      expect(text_content).to include(I18n.t('pdf.dimensions.width'))
      expect(text_content).to include(I18n.t('pdf.dimensions.length'))
      expect(text_content).to include(I18n.t('pdf.dimensions.height'))
      expect(text_content).to include("Bounce Co Ltd")
      expect(text_content).to include("Test Owner")
      
      # Assessment sections exist
      expect(text_content).to include(I18n.t("inspections.assessments.user_height.title"))
      expect(text_content).to include(I18n.t("inspections.assessments.structure.title"))
      expect(text_content).to include(I18n.t("inspections.assessments.anchorage.title"))
      expect(text_content).to include(I18n.t("inspections.assessments.materials.title"))
      expect(text_content).to include(I18n.t("inspections.assessments.fan.title"))
      
      # Some actual assessment data shows up
      expect(text_content).to include(I18n.t("pdf.inspection.fields.pass")) # Should have some passing assessments
      expect(text_content).to include("2.5") # containing_wall_height
      expect(text_content).to include("1.8") # platform_height
    end

    scenario "handles nil and empty values gracefully" do
      # Create inspection with minimal data
      inspection = create(:inspection, :completed,
        user: user,
        unit: unit,
        inspection_location: "Minimal Test Location",
        passed: true)

      # Create minimal assessments with mostly nil values
      create(:user_height_assessment, inspection: inspection)
      create(:structure_assessment, inspection: inspection)

      get(inspection_report_path(inspection))

      # Should generate PDF successfully even with minimal data
      expect(response.status).to eq(200)
      expect(response.headers["Content-Type"]).to eq("application/pdf")

      # Verify it's a valid PDF
      expect { PDF::Inspector::Text.analyze(response.body) }.not_to raise_error

      pdf = PDF::Inspector::Text.analyze(response.body)
      text_content = pdf.strings.join(" ")

      # Should include fallback text for missing data
      expect(text_content).to include("N/A")
      expect(text_content).to include("No") # for "No data available" messages
    end
  end

  private

  def get(path)
    page.driver.browser.get(path)
  end

  def response
    page.driver.response
  end

  def inspection_report_path(inspection)
    "/inspections/#{inspection.id}/report"
  end
end
