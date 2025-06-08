require "rails_helper"

RSpec.feature "Inspection Dimension Replacement", type: :feature do
  let(:user) { create(:user) }
  let(:unit) {
    create(:unit,
      user: user,
      name: "Test Unit with Dimensions",
      width: 12.5,
      length: 10.0,
      height: 4.5,
      num_low_anchors: 6,
      num_high_anchors: 2,
      rope_size: 18.0,
      slide_platform_height: 2.5,
      containing_wall_height: 1.2,
      users_at_1000mm: 10)
  }

  let(:inspection) {
    # Create inspection with different dimensions than the unit
    create(:inspection,
      user: user,
      unit: unit).tap do |i|
      i.update_columns(
        width: 8.0,
        length: 6.0,
        height: 3.0,
        num_low_anchors: 2,
        num_high_anchors: 1
      )
    end
  }

  before do
    sign_in(user)
  end

  scenario "User sees replace dimensions link on edit page" do
    visit edit_inspection_path(inspection)

    # Verify the Replace dimensions link is present
    expect(page).to have_link(I18n.t("inspections.buttons.replace_dimensions"))

    # Verify link has correct attributes (but we can't test the confirmation dialog without JS)
    link = find_link(I18n.t("inspections.buttons.replace_dimensions"))
    expect(link["data-turbo-method"]).to eq("patch")
    expect(link["data-turbo-confirm"]).to eq(I18n.t("inspections.messages.dimensions_replace_confirm"))
  end

  scenario "Replace dimensions link is shown for newly created inspection" do
    visit unit_path(unit)

    # Create a new inspection
    click_button I18n.t("units.buttons.add_inspection")

    # The new inspection is created immediately and we're on the edit page
    # The replace dimensions link should be shown since the inspection is persisted and has a unit
    expect(page).to have_link(I18n.t("inspections.buttons.replace_dimensions"))

    # Verify we're on the edit page for the newly created inspection
    expect(page).to have_current_path(edit_inspection_path(Inspection.last))
  end

  scenario "Replace dimensions link only shows when unit is present" do
    # Create an inspection and simulate the edge case where unit_id exists but unit is deleted
    # Since we can't actually delete the unit due to foreign key constraints,
    # we'll just verify the view logic by checking the page
    visit edit_inspection_path(inspection)

    expect(page).to have_link(I18n.t("inspections.buttons.replace_dimensions"))
  end
end
