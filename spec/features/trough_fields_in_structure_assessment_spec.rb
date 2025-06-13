require "rails_helper"

RSpec.feature "Trough Fields in Structure Assessment", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before { sign_in(user) }

  describe "structure assessment form" do
    before { visit edit_inspection_path(inspection) }

    it "shows trough fields in structure tab" do
      click_link I18n.t("inspections.tabs.structure")

      # Just verify the labels are visible
      expect(page).to have_content("Trough Depth")
      expect(page).to have_content("Trough Adjacent Panel Width")
    end

    it "saves trough field values" do
      visit edit_inspection_path(inspection, tab: "structure")

      # Use i18n to find fields
      fill_in I18n.t("forms.structure.fields.trough_depth"), with: "150"
      fill_in I18n.t("forms.structure.fields.trough_adjacent_panel_width"), with: "75"

      # Submit form
      click_button I18n.t("forms.structure.submit")

      # Verify redirect and success message
      expect(page).to have_content(I18n.t("inspections.messages.updated"))

      # Verify values were saved
      inspection.reload
      expect(inspection.structure_assessment.trough_depth).to eq(150.0)
      expect(inspection.structure_assessment.trough_adjacent_panel_width).to eq(75.0)
    end
  end

  describe "data migration" do
    it "moves trough fields from inspections to structure assessments" do
      # This test verifies that the migration worked correctly
      structure_assessment = inspection.structure_assessment

      # These fields should exist in structure_assessment
      expect(structure_assessment).to respond_to(:trough_depth)
      expect(structure_assessment).to respond_to(:trough_depth_pass)
      expect(structure_assessment).to respond_to(:trough_adjacent_panel_width)
      expect(structure_assessment).to respond_to(:trough_adjacent_panel_width_pass)
      expect(structure_assessment).to respond_to(:trough_adjacent_panel_width_comment)

      # These fields should no longer exist in inspection
      expect(inspection).not_to respond_to(:trough_depth)
      expect(inspection).not_to respond_to(:trough_adjacent_panel_width)
    end
  end
end
