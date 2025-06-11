require "rails_helper"

RSpec.feature "Unit creation company restriction", type: :feature do
  context "when user has an inspection company" do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    scenario "user can see the new unit button and create units" do
      visit units_path

      # Should see the new unit button
      expect(page).to have_button(I18n.t("units.buttons.add_unit"))

      # Click the button
      click_button I18n.t("units.buttons.add_unit")

      # Should be on the new unit page
      expect(page).to have_current_path(new_unit_path)
      expect(page).to have_content(I18n.t("units.titles.new"))

      # Fill in the form
      fill_in I18n.t("units.forms.name"), with: "Test Unit"
      fill_in I18n.t("units.forms.serial"), with: "TEST123"
      fill_in I18n.t("units.forms.manufacturer"), with: "Test Manufacturer"
      fill_in I18n.t("units.forms.owner"), with: "Test Owner"
      fill_in I18n.t("units.forms.description"), with: "Test Description"
      fill_in I18n.t("units.forms.width"), with: "10"
      fill_in I18n.t("units.forms.length"), with: "10"
      fill_in I18n.t("units.forms.height"), with: "3"

      # Submit the form
      click_button I18n.t("units.buttons.create")

      # Should be redirected to unit show page with success message
      expect(page).to have_content(I18n.t("units.messages.created"))
      expect(page).to have_content("Test Unit")
    end
  end

  context "when user is inactive" do
    let(:inactive_user) { create(:user, :inactive_user) }

    before do
      sign_in(inactive_user)
    end

    scenario "user cannot see the new unit button" do
      visit units_path

      # Should NOT see the new unit button
      expect(page).not_to have_link(I18n.t("units.titles.new"), href: new_unit_path)
    end

    scenario "user is redirected when trying to access new unit page directly" do
      # Try to access the new unit page directly
      visit new_unit_path

      # Should be redirected to units index with an error message
      expect(page).to have_current_path(units_path)
      expect(page).to have_content(inactive_user.inactive_user_message)
    end

    scenario "user cannot create a unit via POST request" do
      # Attempt to create a unit by posting to the create action
      # This tests that the controller protection works even if someone tries to bypass the UI
      page.driver.submit :post, units_path, {
        unit: {
          name: "Test Unit",
          serial: "TEST123",
          manufacturer: "Test Manufacturer",
          owner: "Test Owner",
          description: "Test Description",
          width: "10",
          length: "10",
          height: "3"
        }
      }

      # Should be redirected with error message
      expect(page).to have_current_path(units_path)
      expect(page).to have_content(inactive_user.inactive_user_message)

      # Verify no unit was created for this user
      expect(inactive_user.units.reload.count).to eq(0)
    end
  end

  context "when user's company is archived" do
    let(:archived_company) { create(:inspector_company, active: false) }
    let(:user_with_archived_company) { create(:user, :active_user, inspection_company: archived_company) }

    before do
      sign_in(user_with_archived_company)
    end

    scenario "user can still see and create units (only inspection creation is blocked)" do
      visit units_path

      # Should see the new unit button (units are not restricted by company active status)
      expect(page).to have_button(I18n.t("units.buttons.add_unit"))
    end
  end

  context "switching between active and inactive users" do
    let(:admin_user) { create(:user, :admin, :without_company) }
    let(:active_user) { create(:user, :active_user) }
    let(:inactive_user) { create(:user, :inactive_user) }


    scenario "button visibility changes based on user's active status" do
      # Start as active user
      sign_in(active_user)
      visit units_path
      expect(page).to have_button(I18n.t("units.buttons.add_unit"))

      # Switch to inactive user
      visit logout_path
      sign_in(inactive_user)
      visit units_path
      expect(page).not_to have_button(I18n.t("units.buttons.add_unit"))

      # Admin makes first user inactive
      visit logout_path
      sign_in(admin_user)
      visit edit_user_path(active_user)
      fill_in "user_active_until", with: (Date.current - 1.day).strftime("%Y-%m-%d")
      click_button I18n.t("users.buttons.update_user")

      # Now first user should not see the button
      visit logout_path
      sign_in(active_user)
      visit units_path
      expect(page).not_to have_button(I18n.t("units.buttons.add_unit"))
    end
  end
end
