require "rails_helper"

RSpec.feature "User RPII Field Access Control", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :without_company) }
  let(:target_user) { create(:user, rpii_inspector_number: "RPII-123") }

  describe "Admin user access" do
    before do
      sign_in(admin_user)
    end

    it "can see RPII inspector number field when editing users" do
      visit edit_user_path(target_user)

      expect(find_form_field(:user_edit, :rpii_inspector_number).value).to eq("RPII-123")
    end

    it "can update RPII inspector number" do
      visit edit_user_path(target_user)

      fill_in_form :user_edit, :rpii_inspector_number, "RPII-456"
      submit_form :user_edit

      expect(page).to have_content(I18n.t("users.messages.user_updated"))
      target_user.reload
      expect(target_user.rpii_inspector_number).to eq("RPII-456")
    end

    it "can update RPII inspector number for existing users" do
      user_with_rpii = create(:user, rpii_inspector_number: "RPII-OLD")
      visit edit_user_path(user_with_rpii)

      expect_field_present :user_edit, :rpii_inspector_number
      fill_in_form :user_edit, :rpii_inspector_number, "RPII-789"
      submit_form :user_edit

      expect(page).to have_content(I18n.t("users.messages.user_updated"))
      user_with_rpii.reload
      expect(user_with_rpii.rpii_inspector_number).to eq("RPII-789")
    end

    it "shows RPII field in new user registration form" do
      visit new_user_path

      expect_field_present :user_new, :rpii_inspector_number
    end
  end

  describe "Regular user access" do
    before do
      sign_in(regular_user)
    end

    it "cannot see RPII inspector number field when editing their own profile" do
      visit edit_user_path(regular_user)

      expect_field_not_present :user_edit, :rpii_inspector_number
    end

    it "cannot access edit page for other users" do
      visit edit_user_path(target_user)

      expect(page).to have_current_path(root_path)
      expect(page).to have_content(I18n.t("forms.session_new.status.admin_required"))
    end

    it "cannot update RPII inspector number via form submission" do
      page.driver.submit :patch, user_path(regular_user), {
        user: {
          email: regular_user.email,
          rpii_inspector_number: "HACKED-999"
        }
      }

      regular_user.reload
      expect(regular_user.rpii_inspector_number).not_to eq("HACKED-999")
    end

    it "shows RPII field in new user registration form when logged out" do
      logout
      visit new_user_path

      expect_field_present :user_new, :rpii_inspector_number
    end
  end

  describe "Unauthenticated access" do
    it "shows RPII field in new user registration form" do
      visit new_user_path

      expect_field_present :user_new, :rpii_inspector_number
    end

    it "requires RPII data during registration" do
      visit new_user_path

      fill_in_form :user_new, :email, "newuser@example.com"
      fill_in_form :user_new, :name, "New Test User"
      fill_in_form :user_new, :rpii_inspector_number, "RPII-NEW-123"
      fill_in_form :user_new, :password, "password123"
      fill_in_form :user_new, :password_confirmation, "password123"

      submit_form :user_new

      expect(page).to have_content(I18n.t("users.messages.account_created"))

      new_user = User.find_by(email: "newuser@example.com")
      expect(new_user).to be_present
      expect(new_user.rpii_inspector_number).to eq("RPII-NEW-123")
    end

    it "allows registration without RPII number" do
      visit new_user_path

      fill_in_form :user_new, :email, "newuser@example.com"
      fill_in_form :user_new, :name, "New Test User"
      fill_in_form :user_new, :password, "password123"
      fill_in_form :user_new, :password_confirmation, "password123"

      submit_form :user_new

      expect(page).to have_content(I18n.t("users.messages.account_created"))

      new_user = User.find_by(email: "newuser@example.com")
      expect(new_user).to be_present
      expect(new_user.rpii_inspector_number).to be_nil
    end
  end
end
