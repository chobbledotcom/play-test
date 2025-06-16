require "rails_helper"

RSpec.feature "Structure Assessment Form", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before { sign_in(user) }

  scenario "user can fill and save structure assessment form" do
    visit edit_inspection_path(inspection, tab: "structure")

    choose "seam_integrity_pass_true"
    choose "uses_lock_stitching_pass_false"
    choose "air_loss_pass_true"
    choose "straight_walls_pass_true"
    choose "sharp_edges_pass_false"
    choose "unit_stable_pass_true"

    fill_in "Stitch Length", with: "15.5"
    fill_in "Unit Pressure", with: "2.8"
    fill_in "Blower Tube Length", with: "1.75"

    choose "stitch_length_pass_true"
    choose "unit_pressure_pass_true"
    choose "blower_tube_length_pass_true"

    choose "entrapment_pass_false"
    choose "markings_pass_true"
    choose "grounding_pass_true"

    click_button I18n.t("forms.structure.submit")

    expect_updated_message

    inspection.reload
    structure = inspection.structure_assessment

    expect(structure.seam_integrity_pass).to be true
    expect(structure.uses_lock_stitching_pass).to be false
    expect(structure.air_loss_pass).to be true
    expect(structure.straight_walls_pass).to be true
    expect(structure.sharp_edges_pass).to be false
    expect(structure.unit_stable_pass).to be true

    expect(structure.stitch_length).to eq(15.5)
    expect(structure.unit_pressure).to eq(2.8)
    expect(structure.blower_tube_length).to eq(1.75)

    expect(structure.stitch_length_pass).to be true
    expect(structure.unit_pressure_pass).to be true
    expect(structure.blower_tube_length_pass).to be true

    expect(structure.entrapment_pass).to be false
    expect(structure.markings_pass).to be true
    expect(structure.grounding_pass).to be true
  end
end
