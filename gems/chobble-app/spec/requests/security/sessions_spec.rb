require "rails_helper"

RSpec.describe "Sessions", type: :feature do
  let(:user) { create(:user) }

  describe "Login page" do
    it "displays the login form" do
      visit "/login"

      expect_form_matches_i18n("forms.session_new")
    end

    it "is accessible without authentication" do
      visit "/login"

      expect(page).to have_current_path("/login")
      expect(page).to have_content(I18n.t("session.login.title"))
    end
  end

  describe "Successful login" do
    it "authenticates user and redirects to root" do
      login_user_via_form(user)

      expect(page).to have_current_path(inspections_path)
      expect(page).to have_content(I18n.t("session.login.success"))
    end

    it "handles case-insensitive email" do
      visit "/login"

      fill_in_form :session_new, :email, user.email.upcase
      fill_in_form :session_new, :password, user.password
      submit_form :session_new

      expect(page).to have_current_path(inspections_path)
      expect(page).to have_content(I18n.t("session.login.success"))
    end

    it "works with remember me checked" do
      visit "/login"

      fill_in_form :session_new, :email, user.email
      fill_in_form :session_new, :password, user.password
      check_form :session_new, :remember_me
      submit_form :session_new

      expect(page).to have_current_path(inspections_path)
      expect(page).to have_content(I18n.t("session.login.success"))
    end

    it "works with remember me unchecked" do
      visit "/login"

      fill_in_form :session_new, :email, user.email
      fill_in_form :session_new, :password, user.password
      uncheck_form :session_new, :remember_me
      submit_form :session_new

      expect(page).to have_current_path(inspections_path)
      expect(page).to have_content(I18n.t("session.login.success"))
    end

    it "redirects to inspections page when already logged in" do
      # First login
      visit "/login"
      fill_in_form :session_new, :email, user.email
      fill_in_form :session_new, :password, user.password
      submit_form :session_new

      expect(page).to have_current_path(inspections_path)

      # Try to visit login page again while logged in
      visit "/login"

      # Should redirect to inspections page
      expect(page).to have_current_path(inspections_path)
      expect(page).to have_content(I18n.t("forms.session_new.status.already_logged_in"))
    end
  end

  describe "Failed login attempts" do
    it "shows error for wrong password" do
      visit "/login"

      fill_in_form :session_new, :email, user.email
      fill_in_form :session_new, :password, "wrongpassword"
      submit_form :session_new

      expect(page).to have_current_path("/login")
      expect(page).to have_content(I18n.t("session.login.error"))
    end

    it "shows error for nonexistent email" do
      visit "/login"

      fill_in_form :session_new, :email, "nonexistent@example.com"
      fill_in_form :session_new, :password, user.password
      submit_form :session_new

      expect(page).to have_current_path("/login")
      expect(page).to have_content(I18n.t("session.login.error"))
    end

    it "shows error for empty email" do
      visit "/login"

      fill_in_form :session_new, :email, ""
      fill_in_form :session_new, :password, user.password
      submit_form :session_new

      expect(page).to have_current_path("/login")
      expect(page).to have_content(I18n.t("session.login.error"))
    end

    it "shows error for empty password" do
      visit "/login"

      fill_in_form :session_new, :email, user.email
      fill_in_form :session_new, :password, ""
      submit_form :session_new

      expect(page).to have_current_path("/login")
      expect(page).to have_content(I18n.t("session.login.error"))
    end

    it "displays error messages immediately" do
      visit "/login"

      fill_in_form :session_new, :email, user.email
      fill_in_form :session_new, :password, "wrong"
      submit_form :session_new

      expect(page).to have_content(I18n.t("session.login.error"))
      expect(page).to have_current_path("/login")
    end
  end

  describe "Logout functionality" do
    context "when logged in" do
      before do
        visit "/login"
        fill_in_form :session_new, :email, user.email
        fill_in_form :session_new, :password, user.password
        check_form :session_new, :remember_me
        submit_form :session_new
      end

      it "logs out user and redirects to root" do
        click_button I18n.t("sessions.buttons.log_out")

        expect(page).to have_current_path(root_path)
        expect(page).to have_content(I18n.t("session.logout.success"))
        expect(page).not_to have_button(I18n.t("sessions.buttons.log_out"))
      end

      it "removes navigation when logged out" do
        click_button I18n.t("sessions.buttons.log_out")

        expect(page).not_to have_link(I18n.t("navigation.inspections"))
        expect(page).not_to have_link(I18n.t("navigation.units"))
        expect(page).not_to have_link(I18n.t("navigation.settings"))
      end
    end

    context "when accessing logout directly" do
      it "redirects successfully even when not logged in" do
        page.driver.submit :delete, "/logout", {}

        expect(page).to have_current_path(root_path)
        expect(page).to have_content(I18n.t("session.logout.success"))
      end
    end
  end

  describe "Security and edge cases" do
    it "does not reveal whether email exists" do
      visit "/login"

      fill_in_form :session_new, :email, "nonexistent@example.com"
      fill_in_form :session_new, :password, user.password
      submit_form :session_new

      expect(page).to have_content(I18n.t("session.login.error"))

      fill_in_form :session_new, :email, user.email
      fill_in_form :session_new, :password, "wrongpassword"
      submit_form :session_new

      expect(page).to have_content(I18n.t("session.login.error"))
    end

    it "normalizes email case for lookup" do
      mixed_case_email =
        user.email.chars.map.with_index { |c, i| i.even? ? c.upcase : c }.join

      visit "/login"
      fill_in_form :session_new, :email, mixed_case_email
      fill_in_form :session_new, :password, user.password
      submit_form :session_new

      expect(page).to have_current_path(inspections_path)
      expect(page).to have_content(I18n.t("session.login.success"))
    end
  end
end
