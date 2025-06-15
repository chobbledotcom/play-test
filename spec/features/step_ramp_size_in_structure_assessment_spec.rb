require "rails_helper"

RSpec.feature "Step Ramp Size in Structure Assessment", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before { sign_in(user) }

  describe "structure assessment form" do
    before { visit edit_inspection_path(inspection) }

    it "shows and saves step size field" do
      visit edit_inspection_path(inspection, tab: "structure")

      # Verify field is visible
      expect(page).to have_content(I18n.t("forms.structure.fields.step_ramp_size"))

      # Fill and save using i18n
      fill_in I18n.t("forms.structure.fields.step_ramp_size"), with: "25"
      click_button I18n.t("forms.structure.submit")

      # Verify success
      expect(page).to have_content(I18n.t("inspections.messages.updated"))

      # Verify saved
      inspection.reload
      expect(inspection.structure_assessment.step_ramp_size).to eq(25.0)
    end
  end

  describe "data migration" do
    it "moves step_ramp_size fields from inspections to structure assessments" do
      # This test verifies that the migration worked correctly
      structure_assessment = inspection.structure_assessment

      # These fields should exist in structure_assessment
      expect(structure_assessment).to respond_to(:step_ramp_size)
      expect(structure_assessment).to respond_to(:step_ramp_size_pass)
      expect(structure_assessment).to respond_to(:step_ramp_size_comment)

      # These fields should no longer exist in inspection
      expect(inspection).not_to respond_to(:step_ramp_size)
      expect(inspection).not_to respond_to(:step_ramp_size_pass)
      expect(inspection).not_to respond_to(:step_ramp_size_comment)
    end
  end

  describe "inspection form" do
    before { visit edit_inspection_path(inspection) }

    it "no longer shows step/ramp size in the main inspection form" do
      # Should not be in the general tab anymore as a field
      expect(page).not_to have_field("inspection[step_ramp_size]")
      expect(page).not_to have_field(I18n.t("forms.inspection.fields.step_ramp_size", default: "Step/Ramp Size"))
    end
  end
end
