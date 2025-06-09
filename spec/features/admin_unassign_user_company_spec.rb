require "rails_helper"

RSpec.feature "Admin unassigns user from company", type: :feature do
  let(:admin_user) { create(:user, :without_company, email: "admin@example.com") }
  let(:inspector_company) { create(:inspector_company, name: "Test Company") }
  let(:regular_user) { create(:user, email: "user@example.com", inspection_company: inspector_company) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_EMAILS_PATTERN").and_return("admin@")
    sign_in(admin_user)
  end

  scenario "admin can unassign a user from their inspection company" do
    # Verify user starts with a company
    expect(regular_user.inspection_company).to eq(inspector_company)
    expect(regular_user.can_create_inspection?).to be true

    # Visit user edit page
    visit edit_user_path(regular_user)

    # Check that the form shows the current company selected
    expect(page).to have_select(I18n.t("users.forms.inspection_company_id"),
      selected: inspector_company.name)

    # Select "No Company"
    select I18n.t("users.forms.no_company"), from: I18n.t("users.forms.inspection_company_id")

    # Submit the form
    click_button I18n.t("users.buttons.update_user")

    # Check for success message
    expect(page).to have_content(I18n.t("users.messages.user_updated"))

    # Verify the user no longer has a company
    regular_user.reload
    expect(regular_user.inspection_company).to be_nil
    expect(regular_user.inspection_company_id).to be_nil
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

  scenario "non-admin users cannot see company selection" do
    # Log out admin and log in as regular user
    visit logout_path
    sign_in(regular_user)

    # Visit own edit page
    visit edit_user_path(regular_user)

    # Should not see the company selection field
    expect(page).not_to have_select(I18n.t("users.forms.inspection_company_id"))
  end

  scenario "user without company cannot create inspections" do
    # Unassign the user from their company
    regular_user.update!(inspection_company_id: nil)

    # Log in as the user
    visit logout_path
    sign_in(regular_user)

    # Try to create an inspection
    unit = create(:unit, user: regular_user)
    visit unit_path(unit)

    # Should see a message about not being able to create inspections
    click_button I18n.t("units.buttons.add_inspection")

    expect(page).to have_content(I18n.t("users.messages.company_not_activated"))
  end
end
