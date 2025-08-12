# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "User Height Defaults Message", type: :feature do
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user:) }

  before do
    sign_in(user)
    visit edit_inspection_path(inspection, tab: "user_height")
  end

  scenario "shows message when user height fields are set to zero" do
    # Fill in required fields
    fill_in_form :user_height, :play_area_width, "10"
    fill_in_form :user_height, :play_area_length, "15"

    # Leave users_at fields blank (they should default to 0)
    # Don't fill in users_at_1000mm, users_at_1200mm, etc.

    submit_form :user_height

    # Check for the success message with additional info
    expect(page).to have_content(I18n.t("inspections.messages.updated"))

    expected_fields = [
      I18n.t("forms.user_height.fields.users_at_1000mm"),
      I18n.t("forms.user_height.fields.users_at_1200mm"),
      I18n.t("forms.user_height.fields.users_at_1500mm"),
      I18n.t("forms.user_height.fields.users_at_1800mm")
    ].join(", ")

    expected_message = I18n.t(
      "inspections.messages.user_height_defaults_applied",
      fields: expected_fields
    )

    expect(page).to have_content(expected_message)
  end

  scenario "doesn't show message when user height fields are provided" do
    fill_in_form :user_height, :play_area_width, "10"
    fill_in_form :user_height, :play_area_length, "15"
    fill_in_form :user_height, :users_at_1000mm, "5"
    fill_in_form :user_height, :users_at_1200mm, "10"
    fill_in_form :user_height, :users_at_1500mm, "15"
    fill_in_form :user_height, :users_at_1800mm, "20"

    submit_form :user_height

    # Check for only the success message, no additional info
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
    expect(page).not_to have_content("set to zero")
  end

  scenario "shows partial message when some fields are set to zero" do
    fill_in_form :user_height, :play_area_width, "10"
    fill_in_form :user_height, :play_area_length, "15"
    fill_in_form :user_height, :users_at_1000mm, "5"
    fill_in_form :user_height, :users_at_1200mm, "10"
    # Leave users_at_1500mm and users_at_1800mm blank

    submit_form :user_height

    expect(page).to have_content(I18n.t("inspections.messages.updated"))

    expected_fields = [
      I18n.t("forms.user_height.fields.users_at_1500mm"),
      I18n.t("forms.user_height.fields.users_at_1800mm")
    ].join(", ")

    expected_message = I18n.t(
      "inspections.messages.user_height_defaults_applied",
      fields: expected_fields
    )

    expect(page).to have_content(expected_message)
  end
end
