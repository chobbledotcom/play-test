# typed: false

require "rails_helper"

RSpec.feature "User Impersonation", type: :feature do
  let(:admin) { create(:user, :admin, name: "Admin User") }
  let(:regular_user) do
    create(:user, name: "Regular User", email: "regular@example.com")
  end
  let(:other_user) { create(:user, name: "Other User") }

  background do
    # Create some test data
    create(:inspection, user: regular_user)
  end

  scenario "admin can impersonate another user" do
    # Login as admin
    login_user_via_form(admin)

    # Go to edit user page
    visit edit_user_path(regular_user)

    # Click impersonate button
    click_button I18n.t("users.buttons.impersonate", email: regular_user.email)

    # Should be redirected to root path with notice
    expect(page).to have_current_path(root_path)
    impersonating_msg = I18n.t("users.messages.impersonating",
      email: regular_user.email)
    expect(page).to have_content(impersonating_msg)

    # Should now be logged in as the regular user
    visit inspections_path
    # Check we can see stop impersonating link
    expect(page).to have_link(I18n.t("users.buttons.stop_impersonating"))

    # Should see regular user's inspections
    inspection = regular_user.inspections.first
    identifier = inspection.unique_report_number || inspection.id
    expect(page).to have_content(identifier)
  end

  scenario "admin can stop impersonating" do
    # Login as admin and impersonate
    login_user_via_form(admin)
    visit edit_user_path(regular_user)
    click_button I18n.t("users.buttons.impersonate", email: regular_user.email)

    # Should see "Stop Impersonating" link in navigation
    expect(page).to have_link(I18n.t("users.buttons.stop_impersonating"))

    # Click stop impersonating
    click_link I18n.t("users.buttons.stop_impersonating")

    # Should be back as admin
    expect(page).to have_current_path(root_path)
    expect(page).to have_content(I18n.t("users.messages.stopped_impersonating"))

    # Should not see stop impersonating link anymore
    expect(page).not_to have_link(I18n.t("users.buttons.stop_impersonating"))
  end

  scenario "regular user cannot impersonate" do
    # Login as regular user
    login_user_via_form(regular_user)

    # Try to access users page
    visit users_path
    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Admin required")

    # Try to impersonate directly via URL
    page.driver.submit :post, impersonate_user_path(other_user), {}
    expect(page).to have_current_path(root_path)
  end

  scenario "impersonation creates new session" do
    # Login as admin
    login_user_via_form(admin)

    # Check we have a session token
    admin_session = UserSession.find_by(user: admin)
    expect(admin_session).to be_present
    admin_session_id = admin_session.id

    # Impersonate
    visit edit_user_path(regular_user)
    click_button I18n.t("users.buttons.impersonate", email: regular_user.email)

    # Should create a new session for the impersonated user
    impersonated_session = UserSession.find_by(user: regular_user)
    expect(impersonated_session).to be_present

    # Original admin session should be deleted (replaced)
    expect(UserSession.find_by(id: admin_session_id)).to be_nil
  end
end
