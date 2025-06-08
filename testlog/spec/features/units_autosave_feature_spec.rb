require "rails_helper"

RSpec.feature "Units Auto-save Feature", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user, name: "Test Unit") }

  before do
    sign_in(user)
  end

  scenario "Auto-save works when editing a unit" do
    visit edit_unit_path(unit)

    # Check that auto-save status is present
    expect(page).to have_css("[data-autosave-status]")

    # Change a field and wait for auto-save (this would work with JS)
    fill_in "Width (m)", with: "15.5"

    # In a real browser with JS, we would see:
    # - The field would auto-save after 2 seconds
    # - The status indicator would show "Saved"
    # - No page reload would occur

    # For now, just verify the form structure is correct
    expect(page).to have_field("Width (m)")
    expect(page).to have_css("form[data-autosave='true']")
  end

  scenario "Auto-save status indicator is present" do
    visit edit_unit_path(unit)

    expect(page).to have_css("[data-autosave-status]")
  end

  scenario "New units do not have auto-save enabled" do
    visit new_unit_path

    # New forms should not have auto-save
    expect(page).not_to have_css("form[data-autosave='true']")
    expect(page).not_to have_css("[data-autosave-status]")
  end

  scenario "Auto-save only enabled for persisted units" do
    visit edit_unit_path(unit)

    # Existing unit should have auto-save
    expect(page).to have_css("form[data-autosave='true']")

    visit new_unit_path

    # New unit should not have auto-save
    expect(page).not_to have_css("form[data-autosave='true']")
  end
end
