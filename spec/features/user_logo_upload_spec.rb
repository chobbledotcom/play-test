require "rails_helper"

RSpec.feature "User Logo Upload", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  scenario "uploading a logo via settings page" do
    visit change_settings_user_path(user)

    # Check that logo field is present
    expect(page).to have_field(I18n.t("forms.user_settings.fields.logo"))

    # Upload a logo
    attach_file I18n.t("forms.user_settings.fields.logo"),
      Rails.root.join("spec/fixtures/files/test_image.jpg")

    # Submit the form
    click_button I18n.t("forms.user_settings.submit")

    # Wait for turbo to complete
    expect(page).to have_content(I18n.t("users.messages.settings_updated"))

    # Reload to verify persistence
    visit change_settings_user_path(user)

    # Check that logo is now displayed
    expect(page).to have_css(".file-preview img")
    expect(page).to have_content("Current company logo")

    # Verify in database
    user.reload
    expect(user.logo).to be_attached
  end
end
