require "rails_helper"
require "pdf/inspector"
require Rails.root.join("db/seeds/seed_data")

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
      inspection = create(:inspection, :completed, user: user, unit: unit)

      text_content = get_pdf_text(inspection_path(inspection, format: :pdf))

      expect(text_content).to include(unit.name)
      expect(text_content).to include(unit.serial)
      expect(text_content).to include(inspection.inspection_date.strftime("%-d %B, %Y"))
      expect(text_content).to include(inspection.passed? ?
        I18n.t("pdf.inspection.passed") :
        I18n.t("pdf.inspection.failed"))
      expect(text_content).to include("#{I18n.t("pdf.inspection.fields.report_id")}: #{inspection.id}")

      expect(text_content).to include(I18n.t("pdf.dimensions.width"))
      expect(text_content).to include(I18n.t("pdf.dimensions.length"))
      expect(text_content).to include(I18n.t("pdf.dimensions.height"))
      expect(text_content).to include(unit.manufacturer)
      expect(text_content).to include(unit.owner)

      inspection.each_applicable_assessment do |assessment_key, _, _|
        assessment_type = assessment_key.to_s.sub(/_assessment$/, "")
        header = I18n.t("forms.#{assessment_type}.header")
        expect(text_content).to include(header)
      end

      expect(text_content).to include("[PASS]") # Should have some passing assessments
      expect(text_content).to include("1.2") # containing_wall_height
      expect(text_content).to include("1.8") # platform_height
    end
  end
end
