require "rails_helper"

RSpec.feature "Logout Everywhere Else", type: :feature do
  let(:user) { create(:user, password: "password123") }

  scenario "user can log out all other sessions" do
    # First login session
    visit login_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button I18n.t("forms.session_new.submit")

    expect(page).to have_current_path(inspections_path)

    # Simulate second login from different browser/device
    # We'll use Capybara's using_session to simulate this
    using_session :second_browser do
      visit login_path
      fill_in "Email", with: user.email
      fill_in "Password", with: "password123"
      click_button I18n.t("forms.session_new.submit")

      expect(page).to have_current_path(inspections_path)
    end

    # Verify we have 2 active sessions
    expect(user.user_sessions.count).to eq(2)

    # Go to settings and click logout everywhere else
    visit change_settings_user_path(user)

    # Expand the sessions section
    find("summary", text: I18n.t("users.sessions.title")).click

    # Click logout everywhere else
    click_button I18n.t("users.sessions.logout_everywhere_else")

    # Should see success message
    expect(page).to have_content(
      I18n.t("users.messages.logged_out_everywhere")
    )

    # Current session should still work
    visit inspections_path
    expect(page).to have_current_path(inspections_path)

    # But the other session should be logged out
    using_session :second_browser do
      visit inspections_path
      # Should be redirected to login
      expect(page).to have_current_path(login_path)
      expect(page).to have_content(
        I18n.t("forms.session_new.status.login_required")
      )
    end

    # Verify only 1 session remains
    expect(user.user_sessions.count).to eq(1)
  end

  scenario "displays active sessions in settings" do
    # Create a session
    visit login_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button I18n.t("forms.session_new.submit")

    # Go to settings
    visit change_settings_user_path(user)

    # Expand sessions section
    find("summary", text: I18n.t("users.sessions.title")).click

    # Should see session details
    within "table" do
      expect(page).to have_content("127.0.0.1") # IP address
      expect(page).to have_content(
        I18n.t("users.sessions.current")
      )
    end
  end
end
