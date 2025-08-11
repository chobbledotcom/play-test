# typed: false

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

      expect(page).to have_content("Trough Depth")
      expect(page).to have_content("Trough Adjacent Panel Width")
    end

    it "saves trough field values" do
      visit edit_inspection_path(inspection, tab: "structure")

      fill_in_form :structure, :trough_depth, "150"
      fill_in_form :structure, :trough_adjacent_panel_width, "75"

      submit_form :structure

      expect_updated_message

      inspection.reload
      expect(inspection.structure_assessment.trough_depth).to eq(150)
      width = inspection.structure_assessment.trough_adjacent_panel_width
      expect(width).to eq(75)
    end
  end

  describe "data migration" do
    it "moves trough fields from inspections to structure assessments" do
      structure_assessment = inspection.structure_assessment

      expect(structure_assessment).to respond_to(:trough_depth)
      expect(structure_assessment).to respond_to(:trough_adjacent_panel_width)
      comment_field = :trough_adjacent_panel_width_comment
      expect(structure_assessment).to respond_to(comment_field)

      expect(inspection).not_to respond_to(:trough_depth)
      expect(inspection).not_to respond_to(:trough_adjacent_panel_width)
    end
  end
end
