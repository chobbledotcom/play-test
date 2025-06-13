require "rails_helper"

RSpec.feature "User Height Assessment", type: :feature do
  
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before do
    login_user_via_form(user)
  end

  describe "accessing the user height assessment tab" do
    it "displays the user height tab in the navigation" do
      visit edit_inspection_path(inspection)

      expect(page).to have_link(I18n.t("inspections.tabs.tallest_user_height"))
    end

    it "navigates to the user height assessment form when clicking the tab" do
      visit edit_inspection_path(inspection)
      click_link I18n.t("inspections.tabs.tallest_user_height")

      expect(page).to have_current_path(edit_inspection_path(inspection, tab: "user_height"))
      expect(page).to have_content(I18n.t("forms.tallest_user_height.header"))
    end
  end

  describe "filling out the user height assessment form" do
    before do
      visit edit_inspection_path(inspection, tab: "user_height")
    end

    it "displays all the required form fields" do
      # Height measurements
      expect(page).to have_field(I18n.t("forms.tallest_user_height.fields.containing_wall_height"))
      expect(page).to have_field(I18n.t("forms.tallest_user_height.fields.platform_height"))
      expect(page).to have_field(I18n.t("forms.tallest_user_height.fields.tallest_user_height"))
      expect(page).to have_field(I18n.t("forms.tallest_user_height.fields.permanent_roof"))

      # User capacity
      expect(page).to have_field(I18n.t("forms.tallest_user_height.fields.users_at_1000mm"))
      expect(page).to have_field(I18n.t("forms.tallest_user_height.fields.users_at_1200mm"))
      expect(page).to have_field(I18n.t("forms.tallest_user_height.fields.users_at_1500mm"))
      expect(page).to have_field(I18n.t("forms.tallest_user_height.fields.users_at_1800mm"))

      # Play area
      expect(page).to have_field(I18n.t("forms.tallest_user_height.fields.play_area_length"))
      expect(page).to have_field(I18n.t("forms.tallest_user_height.fields.play_area_width"))
      expect(page).to have_field(I18n.t("forms.tallest_user_height.fields.negative_adjustment"))

      # Comments
      expect(page).to have_field(I18n.t("shared.comment"))
    end

    it "saves the assessment data when submitting the form" do
      # Fill in height measurements
      fill_in_form :tallest_user_height, :containing_wall_height, "2.5"
      fill_in_form :tallest_user_height, :platform_height, "1.0"
      fill_in_form :tallest_user_height, :tallest_user_height, "1.8"
      check_form :tallest_user_height, :permanent_roof

      # Fill in user capacity
      fill_in_form :tallest_user_height, :users_at_1000mm, "5"
      fill_in_form :tallest_user_height, :users_at_1200mm, "4"
      fill_in_form :tallest_user_height, :users_at_1500mm, "3"
      fill_in_form :tallest_user_height, :users_at_1800mm, "2"

      # Fill in play area
      fill_in_form :tallest_user_height, :play_area_length, "10.0"
      fill_in_form :tallest_user_height, :play_area_width, "8.0"
      fill_in_form :tallest_user_height, :negative_adjustment, "2.0"

      # Skip testing comments since JavaScript is disabled in tests
      # The comment field toggle requires JavaScript to work properly

      click_button I18n.t("inspections.buttons.save_assessment")

      expect(page).to have_content(I18n.t("inspections.messages.updated"))

      # Verify the data was saved
      inspection.reload
      assessment = inspection.user_height_assessment
      expect(assessment).to be_present
      expect(assessment.containing_wall_height).to eq(2.5)
      expect(assessment.platform_height).to eq(1.0)
      expect(assessment.tallest_user_height).to eq(1.8)
      expect(assessment.permanent_roof).to be true
      expect(assessment.users_at_1000mm).to eq(5)
      expect(assessment.users_at_1200mm).to eq(4)
      expect(assessment.users_at_1500mm).to eq(3)
      expect(assessment.users_at_1800mm).to eq(2)
      expect(assessment.play_area_length).to eq(10.0)
      expect(assessment.play_area_width).to eq(8.0)
      expect(assessment.negative_adjustment).to eq(2.0)
      # Skip checking comments since JavaScript is disabled in tests
    end

    it "displays validation errors for invalid data" do
      # Try to submit with negative value for containing_wall_height
      fill_in_form :tallest_user_height, :containing_wall_height, "-1"

      click_button I18n.t("inspections.buttons.save_assessment")
      
      # The form should re-render with errors
      expect(page.status_code).to eq(422)
      
      # Should show error messages
      expect(page).to have_css(".form-errors")
      expect(page).to have_content("Containing wall height must be greater than or equal to 0")
      
      # The validation should have failed
      assessment = inspection.user_height_assessment.reload
      expect(assessment.containing_wall_height).not_to eq(-1)
    end
  end

  describe "viewing assessment status" do
    let(:inspection_with_data) { create(:inspection, :with_complete_assessments, user: user, unit: unit) }
    
    before do
      visit edit_inspection_path(inspection_with_data, tab: "user_height")
    end

    it "displays the safety status section" do
      expect(page).to have_content(I18n.t("forms.tallest_user_height.status.height_requirement"))
      expect(page).to have_content(I18n.t("forms.tallest_user_height.status.checks_passed"))
      expect(page).to have_content(I18n.t("forms.tallest_user_height.status.completion"))
    end

    it "shows pass/fail status for height requirement" do
      expect(page).to have_css(".assessment-status")
      
      within(".assessment-status") do
        # With factory data: containing_wall_height: 1.2, tallest_user_height: 1.8
        # This should fail since wall height < user height
        expect(page).to have_content(I18n.t("forms.tallest_user_height.status.height_requirement"))
        expect(page).to have_css(".text-danger", text: I18n.t("shared.fail"))
      end
    end
  end

  # JavaScript tests would require selenium-webdriver which is not available
  # The JavaScript functionality is tested manually
end
