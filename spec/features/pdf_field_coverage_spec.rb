require "rails_helper"
require "pdf/inspector"
require_relative "../../db/seeds/seed_data"

RSpec.feature "PDF Field Coverage", type: :feature do
  let(:user) { create(:user) }
  let(:inspector_company) { user.inspection_company }
  let(:unit) do
    create(:unit,
      user: user,
      **SeedData.unit_fields)
  end

  before do
    sign_in(user)
  end

  feature "Inspection PDF renders all relevant model fields" do
    scenario "includes all inspection model fields except system/metadata fields" do
      inspection = create(:inspection, :with_slide, :totally_enclosed, :completed, user: user, unit: unit)

      # Just check that the PDF actually has the important stuff
      text_content = get_pdf_text(inspection_path(inspection, format: :pdf))

      # Core inspection info
      expect(text_content).to include(unit.name)
      expect(text_content).to include(unit.serial)
      expect(text_content).to include(inspection.inspection_date.strftime("%d/%m/%Y"))
      expect(text_content).to include(inspection.passed? ? I18n.t("pdf.inspection.passed") : I18n.t("pdf.inspection.failed"))
      expect(text_content).to include("#{I18n.t("pdf.inspection.fields.report_id")}: #{inspection.id}")

      # Unit details (the stuff we just fixed)
      expect(text_content).to include(I18n.t("pdf.dimensions.width"))
      expect(text_content).to include(I18n.t("pdf.dimensions.length"))
      expect(text_content).to include(I18n.t("pdf.dimensions.height"))
      expect(text_content).to include(unit.manufacturer)
      expect(text_content).to include(unit.owner)

      # Assessment sections exist - loop through all assessment types
      Inspection::ASSESSMENT_TYPES.each do |assessment_name, _assessment_class|
        # Skip conditional assessments if not applicable
        next if assessment_name == :slide_assessment && !inspection.has_slide?
        next if assessment_name == :enclosed_assessment && !inspection.is_totally_enclosed?
        
        # Get the i18n key for this assessment
        assessment_type = assessment_name.to_s.sub(/_assessment$/, "")
        header = I18n.t("forms.#{assessment_type}.header")
        expect(text_content).to include(header)
      end

      # Some actual assessment data shows up
      expect(text_content).to include("[PASS]") # Should have some passing assessments
      expect(text_content).to include("1.2") # containing_wall_height
      expect(text_content).to include("1.8") # platform_height
    end
  end

  private
end
