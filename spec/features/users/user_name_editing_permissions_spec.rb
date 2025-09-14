# typed: false

require "rails_helper"

RSpec.feature "User Name Editing Permissions", type: :feature do
  include InspectionTestHelpers
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :without_company, email: "user@example.com", name: "Original Name") }
  let!(:inspector_company) { create(:inspector_company, active: true) }

  describe "Admin name editing permissions" do
    before { sign_in admin_user }

    scenario "Admin can edit user names through admin edit form" do
      visit edit_user_path(regular_user)

      expect_field_present(:user_edit, :name)
      expect(find_form_field(:user_edit, :name).value).to eq("Original Name")

      fill_in_form(:user_edit, :name, "New Admin Changed Name")
      submit_form(:user_edit)

      expect(page).to have_content(I18n.t("users.messages.user_updated"))

      regular_user.reload
      expect(regular_user.name).to eq("New Admin Changed Name")
    end

    scenario "Admin edit form includes all admin-only fields" do
      visit edit_user_path(regular_user)

      expect_field_present(:user_edit, :name)
      expect_field_present(:user_edit, :email)
      expect_field_present(:user_edit, :rpii_inspector_number)

      if ENV["SIMPLE_USER_ACTIVATION"] == "true"
        # Check for activation status display instead of field
        expect(page).to have_content(I18n.t("users.labels.activated_at")) ||
          have_content(I18n.t("users.labels.deactivated_at"))
      else
        expect_field_present(:user_edit, :active_until)
      end

      expect_field_present(:user_edit, :inspection_company_id)
    end
  end

  describe "Regular user name editing restrictions" do
    before { sign_in regular_user }

    scenario "Regular user cannot access admin edit form" do
      visit edit_user_path(regular_user)

      expect(page).to have_content(I18n.t("forms.session_new.status.admin_required"))
      expect(current_path).to eq(root_path)
    end

    scenario "Regular user cannot edit name in settings form" do
      visit change_settings_user_path(regular_user)

      expect(page).to have_content("Original Name")
      expect_field_not_present(:user_settings, :name)

      expect_field_present(:user_settings, :phone)
      expect_field_present(:user_settings, :address)
      expect_field_present(:user_settings, :country)
      expect_field_present(:user_settings, :postal_code)
    end

    scenario "Regular user with company sees all fields as read-only" do
      regular_user.update!(inspection_company: inspector_company)
      visit change_settings_user_path(regular_user)

      expect(page).to have_content("Original Name")
      expect_field_not_present(:user_settings, :name)
      expect_field_not_present(:user_settings, :phone)
      expect_field_not_present(:user_settings, :address)
      expect_field_not_present(:user_settings, :country)
      expect_field_not_present(:user_settings, :postal_code)

      expect(page).to have_content(I18n.t("users.messages.inherited_from_company"))
    end

    scenario "Regular user can still edit preferences but not name" do
      visit change_settings_user_path(regular_user)

      # Theme field is only shown if forced_theme is not set
      if Rails.configuration.forced_theme.blank?
        expect_field_present(:user_settings, :theme)

        theme_field = I18n.t("forms.user_settings.fields.theme")
        select I18n.t("users.options.theme_dark"), from: theme_field
        submit_form(:user_settings)

        expect(page).to have_content(I18n.t("users.messages.settings_updated"))

        regular_user.reload
        expect(regular_user.theme).to eq("dark")
      else
        # When theme is set via ENV, just verify we can access settings page
        expect(page).to have_content(I18n.t("forms.user_settings.header"))
      end

      expect(regular_user.name).to eq("Original Name")
    end
  end
end
