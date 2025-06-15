require "rails_helper"

RSpec.feature "Inspection Conditional Fields", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, unit: unit, user: user) }

  before do
    sign_in(user)
  end

  scenario "saves is_totally_enclosed field when creating inspection" do
    # Create inspection from unit page
    visit unit_path(unit)
    click_button I18n.t("units.buttons.add_inspection")

    # Should be on edit inspection page for the new inspection
    expect(page).to have_content(I18n.t("inspections.titles.edit"))

    # Choose "Yes" for the "Is totally enclosed" radio button
    check_radio I18n.t("forms.inspections.fields.is_totally_enclosed")

    # Save the inspection
    click_button I18n.t("forms.inspections.submit")

    # After save, we should be on the show page
    expect(page).to have_content("Inspection updated successfully")

    # Verify it was saved
    created_inspection = unit.inspections.last
    expect(created_inspection.is_totally_enclosed).to be true

    # Go back to edit page using the Update Inspection link
    click_link "Update Inspection"

    # Now we should see the enclosed tab
    expect(page).to have_link(I18n.t("forms.enclosed.header"))
  end

  scenario "saves has_slide field when creating inspection" do
    # Create inspection from unit page
    visit unit_path(unit)
    click_button I18n.t("units.buttons.add_inspection")

    # Should be on edit inspection page for the new inspection
    expect(page).to have_content(I18n.t("inspections.titles.edit"))

    # Choose "Yes" for the "Has slide" radio button
    check_radio I18n.t("forms.inspections.fields.has_slide")

    # Save the inspection
    click_button I18n.t("forms.inspections.submit")

    # After save, we should be on the show page
    expect(page).to have_content("Inspection updated successfully")

    # Verify it was saved
    created_inspection = unit.inspections.last
    expect(created_inspection.has_slide).to be true

    # Go back to edit page using the Update Inspection link
    click_link "Update Inspection"

    # Now we should see the slide tab
    expect(page).to have_link(I18n.t("forms.slide.header"))
  end

  scenario "updates is_totally_enclosed field on existing inspection" do
    # Start with a regular inspection (no default value means nil)
    expect(inspection.is_totally_enclosed).to be_nil

    visit edit_inspection_path(inspection)

    # Should not see enclosed tab initially
    expect(page).not_to have_link(I18n.t("forms.enclosed.header"))

    # Choose "Yes" for the radio button
    check_radio I18n.t("forms.inspections.fields.is_totally_enclosed")

    # Save the inspection
    click_button I18n.t("forms.inspections.submit")

    # Verify it was saved
    inspection.reload
    expect(inspection.is_totally_enclosed).to be true

    # Go back to edit page
    visit edit_inspection_path(inspection)

    # Now should see enclosed tab
    expect(page).to have_link(I18n.t("forms.enclosed.header"))
  end

  scenario "updates has_slide field on existing inspection" do
    # Start with a non-slide inspection (no default value means nil)
    expect(inspection.has_slide).to be_nil

    visit edit_inspection_path(inspection)

    # Should not see slide tab initially
    expect(page).not_to have_link(I18n.t("forms.slide.header"))

    # Choose "Yes" for the radio button
    check_radio I18n.t("forms.inspections.fields.has_slide")

    # Save the inspection
    click_button I18n.t("forms.inspections.submit")

    # Verify it was saved
    inspection.reload
    expect(inspection.has_slide).to be true

    # Go back to edit page
    visit edit_inspection_path(inspection)

    # Now should see slide tab
    expect(page).to have_link(I18n.t("forms.slide.header"))
  end

  scenario "saves both conditional fields together" do
    # Create inspection from unit page
    visit unit_path(unit)
    click_button I18n.t("units.buttons.add_inspection")

    # Should be on edit inspection page for the new inspection
    expect(page).to have_content(I18n.t("inspections.titles.edit"))

    # Choose "Yes" for both radio buttons
    check_radio I18n.t("forms.inspections.fields.is_totally_enclosed")
    check_radio I18n.t("forms.inspections.fields.has_slide")

    # Save the inspection
    click_button I18n.t("forms.inspections.submit")

    # After save, we should be on the show page
    expect(page).to have_content("Inspection updated successfully")

    # Verify both were saved
    created_inspection = unit.inspections.last
    expect(created_inspection.is_totally_enclosed).to be true
    expect(created_inspection.has_slide).to be true

    # Go back to edit page using the Update Inspection link
    click_link "Update Inspection"

    # Now we should see both tabs
    expect(page).to have_link(I18n.t("forms.enclosed.header"))
    expect(page).to have_link(I18n.t("forms.slide.header"))
  end

  scenario "unchecking removes conditional tabs" do
    # Create inspection with both fields true
    totally_enclosed_slide_inspection = create(:inspection,
      unit: unit,
      user: user,
      is_totally_enclosed: true,
      has_slide: true)

    visit edit_inspection_path(totally_enclosed_slide_inspection)

    # Should see both tabs
    expect(page).to have_link(I18n.t("forms.enclosed.header"))
    expect(page).to have_link(I18n.t("forms.slide.header"))

    # Choose "No" for both radio buttons
    uncheck_radio I18n.t("forms.inspections.fields.is_totally_enclosed")
    uncheck_radio I18n.t("forms.inspections.fields.has_slide")

    # Save
    click_button I18n.t("forms.inspections.submit")

    # Verify they were saved as false
    totally_enclosed_slide_inspection.reload
    expect(totally_enclosed_slide_inspection.is_totally_enclosed).to be false
    expect(totally_enclosed_slide_inspection.has_slide).to be false

    # Go back to edit page
    visit edit_inspection_path(totally_enclosed_slide_inspection)

    # Should not see either tab
    expect(page).not_to have_link(I18n.t("forms.enclosed.header"))
    expect(page).not_to have_link(I18n.t("forms.slide.header"))
  end
end
