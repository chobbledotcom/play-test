# typed: false

require "rails_helper"

RSpec.feature "Save & Continue button", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:complete_inspection) { create(:inspection, :completed, unit: unit, user: user) }

  before do
    sign_in(user)
    # Remove complete_date to make it editable
    complete_inspection.update!(complete_date: nil)
  end

  describe "Complete inspection" do
    scenario "shows 'Save Inspection' on inspection tab when all fields are complete" do
      visit edit_inspection_path(complete_inspection, tab: "inspection")

      expect(page).to have_button("Save Inspection")
      expect(page).not_to have_button("Save & Continue")
    end

    scenario "shows 'Save Assessment' on assessment tabs when all fields are complete" do
      visit edit_inspection_path(complete_inspection, tab: "materials")

      expect(page).to have_button("Save Assessment")
      expect(page).not_to have_button("Save & Continue")

      visit edit_inspection_path(complete_inspection, tab: "structure")

      expect(page).to have_button("Save Assessment")
      expect(page).not_to have_button("Save & Continue")
    end

    scenario "shows 'Save Results' on results tab when all fields are complete" do
      visit edit_inspection_path(complete_inspection, tab: "results")

      expect(page).to have_button("Save Results")
      expect(page).not_to have_button("Save & Continue")
    end
  end

  describe "Incomplete inspection" do
    before do
      # Make the inspection incomplete by removing the passed field
      # Also remove width to make inspection tab incomplete
      complete_inspection.update!(passed: nil, width: nil)
    end

    scenario "shows 'Save & Continue' on inspection tab when inspection has incomplete fields" do
      visit edit_inspection_path(complete_inspection, tab: "inspection")

      expect(page).to have_button("Save & Continue")
      expect(page).not_to have_button("Save Inspection")
    end

    scenario "shows 'Save & Continue' on assessment tabs when inspection has incomplete fields" do
      visit edit_inspection_path(complete_inspection, tab: "materials")

      expect(page).to have_button("Save & Continue")
      expect(page).not_to have_button("Save Assessment")

      visit edit_inspection_path(complete_inspection, tab: "structure")

      expect(page).to have_button("Save & Continue")
      expect(page).not_to have_button("Save Assessment")

      visit edit_inspection_path(complete_inspection, tab: "anchorage")

      expect(page).to have_button("Save & Continue")
      expect(page).not_to have_button("Save Assessment")
    end

    scenario "shows 'Save & Continue' on results tab when inspection has incomplete fields" do
      visit edit_inspection_path(complete_inspection, tab: "results")

      expect(page).to have_button("Save & Continue")
      expect(page).not_to have_button("Save Results")
    end
  end

  describe "Dynamic button text update" do
    scenario "button text changes from 'Save & Continue' to 'Save Results' when passed field is filled" do
      # Start with incomplete inspection (no passed field)
      complete_inspection.update!(passed: nil)

      visit edit_inspection_path(complete_inspection, tab: "results")

      # Initially should show "Save & Continue"
      expect(page).to have_button("Save & Continue")

      # Fill in the passed field using the helper
      choose_pass_fail(I18n.t("forms.results.fields.passed"), true)

      # Save and revisit the page
      click_button "Save & Continue"
      expect(page).to have_content(I18n.t("inspections.messages.updated"))

      visit edit_inspection_path(complete_inspection, tab: "results")

      # Now should show "Save Results" since all fields are complete
      expect(page).to have_button("Save Results")
      expect(page).not_to have_button("Save & Continue")
    end
  end
end
