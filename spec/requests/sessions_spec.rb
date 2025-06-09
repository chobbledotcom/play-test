require "rails_helper"

# Sessions Controller Behavior Documentation
# ==========================================
#
# The Sessions controller manages user authentication with three main actions:
#
# PUBLIC ACCESS (no login required):
# - GET /login - Shows login form
# - POST /login - Authenticates user with email/password, handles remember_me
#
# AUTHENTICATED ACCESS (must be logged in):
# - DELETE /logout - Logs out user and clears session
#
# AUTHENTICATION FLOW:
# 1. User submits email/password via login form
# 2. Controller finds user by email (case insensitive) and verifies password
# 3. On success: sets session[:user_id], handles remember_me cookie, redirects to root
# 4. On failure: shows error message and re-renders form with :unprocessable_entity
#
# REMEMBER ME FUNCTIONALITY:
# - When remember_me checkbox is checked (value "1"), sets permanent signed cookie
# - When unchecked or absent, deletes any existing remember_me cookie
# - Remember me allows persistent login across browser sessions
#
# LOGOUT BEHAVIOR:
# - Clears session[:user_id] and deletes remember_me cookie
# - Shows success message and redirects to root path
#
# ERROR HANDLING:
# - Invalid credentials show "Invalid email/password combination" via flash.now
# - Failed login renders :new template with :unprocessable_entity status
# - All authentication redirects go to root_path

RSpec.describe "Sessions", type: :feature do
  let(:user) { create(:user) }

  describe "Login page" do
    it "displays the login form" do
      visit "/login"

      expect(page).to have_content(I18n.t("session.login.title"))
      expect(page).to have_field(I18n.t("session.login.email"))
      expect(page).to have_field(I18n.t("session.login.password"))
      expect(page).to have_field(I18n.t("session.login.remember_me"))
      expect(page).to have_button(I18n.t("session.login.submit"))
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

      expect(page).to have_current_path(root_path)
      expect(page).to have_content(I18n.t("session.login.success"))
    end

    it "handles case-insensitive email" do
      visit "/login"

      fill_in I18n.t("session.login.email"), with: user.email.upcase
      fill_in I18n.t("session.login.password"), with: user.password
      click_button I18n.t("session.login.submit")

      expect(page).to have_current_path(root_path)
      expect(page).to have_content(I18n.t("session.login.success"))
    end

    it "works with remember me checked" do
      visit "/login"

      fill_in I18n.t("session.login.email"), with: user.email
      fill_in I18n.t("session.login.password"), with: user.password
      check I18n.t("session.login.remember_me")
      click_button I18n.t("session.login.submit")

      expect(page).to have_current_path(root_path)
      expect(page).to have_content(I18n.t("session.login.success"))
    end

    it "works with remember me unchecked" do
      visit "/login"

      fill_in I18n.t("session.login.email"), with: user.email
      fill_in I18n.t("session.login.password"), with: user.password
      uncheck I18n.t("session.login.remember_me")
      click_button I18n.t("session.login.submit")

      expect(page).to have_current_path(root_path)
      expect(page).to have_content(I18n.t("session.login.success"))
    end

    it "allows re-login when already logged in" do
      # First login
      visit "/login"
      fill_in I18n.t("session.login.email"), with: user.email
      fill_in I18n.t("session.login.password"), with: user.password
      click_button I18n.t("session.login.submit")

      expect(page).to have_current_path(root_path)

      # Login again
      visit "/login"
      fill_in I18n.t("session.login.email"), with: user.email
      fill_in I18n.t("session.login.password"), with: user.password
      click_button I18n.t("session.login.submit")

      expect(page).to have_current_path(root_path)
      expect(page).to have_content(I18n.t("session.login.success"))
    end
  end

  describe "Failed login attempts" do
    it "shows error for wrong password" do
      visit "/login"

      fill_in I18n.t("session.login.email"), with: user.email
      fill_in I18n.t("session.login.password"), with: "wrongpassword"
      click_button I18n.t("session.login.submit")

      expect(page).to have_current_path("/login")
      expect(page).to have_content(I18n.t("session.login.error"))
    end

    it "shows error for nonexistent email" do
      visit "/login"

      fill_in I18n.t("session.login.email"), with: "nonexistent@example.com"
      fill_in I18n.t("session.login.password"), with: user.password
      click_button I18n.t("session.login.submit")

      expect(page).to have_current_path("/login")
      expect(page).to have_content(I18n.t("session.login.error"))
    end

    it "shows error for empty email" do
      visit "/login"

      fill_in I18n.t("session.login.email"), with: ""
      fill_in I18n.t("session.login.password"), with: user.password
      click_button I18n.t("session.login.submit")

      expect(page).to have_current_path("/login")
      expect(page).to have_content(I18n.t("session.login.error"))
    end

    it "shows error for empty password" do
      visit "/login"

      fill_in I18n.t("session.login.email"), with: user.email
      fill_in I18n.t("session.login.password"), with: ""
      click_button I18n.t("session.login.submit")

      expect(page).to have_current_path("/login")
      expect(page).to have_content(I18n.t("session.login.error"))
    end

    it "displays error messages immediately" do
      visit "/login"

      fill_in I18n.t("session.login.email"), with: user.email
      fill_in I18n.t("session.login.password"), with: "wrong"
      click_button I18n.t("session.login.submit")

      expect(page).to have_content(I18n.t("session.login.error"))
      expect(page).to have_current_path("/login")
    end
  end

  describe "Logout functionality" do
    context "when logged in" do
      before do
        visit "/login"
        fill_in I18n.t("session.login.email"), with: user.email
        fill_in I18n.t("session.login.password"), with: user.password
        check I18n.t("session.login.remember_me")
        click_button I18n.t("session.login.submit")
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

      # Try with non-existent email
      fill_in I18n.t("session.login.email"), with: "nonexistent@example.com"
      fill_in I18n.t("session.login.password"), with: user.password
      click_button I18n.t("session.login.submit")

      expect(page).to have_content(I18n.t("session.login.error"))

      # Try with existing email but wrong password
      fill_in I18n.t("session.login.email"), with: user.email
      fill_in I18n.t("session.login.password"), with: "wrongpassword"
      click_button I18n.t("session.login.submit")

      # Both should show the same error message
      expect(page).to have_content(I18n.t("session.login.error"))
    end

    it "normalizes email case for lookup" do
      mixed_case_email = user.email.chars.map.with_index { |c, i| i.even? ? c.upcase : c }.join

      visit "/login"
      fill_in I18n.t("session.login.email"), with: mixed_case_email
      fill_in I18n.t("session.login.password"), with: user.password
      click_button I18n.t("session.login.submit")

      expect(page).to have_current_path(root_path)
      expect(page).to have_content(I18n.t("session.login.success"))
    end
  end
end
