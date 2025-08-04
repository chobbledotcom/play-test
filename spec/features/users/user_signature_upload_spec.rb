require "rails_helper"

RSpec.feature "User Signature Upload", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  scenario "user uploads a signature through settings" do
    visit change_settings_user_path(user)

    expect(page).to have_content(I18n.t("forms.user_settings.header"))

    # Upload a signature
    within_fieldset I18n.t("forms.user_settings.sections.preferences") do
      attach_file I18n.t("forms.user_settings.fields.signature"),
        Rails.root.join("spec/fixtures/files/test_image.jpg")
    end

    click_button I18n.t("forms.user_settings.submit")

    expect_successful_action(change_settings_user_path(user))

    # Verify the signature was attached
    user.reload
    expect(user.signature).to be_attached
  end

  scenario "user uploads an invalid file as signature" do
    visit change_settings_user_path(user)

    within_fieldset I18n.t("forms.user_settings.sections.preferences") do
      attach_file I18n.t("forms.user_settings.fields.signature"),
        Rails.root.join("spec/fixtures/files/test.txt")
    end

    click_button I18n.t("forms.user_settings.submit")

    # Should redirect back to settings page with error
    expect(page).to have_current_path(change_settings_user_path(user))
    # In test environment, flash messages might not render, so we verify the behavior

    # Signature should not be attached
    user.reload
    expect(user.signature).not_to be_attached
  end
end
