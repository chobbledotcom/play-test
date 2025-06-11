require "rails_helper"

RSpec.feature "User Name Editing Permissions", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :without_company, email: "user@example.com", name: "Original Name") }
  let!(:inspector_company) { create(:inspector_company, active: true) }

  describe "Admin name editing permissions" do
    before { sign_in admin_user }

    scenario "Admin can edit user names through admin edit form" do
      visit edit_user_path(regular_user)

      expect(page).to have_field("user_name")
      expect(page).to have_field("user_name", with: "Original Name")

      fill_in "user_name", with: "New Admin Changed Name"
      click_button I18n.t("users.buttons.update_user")

      expect(page).to have_content(I18n.t("users.messages.user_updated"))

      regular_user.reload
      expect(regular_user.name).to eq("New Admin Changed Name")
    end

    scenario "Admin edit form includes all admin-only fields" do
      visit edit_user_path(regular_user)

      # Admin-only fields should be present
      expect(page).to have_field("user_name")
      expect(page).to have_field("user_email")
      expect(page).to have_field("user_rpii_inspector_number")
      expect(page).to have_field("user_active_until")
      expect(page).to have_select("user_inspection_company_id")
    end
  end

  describe "Regular user name editing restrictions" do
    before { sign_in regular_user }

    scenario "Regular user cannot access admin edit form" do
      visit edit_user_path(regular_user)

      expect(page).to have_content(I18n.t("inspector_companies.messages.unauthorized"))
      expect(current_path).to eq(root_path)
    end

    scenario "Regular user cannot edit name in settings form" do
      visit change_settings_user_path(regular_user)

      # Name should be displayed as read-only
      expect(page).to have_content("Original Name")
      expect(page).not_to have_field("user_name")

      # Other editable fields should be present for users without company
      expect(page).to have_field("user_phone")
      expect(page).to have_field("user_address")
      expect(page).to have_field("user_country")
      expect(page).to have_field("user_postal_code")
    end

    scenario "Regular user with company sees all fields as read-only" do
      regular_user.update!(inspection_company: inspector_company)
      visit change_settings_user_path(regular_user)

      # All contact details should be read-only for users with company
      expect(page).to have_content("Original Name")
      expect(page).not_to have_field("user_name")
      expect(page).not_to have_field("user_phone")
      expect(page).not_to have_field("user_address")
      expect(page).not_to have_field("user_country")
      expect(page).not_to have_field("user_postal_code")

      expect(page).to have_content(I18n.t("users.messages.inherited_from_company"))
    end

    scenario "Regular user can still edit preferences but not name" do
      visit change_settings_user_path(regular_user)

      # Should be able to edit preferences
      expect(page).to have_select("user_time_display")
      expect(page).to have_field("user_default_inspection_location")
      expect(page).to have_select("user_theme")

      # Update preferences
      select I18n.t("users.options.time_full"), from: "user_time_display"
      fill_in "user_default_inspection_location", with: "Test Location"
      click_button I18n.t("users.buttons.update_settings")

      expect(page).to have_content(I18n.t("users.messages.settings_updated"))

      regular_user.reload
      expect(regular_user.time_display).to eq("time")
      expect(regular_user.default_inspection_location).to eq("Test Location")
      # Name should remain unchanged
      expect(regular_user.name).to eq("Original Name")
    end
  end
end
