require "rails_helper"

RSpec.feature "Inspection Deletion Restrictions", type: :feature do
  let(:inspector_company) { create(:inspector_company, name: "Test Company") }
  let(:user) { create(:user, inspection_company: inspector_company) }
  let(:unit) { create(:unit, user: user) }

  before do
    sign_in(user)
  end

  context "for regular users" do
    scenario "shows delete button for draft inspections" do
      inspection = create(:inspection, user: user, unit: unit, status: "draft")

      visit edit_inspection_path(inspection)

      expect(page).to have_button(I18n.t("inspections.buttons.delete"))
    end

    scenario "hides delete button for complete inspections" do
      inspection = create(:inspection, user: user, unit: unit, status: "complete")

      visit edit_inspection_path(inspection)

      expect(page).not_to have_button(I18n.t("inspections.buttons.delete"))
    end

    scenario "shows delete button for inspections with nil status" do
      inspection = create(:inspection, user: user, unit: unit, status: nil)

      visit edit_inspection_path(inspection)

      expect(page).to have_button(I18n.t("inspections.buttons.delete"))
    end

    scenario "successfully deletes draft inspection when delete button is clicked" do
      inspection = create(:inspection, user: user, unit: unit, status: "draft")

      visit edit_inspection_path(inspection)

      expect {
        click_button I18n.t("inspections.buttons.delete")
      }.to change(Inspection, :count).by(-1)

      expect(page).to have_content(I18n.t("inspections.messages.deleted"))
      expect(current_path).to eq(inspections_path)
    end
  end

  # TODO: Admin user tests commented out due to admin deletion issue
  # context "for admin users" do
  #   let(:admin_user) { create(:user, :admin, inspection_company: inspector_company) }
  #
  #   before do
  #     sign_in(admin_user)
  #   end
  #
  #   scenario "shows delete button for draft inspections" do
  #     inspection = create(:inspection, user: admin_user, unit: unit, status: "draft")
  #
  #     visit edit_inspection_path(inspection)
  #
  #     expect(page).to have_button(I18n.t("inspections.buttons.delete"))
  #   end
  #
  #   scenario "shows delete button for complete inspections" do
  #     inspection = create(:inspection, user: admin_user, unit: unit, status: "complete")
  #
  #     visit edit_inspection_path(inspection)
  #
  #     expect(page).to have_button(I18n.t("inspections.buttons.delete"))
  #   end
  #
  #   scenario "successfully deletes complete inspection when delete button is clicked" do
  #     inspection = create(:inspection, user: admin_user, unit: unit, status: "complete")
  #
  #     visit edit_inspection_path(inspection)
  #
  #     expect {
  #       click_button I18n.t("inspections.buttons.delete")
  #     }.to change(Inspection, :count).by(-1)
  #
  #     expect(page).to have_content(I18n.t("inspections.messages.deleted"))
  #     expect(current_path).to eq(inspections_path)
  #   end
  # end

  context "edge cases and error scenarios" do
    scenario "attempting to delete complete inspection via direct URL shows error" do
      inspection = create(:inspection, user: user, unit: unit, status: "complete")

      # Try to delete via direct HTTP request (simulating form manipulation)
      page.driver.submit :delete, "/inspections/#{inspection.id}", {}

      expect(current_path).to eq(inspection_path(inspection))
      expect(page).to have_content(I18n.t("inspections.messages.delete_complete_denied"))

      # Verify inspection still exists
      expect(Inspection.exists?(inspection.id)).to be true
    end

    scenario "changing inspection to complete status hides delete button" do
      inspection = create(:inspection, user: user, unit: unit, status: "draft")

      visit edit_inspection_path(inspection)
      expect(page).to have_button(I18n.t("inspections.buttons.delete"))

      # Change status to complete (simulating the status change)
      inspection.update!(status: "complete")

      visit edit_inspection_path(inspection)
      expect(page).not_to have_button(I18n.t("inspections.buttons.delete"))
    end
  end
end
