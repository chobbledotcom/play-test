# typed: false

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
end
