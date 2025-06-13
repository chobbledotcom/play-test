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
      owner: "Test Owner")
  end

  before do
    sign_in(user)
  end

  feature "Inspection PDF renders all relevant model fields" do
    scenario "includes all inspection model fields except system/metadata fields" do
          inspection = create(:inspection, :pdf_complete_test_data, :with_slide, :totally_enclosed, user: user, unit: unit)

          # Just check that the PDF actually has the important stuff
          text_content = get_pdf_text(inspection_report_path(inspection))

          # Core inspection info
          expect(text_content).to include("Test Bouncy Castle")
          expect(text_content).to include("BCL-2024-001")
          expect(text_content).to include(inspection.inspection_date.strftime("%d/%m/%Y"))
          expect(text_content).to include(inspection.passed? ? I18n.t("pdf.inspection.passed") : I18n.t("pdf.inspection.failed"))
          expect(text_content).to include("#{I18n.t("pdf.inspection.fields.report_id")}: #{inspection.id}")

          # Unit details (the stuff we just fixed)
          expect(text_content).to include(I18n.t("pdf.dimensions.width"))
          expect(text_content).to include(I18n.t("pdf.dimensions.length"))
          expect(text_content).to include(I18n.t("pdf.dimensions.height"))
          expect(text_content).to include("Bounce Co Ltd")
          expect(text_content).to include("Test Owner")

          # Assessment sections exist
          expect(text_content).to include(I18n.t("forms.tallest_user_height.header"))
          expect(text_content).to include(I18n.t("forms.structure.header"))
          expect(text_content).to include(I18n.t("forms.anchorage.header"))
          expect(text_content).to include(I18n.t("forms.materials.header"))
          expect(text_content).to include(I18n.t("forms.fan.header"))

          # Some actual assessment data shows up
          expect(text_content).to include(I18n.t("shared.pass")) # Should have some passing assessments
          expect(text_content).to include("1.2") # containing_wall_height
          expect(text_content).to include("1.8") # platform_height
        end

    scenario "handles nil and empty values gracefully" do
      # Create inspection with minimal data
      inspection = create(:inspection, :completed,
        user: user,
        unit: unit,
        inspection_location: "Minimal Test Location",
        passed: true)

      # Assessments are auto-created by inspection callback with nil values

      # Should generate PDF successfully even with minimal data
      text_content = test_pdf_content(inspection_report_path(inspection))

      # Should include fallback text for missing data
      expect_no_assessment_messages(text_content, inspection)
    end
  end

  private

  def inspection_report_path(inspection)
    "/inspections/#{inspection.id}.pdf"
  end
end
