require "rails_helper"

RSpec.feature "Admin manages user active status", type: :feature do
  let(:admin_user) { create(:user, :without_company, email: "admin@example.com") }
  let(:inspector_company) { create(:inspector_company, name: "Test Company") }
  let(:regular_user) { create(:user, :active_user, email: "user@example.com", inspection_company: inspector_company) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_EMAILS_PATTERN").and_return("admin@")
    sign_in(admin_user)
  end

  scenario "admin can set user as inactive" do
    # Verify user starts as active
    expect(regular_user.is_active?).to be true
    expect(regular_user.can_create_inspection?).to be true

    # Visit user edit page
    visit edit_user_path(regular_user)

    # Set active until date to yesterday (making user inactive)
    fill_in "user_active_until", with: (Date.current - 1.day).strftime("%Y-%m-%d")

    # Select "No Company"
    select I18n.t("users.forms.no_company"), from: I18n.t("users.forms.inspection_company_id")

    # Submit the form
    click_button I18n.t("users.buttons.update_user")

    # Check for success message
    expect(page).to have_content(I18n.t("users.messages.user_updated"))

    # Verify the user is now inactive
    regular_user.reload
    expect(regular_user.active_until).to eq(Date.current - 1.day)
    expect(regular_user.is_active?).to be false
    expect(regular_user.can_create_inspection?).to be false
  end

  scenario "admin sees all company options including 'No Company'" do
    create(:inspector_company, name: "Another Company")

    visit edit_user_path(regular_user)

    # Check that all options are available
    select_element = find("select[name='user[inspection_company_id]']")
    options = select_element.all("option").map(&:text)

    expect(options).to include(I18n.t("users.forms.no_company"))
    expect(options).to include("Test Company")
    expect(options).to include("Another Company")
  end

  scenario "non-admin users cannot see company selection or active until field" do
    # Log out admin and log in as regular user
    visit logout_path
    sign_in(regular_user)

    # Visit own edit page
    visit edit_user_path(regular_user)

    # Should not see the company selection field or active until field
    expect(page).not_to have_select(I18n.t("users.forms.inspection_company_id"))
    expect(page).not_to have_field("user_active_until")
  end

  scenario "inactive user cannot create inspections" do
    # Make the user inactive
    regular_user.update!(active_until: Date.current - 1.day)

    # Log in as the user
    visit logout_path
    sign_in(regular_user)

    # Try to create an inspection
    unit = create(:unit, user: regular_user)
    visit unit_path(unit)

    # Should see a message about being inactive
    click_button I18n.t("units.buttons.add_inspection")

    expect(page).to have_content(I18n.t("users.messages.user_inactive"))
  end
end
