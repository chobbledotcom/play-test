require "rails_helper"

RSpec.feature "Unit edit dirty form", js: true do
  include FormHelpers

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before do
    sign_in(user)
    visit edit_unit_path(unit)
  end

  scenario "tracks form changes and clears unsaved indicator after save" do
    # Initially no unsaved changes indicator
    expect(page).not_to have_css("#dirty-form-indicator", visible: true)

    # Make a change to the form
    fill_in_form :units, :name, "Updated Unit Name"

    # Should show unsaved changes
    expect(page).to have_css("#dirty-form-indicator", visible: true)
    expect(page).to have_content("Unsaved changes")

    # Save via the floating save button
    within("#dirty-form-indicator") do
      click_button "Save"
    end

    # Should show success message
    expect(page).to have_content(I18n.t("units.messages.updated"))

    # Unsaved changes indicator should be hidden
    expect(page).not_to have_css("#dirty-form-indicator", visible: true)

    # Verify the change was saved
    unit.reload
    expect(unit.name).to eq("Updated Unit Name")
  end

  scenario "clears unsaved indicator when submitting via form submit button" do
    # Make a change
    fill_in_form :units, :name, "Another Updated Name"

    # Should show unsaved changes
    expect(page).to have_css("#dirty-form-indicator", visible: true)

    # Save via the form's submit button
    submit_form :units

    # Should show success message
    expect(page).to have_content(I18n.t("units.messages.updated"))

    # Unsaved changes indicator should be hidden
    expect(page).not_to have_css("#dirty-form-indicator", visible: true)
  end

  scenario "clears unsaved indicator when saving clears the form state" do
    # Make a change
    fill_in_form :units, :name, "Name Before Save"

    # Should show unsaved changes
    expect(page).to have_css("#dirty-form-indicator", visible: true)

    # Save the form
    submit_form :units

    # Wait for success message
    expect(page).to have_content(I18n.t("units.messages.updated"))

    # Unsaved changes indicator should be hidden
    expect(page).not_to have_css("#dirty-form-indicator", visible: true)

    # Now make another change to verify the form tracking was reset
    fill_in_form :units, :name, "Name After Save"

    # Should show unsaved changes again
    expect(page).to have_css("#dirty-form-indicator", visible: true)

    # Navigate away - should get warning for the new unsaved changes
    dismiss_confirm do
      visit units_path
    end

    # Should still be on edit page
    expect(page).to have_current_path(edit_unit_path(unit))
  end

  scenario "warns before navigating away with unsaved changes" do
    # Make a change
    fill_in_form :units, :name, "Unsaved Name"

    # Try to navigate away - dismiss the confirm dialog
    dismiss_confirm do
      click_link I18n.t("units.buttons.view")
    end

    # Should still be on edit page
    expect(page).to have_current_path(edit_unit_path(unit))

    # Accept the confirm dialog this time
    accept_confirm do
      click_link I18n.t("units.buttons.view")
    end

    # Should navigate to unit show page (the anchor might not be in current_path)
    expect(page).to have_current_path(unit_path(unit))
  end
end
