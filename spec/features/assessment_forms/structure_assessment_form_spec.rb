require "rails_helper"

RSpec.feature "Structure Assessment Form", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before { sign_in(user) }

  def field_prefix
    "forms.structure.fields"
  end

  def get_label(field)
    key = "#{field_prefix}.#{field}"
    label = I18n.t(key, default: nil)
    label || I18n.t(key.gsub(/_pass$/, ""))
  end

  def choose_structure_field(field, value)
    choose_pass_fail(get_label(field), value)
  end

  def fill_structure_field(field, value)
    fill_in get_label(field), with: value.to_s
  end

  scenario "user can fill and save structure assessment form" do
    visit edit_inspection_path(inspection, tab: "structure")

    choose_structure_field :seam_integrity_pass, true
    choose_structure_field :uses_lock_stitching_pass, false
    choose_structure_field :air_loss_pass, true
    choose_structure_field :straight_walls_pass, true
    choose_structure_field :sharp_edges_pass, false
    choose_structure_field :unit_stable_pass, true

    fill_structure_field :stitch_length, "15.5"
    fill_structure_field :unit_pressure, "2.8"
    fill_structure_field :blower_tube_length, "1.75"
    fill_structure_field :evacuation_time, "45"
    fill_structure_field :critical_fall_off_height, "1.2"
    fill_structure_field :step_ramp_size, "150"
    fill_structure_field :trough_depth, "200"
    fill_structure_field :trough_adjacent_panel_width, "0.8"

    choose_structure_field :stitch_length_pass, true
    choose_structure_field :unit_pressure_pass, true
    choose_structure_field :blower_tube_length_pass, true
    choose_structure_field :evacuation_time_pass, true
    choose_structure_field :critical_fall_off_height_pass, true
    choose_structure_field :step_ramp_size_pass, true
    choose_structure_field :trough_depth_pass, true
    choose_structure_field :trough_adjacent_panel_width_pass, true
    choose_structure_field :trough_pass, true

    choose_structure_field :entrapment_pass, false
    choose_structure_field :markings_pass, true
    choose_structure_field :grounding_pass, true

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

    inspection.reload
    structure = inspection.structure_assessment
    expect(structure.incomplete_fields).to eq []
    expect(structure.complete?).to be true
  end
end
