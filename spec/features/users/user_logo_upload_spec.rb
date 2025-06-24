require "rails_helper"

RSpec.feature "User Logo Upload", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  scenario "user uploads a logo through settings" do
    visit change_settings_user_path(user)

    expect(page).to have_content(I18n.t("forms.user_settings.header"))

    # Upload a logo
    within_fieldset I18n.t("forms.user_settings.sections.preferences") do
      attach_file I18n.t("forms.user_settings.fields.logo"),
        Rails.root.join("spec/fixtures/files/test_image.jpg")
    end

    click_button I18n.t("forms.user_settings.submit")

    expect(page).to have_content(I18n.t("users.messages.settings_updated"))

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

    # Should show validation error
    expect(page).to have_content("Logo must be an image file")

    # Logo should not be attached
    user.reload
    expect(user.logo).not_to be_attached
  end
end
