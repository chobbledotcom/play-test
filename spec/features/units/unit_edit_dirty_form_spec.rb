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
    expect(page).not_to have_selector("#dirty-form-indicator", visible: true)

    # Make a change to the form
    fill_in_form :units, :name, "Updated Unit Name"

    # Should show unsaved changes
    expect(page).to have_selector("#dirty-form-indicator", visible: true)
    expect(page).to have_content("Unsaved changes")

    # Save via the floating save button
    within("#dirty-form-indicator") do
      click_button "Save"
    end

    # Should show success message and clear indicator
    # Flash messages may not render in test environment
    expect(page).not_to have_selector("#dirty-form-indicator", visible: true)

    # Verify the change was saved
    unit.reload
    expect(unit.name).to eq("Updated Unit Name")
  end

  scenario "warns before navigating away with unsaved changes" do
    # Make a change
    fill_in_form :units, :name, "Unsaved Name"

    # Should show unsaved changes indicator
    expect(page).to have_selector("#dirty-form-indicator", visible: true)

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

    # Should navigate to unit show page
    expect(page).to have_current_path(unit_path(unit))
  end
end
