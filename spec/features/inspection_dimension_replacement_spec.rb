require "rails_helper"

RSpec.feature "Inspection Dimension Replacement", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, :with_comprehensive_dimensions, user: user) }
  let(:inspection) { create_inspection_with_different_dimensions }

  before do
    sign_in(user)
  end

  scenario "displays replace dimensions link on edit page" do
    visit edit_inspection_path(inspection)

    expect(page).to have_link(I18n.t("inspections.buttons.replace_dimensions"))
  end

  scenario "configures replace dimensions link with correct attributes" do
    visit edit_inspection_path(inspection)

    link = find_link(I18n.t("inspections.buttons.replace_dimensions"))
    expect(link["data-turbo-method"]).to eq("patch")
    expect(link["data-turbo-confirm"]).to eq(I18n.t("inspections.messages.dimensions_replace_confirm"))
  end

  scenario "shows replace dimensions link for newly created inspection" do
    visit unit_path(unit)
    click_button I18n.t("units.buttons.add_inspection")

    expect(page).to have_link(I18n.t("inspections.buttons.replace_dimensions"))
    expect_to_be_on_inspection_edit_page
  end

  scenario "shows replace dimensions link when unit is present" do
    visit edit_inspection_path(inspection)

    expect(page).to have_link(I18n.t("inspections.buttons.replace_dimensions"))
  end

  private

  def create_inspection_with_different_dimensions
    create(:inspection, user: user, unit: unit).tap do |inspection|
      inspection.update_columns(
        width: 8.0,
        length: 6.0,
        height: 3.0,
        num_low_anchors: 2,
        num_high_anchors: 1
      )
    end
  end

  def expect_to_be_on_inspection_edit_page
    new_inspection = user.inspections.find_by(unit_id: unit.id)
    expect(new_inspection).to be_present
    expect(page).to have_current_path(edit_inspection_path(new_inspection))
  end
end
