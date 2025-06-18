require "rails_helper"

RSpec.feature "Inspection Deletion Security", type: :feature do
  include InspectionTestHelpers
  let(:user) { create(:user) }

  before { sign_in(user) }

  scenario "prevents deletion of complete inspections via direct DELETE request" do
    inspection = create(:inspection, :completed, user: user)
    page.driver.submit :delete, "/inspections/#{inspection.id}", {}

    expect(current_path).to eq(inspection_path(inspection))
    expect(page).to have_content(I18n.t("inspections.messages.delete_complete_denied"))
    expect(Inspection.exists?(inspection.id)).to be true
  end

  scenario "allows deletion of draft inspections via direct DELETE request" do
    inspection = create(:inspection, user: user)

    expect {
      page.driver.submit :delete, "/inspections/#{inspection.id}", {}
    }.to change(Inspection, :count).by(-1)

    expect(current_path).to eq(inspections_path)
    expect_deleted_message
  end

  scenario "prevents non-owners from accessing edit page" do
    other_inspection = create(:inspection, user: create(:user))
    visit edit_inspection_path(other_inspection)

    expect_access_denied
  end

  scenario "prevents non-owners from deleting via direct DELETE request" do
    other_inspection = create(:inspection, user: create(:user))
    page.driver.submit :delete, "/inspections/#{other_inspection.id}", {}

    expect_access_denied
    expect(Inspection.exists?(other_inspection.id)).to be true
  end

  scenario "admins follow same deletion rules as regular users" do
    logout
    admin = create(:user, :admin)
    sign_in(admin)

    inspection = create(:inspection, :completed, user: admin)
    visit edit_inspection_path(inspection)

    expect(page).not_to have_button(I18n.t("inspections.buttons.delete"))
    expect(page).to have_button(I18n.t("inspections.buttons.switch_to_in_progress"))
  end

  scenario "delete button disappears when inspection becomes complete" do
    inspection = create(:inspection, user: user)
    visit edit_inspection_path(inspection)

    expect(page).to have_button(I18n.t("inspections.buttons.delete"))

    fill_assessments_with_complete_data(inspection)
    inspection.update!(complete_date: Time.current)

    visit edit_inspection_path(inspection)
    expect(page).not_to have_button(I18n.t("inspections.buttons.delete"))
  end
end
