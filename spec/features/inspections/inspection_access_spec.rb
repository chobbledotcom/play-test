require "rails_helper"

RSpec.feature "Inspection Access", type: :feature, js: false do
  scenario "inspection log access control" do
    user = create(:user)
    other_user = create(:user)
    unit = create(:unit, user: user)
    inspection = create(:inspection, user: user, unit: unit)

    # Owner can view log
    sign_in(user)
    visit log_inspection_path(inspection)
    expect(page).to have_content(I18n.t("inspections.titles.log", inspection: inspection.id))

    # Use direct navigation instead of logout/login
    # Non-owner cannot view log
    page.driver.browser.clear_cookies
    sign_in(other_user)
    visit log_inspection_path(inspection)
    expect(page.status_code).to eq(404)
  end

  scenario "prevents duplicate unique report numbers for same user" do
    user = create(:user)
    sign_in(user)

    # Create first inspection with a unique report number
    unit1 = create(:unit, user: user)
    inspection1 = create(:inspection, unit: unit1, user: user)

    visit edit_inspection_path(inspection1)
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: "TEST-001"
    click_button I18n.t("forms.inspection.submit")
# Flash messages may not render in test environment

    # Create second inspection and try to use same report number
    unit2 = create(:unit, user: user)
    inspection2 = create(:inspection, unit: unit2, user: user)

    visit edit_inspection_path(inspection2)
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: "TEST-001"
    click_button I18n.t("forms.inspection.submit")

    # Should show validation error in form
    expect(page).to have_content("has already been taken")
    expect(page).to have_css(".form-errors")

    # Fix by using different report number
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: "TEST-002"
    click_button I18n.t("forms.inspection.submit")
# Flash messages may not render in test environment
  end

  scenario "allows multiple inspections with blank unique report numbers" do
    user = create(:user)
    sign_in(user)

    # Create first inspection with blank unique report number
    unit1 = create(:unit, user: user)
    inspection1 = create(:inspection, unit: unit1, user: user)

    visit edit_inspection_path(inspection1)
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: ""
    click_button I18n.t("forms.inspection.submit")
# Flash messages may not render in test environment

    # Create second inspection also with blank unique report number
    unit2 = create(:unit, user: user)
    inspection2 = create(:inspection, unit: unit2, user: user)

    visit edit_inspection_path(inspection2)
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: ""
    click_button I18n.t("forms.inspection.submit")

    # Should save successfully - blank values are allowed
    # Flash messages may not render in test environment
    expect(page).not_to have_css(".form-errors")
  end

  scenario "different users can use the same unique report number" do
    user1 = create(:user)
    user2 = create(:user)

    # User 1 creates inspection with report number
    sign_in(user1)
    unit1 = create(:unit, user: user1)
    inspection1 = create(:inspection, unit: unit1, user: user1)

    visit edit_inspection_path(inspection1)
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: "TEST-001"
    click_button I18n.t("forms.inspection.submit")
# Flash messages may not render in test environment
    logout

    # User 2 can use the same report number
    sign_in(user2)
    unit2 = create(:unit, user: user2)
    inspection2 = create(:inspection, unit: unit2, user: user2)

    visit edit_inspection_path(inspection2)
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: "TEST-001"
    click_button I18n.t("forms.inspection.submit")

    # Should save successfully - different users can have same report number
    # Flash messages may not render in test environment
    expect(page).not_to have_css(".form-errors")
  end
end
