# typed: false

require "rails_helper"

RSpec.feature "User Height Assessment", type: :feature do
  include InspectionTestHelpers
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before do
    login_user_via_form(user)
  end

  it_behaves_like "an assessment form", "user_height"

  describe "filling out the user height assessment form" do
    before do
      visit edit_inspection_path(inspection, tab: "user_height")
    end

    it "displays all the required form fields" do
      expect_field_present :user_height, :containing_wall_height

      expect_field_present :user_height, :users_at_1000mm
      expect_field_present :user_height, :users_at_1200mm
      expect_field_present :user_height, :users_at_1500mm
      expect_field_present :user_height, :users_at_1800mm
      expect_field_present :user_height, :custom_user_height_comment

      expect_field_present :user_height, :play_area_length
      expect_field_present :user_height, :play_area_width
      expect_field_present :user_height, :negative_adjustment

      expect(page).to have_field(I18n.t("shared.comment"))
    end

    it "saves the assessment data when submitting the form" do
      fill_in_form :user_height, :containing_wall_height, "2.5"

      fill_in_form :user_height, :users_at_1000mm, "5"
      fill_in_form :user_height, :users_at_1200mm, "4"
      fill_in_form :user_height, :users_at_1500mm, "3"
      fill_in_form :user_height, :users_at_1800mm, "2"
      fill_in_form :user_height, :custom_user_height_comment, "Test height comments"

      fill_in_form :user_height, :play_area_length, "10.0"
      fill_in_form :user_height, :play_area_width, "8.0"
      fill_in_form :user_height, :negative_adjustment, "2.0"

      click_i18n_button "inspections.buttons.save_assessment"

      expect_updated_message

      inspection.reload
      assessment = inspection.user_height_assessment
      expect(assessment).to be_present
      expect(assessment.containing_wall_height).to eq(2.5)
      expect(assessment.users_at_1000mm).to eq(5)
      expect(assessment.users_at_1200mm).to eq(4)
      expect(assessment.users_at_1500mm).to eq(3)
      expect(assessment.users_at_1800mm).to eq(2)
      expect(assessment.custom_user_height_comment).to eq("Test height comments")
      expect(assessment.play_area_length).to eq(10.0)
      expect(assessment.play_area_width).to eq(8.0)
      expect(assessment.negative_adjustment).to eq(2.0)
    end

    it "displays validation errors for invalid data" do
      fill_in_form :user_height, :containing_wall_height, "-1"

      click_i18n_button "inspections.buttons.save_assessment"

      expect(page.status_code).to eq(422)

      expect(page).to have_css(".form-errors")
      wall_height_error = I18n.t(
        "forms.user_height.errors.containing_wall_height_negative"
      )
      expect(page).to have_content(wall_height_error)

      assessment = inspection.user_height_assessment.reload
      expect(assessment.containing_wall_height).not_to eq(-1)
    end
  end
end
