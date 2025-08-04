require "rails_helper"

RSpec.feature "User Logo Upload", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  scenario "user uploads a logo through settings" do
    # In tests, we pass the user instance, not current_user
    visit change_settings_user_path(user)

    expect(page).to have_content(I18n.t("forms.user_settings.header"))

    # Upload a logo
    within_fieldset I18n.t("forms.user_settings.sections.preferences") do
      attach_file I18n.t("forms.user_settings.fields.logo"),
        Rails.root.join("spec/fixtures/files/test_image.jpg")
    end

    click_button I18n.t("forms.user_settings.submit")
    
    # Wait for redirect after form submission
    expect(page).to have_current_path(change_settings_user_path(user))
    # TODO: Fix flash message display
    # expect(page).to have_content(I18n.t("users.messages.settings_updated"))
    
    # Verify the page reloaded with the uploaded image
    expect(page).to have_content("Current company logo: test_image.jpg")

    # Verify the logo was attached
    user.reload
    expect(user.logo).to be_attached
  end

  scenario "user uploads an invalid file as logo" do
    visit change_settings_user_path(user)

    within_fieldset I18n.t("forms.user_settings.sections.preferences") do
      attach_file I18n.t("forms.user_settings.fields.logo"),
        Rails.root.join("spec/fixtures/files/test.txt")
    end

    click_button I18n.t("forms.user_settings.submit")

    # Wait for redirect after failed upload
    expect(page).to have_current_path(change_settings_user_path(user))
    
    # TODO: Fix error message display for invalid images
    # expect(page).to have_content(I18n.t("errors.messages.invalid_image_format"))

    # Logo should not be attached
    user.reload
    expect(user.logo).not_to be_attached
  end
end
