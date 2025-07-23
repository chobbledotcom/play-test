require "rails_helper"

RSpec.feature "Admin User Management", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:inspector_company) { create(:inspector_company, name: "Test Company") }
  let(:regular_user) { create(:user, :active_user, email: "user@example.com", inspection_company: inspector_company) }

  before do
    sign_in(admin_user)
  end

  scenario "sets user as inactive" do
    expect(regular_user.is_active?).to be true
    expect(regular_user.can_create_inspection?).to be true

    visit edit_user_path(regular_user)

    if ENV["SIMPLE_USER_ACTIVATION"] == "true"
      # Deactivate the user
      click_button I18n.t("users.buttons.deactivate")
      expect(page).to have_content(I18n.t("users.messages.user_deactivated"))

      regular_user.reload
      expect(regular_user.is_active?).to be false

      # Also remove the company for full test coverage
      visit edit_user_path(regular_user)
      select I18n.t("users.forms.no_company"), from: I18n.t("users.forms.inspection_company_id")
      click_button I18n.t("users.buttons.update_user")
    else
      # Use the date field
      fill_in "user_active_until", with: (Date.current - 1.day).strftime("%Y-%m-%d")
      select I18n.t("users.forms.no_company"), from: I18n.t("users.forms.inspection_company_id")
      click_button I18n.t("users.buttons.update_user")
      expect(page).to have_content(I18n.t("users.messages.user_updated"))
    end

    regular_user.reload
    expect(regular_user.is_active?).to be false
    expect(regular_user.can_create_inspection?).to be false
  end

  scenario "sees all company options including no company" do
    create(:inspector_company, name: "Another Company")
    visit edit_user_path(regular_user)

    select_element = find("select[name='user[inspection_company_id]']")
    options = select_element.all("option").map(&:text)
    expect(options).to include(I18n.t("users.forms.no_company"))
    expect(options).to include("Test Company")
    expect(options).to include("Another Company")
  end

  scenario "non-admin cannot see admin fields" do
    logout
    sign_in(regular_user)
    visit edit_user_path(regular_user)

    expect(page).to have_content(I18n.t("forms.session_new.status.admin_required"))
    expect(current_path).to eq(root_path)
  end

  scenario "inactive user cannot create inspections" do
    regular_user.update!(active_until: Date.current - 1.day)
    logout
    sign_in(regular_user)
    unit = create(:unit, user: regular_user)
    visit unit_path(unit)

    click_button I18n.t("units.buttons.add_inspection")

    expect(page).to have_content(I18n.t("users.messages.user_inactive"))
  end
end
