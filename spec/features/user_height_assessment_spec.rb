require "rails_helper"

RSpec.feature "User Height Assessment", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before do
    login_user_via_form(user)
  end

  # Use shared examples for common assessment behaviors
  it_behaves_like "an assessment form", "user_height"

  describe "filling out the user height assessment form" do
    before do
      visit edit_inspection_path(inspection, tab: "user_height")
    end

    it "displays all the required form fields" do
      # Height measurements
      expect(page).to have_field(I18n.t("forms.user_height.fields.containing_wall_height"))
      expect(page).to have_field(I18n.t("forms.user_height.fields.platform_height"))
      expect(page).to have_field(I18n.t("forms.user_height.fields.tallest_user_height"))

      # User capacity
      expect(page).to have_field(I18n.t("forms.user_height.fields.users_at_1000mm"))
      expect(page).to have_field(I18n.t("forms.user_height.fields.users_at_1200mm"))
      expect(page).to have_field(I18n.t("forms.user_height.fields.users_at_1500mm"))
      expect(page).to have_field(I18n.t("forms.user_height.fields.users_at_1800mm"))

      # Play area
      expect(page).to have_field(I18n.t("forms.user_height.fields.play_area_length"))
      expect(page).to have_field(I18n.t("forms.user_height.fields.play_area_width"))
      expect(page).to have_field(I18n.t("forms.user_height.fields.negative_adjustment"))

      # Comments
      expect(page).to have_field(I18n.t("shared.comment"))
    end

    it "saves the assessment data when submitting the form" do
      # Fill in height measurements
      fill_in_form :user_height, :containing_wall_height, "2.5"
      fill_in_form :user_height, :platform_height, "1.0"
      fill_in_form :user_height, :tallest_user_height, "1.8"

      # Fill in user capacity
      fill_in_form :user_height, :users_at_1000mm, "5"
      fill_in_form :user_height, :users_at_1200mm, "4"
      fill_in_form :user_height, :users_at_1500mm, "3"
      fill_in_form :user_height, :users_at_1800mm, "2"

      # Fill in play area
      fill_in_form :user_height, :play_area_length, "10.0"
      fill_in_form :user_height, :play_area_width, "8.0"
      fill_in_form :user_height, :negative_adjustment, "2.0"

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
      fill_in_form :user_height, :containing_wall_height, "-1"

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
end
