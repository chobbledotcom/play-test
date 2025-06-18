require "rails_helper"

RSpec.feature "RPII Verification", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let(:user_with_valid_rpii) { create(:user, name: "Chris Winters", rpii_inspector_number: "AI0025") }
  let(:user_with_invalid_rpii) { create(:user, rpii_inspector_number: "9999") }
  let(:user_without_rpii) { create(:user, rpii_inspector_number: "TEMP123").tap { |u| u.update_column(:rpii_inspector_number, "") } }

  before do
    sign_in(admin_user)
  end

  scenario "admin can verify a valid RPII inspector number" do
    visit edit_user_path(user_with_valid_rpii)

    expect(page).to have_button(I18n.t("users.buttons.verify_rpii"))
    expect(page).not_to have_content("✓")

    click_button I18n.t("users.buttons.verify_rpii")

    expect(page).to have_content(I18n.t("users.messages.rpii_verified"))
    expect(page).to have_content("✓")

    user_with_valid_rpii.reload
    expect(user_with_valid_rpii.rpii_verified?).to be true
    expect(user_with_valid_rpii.rpii_verified_date).to be_within(1.minute).of(Time.current)
  end

  scenario "admin sees error when verifying invalid RPII inspector number" do
    visit edit_user_path(user_with_invalid_rpii)

    click_button I18n.t("users.buttons.verify_rpii")

    expect(page).to have_content(I18n.t("users.messages.rpii_not_found"))
    expect(page).not_to have_content("✓")

    user_with_invalid_rpii.reload
    expect(user_with_invalid_rpii.rpii_verified?).to be false
    expect(user_with_invalid_rpii.rpii_verified_date).to be_nil
  end

  scenario "verification button not shown when RPII number is blank" do
    visit edit_user_path(user_without_rpii)

    expect(page).not_to have_button(I18n.t("users.buttons.verify_rpii"))
  end

  scenario "previously verified date is cleared when verification fails" do
    user_with_invalid_rpii.update!(rpii_verified_date: 1.day.ago)

    visit edit_user_path(user_with_invalid_rpii)

    expect(page).to have_content("✓")

    click_button I18n.t("users.buttons.verify_rpii")

    expect(page).to have_content(I18n.t("users.messages.rpii_not_found"))
    expect(page).not_to have_content("✓")

    user_with_invalid_rpii.reload
    expect(user_with_invalid_rpii.rpii_verified_date).to be_nil
  end

  scenario "non-admin users cannot access verification" do
    sign_in(user_with_valid_rpii)

    visit edit_user_path(user_with_invalid_rpii)

    expect(page).not_to have_current_path(edit_user_path(user_with_invalid_rpii))
    expect(page).to have_content(I18n.t("authorization.admin_required"))
  end

  scenario "verification redirects back to edit page" do
    visit edit_user_path(user_with_valid_rpii)

    click_button I18n.t("users.buttons.verify_rpii")

    expect(page).to have_current_path(edit_user_path(user_with_valid_rpii))
    expect(page).to have_content(I18n.t("users.messages.rpii_verified"))
  end

  scenario "admin can compare verification details with user details" do
    user_with_mismatch = create(:user, name: "John Smith", rpii_inspector_number: "AI0025")

    visit edit_user_path(user_with_mismatch)

    expect(page).to have_field(I18n.t("users.forms.name"), with: "John Smith")

    click_button I18n.t("users.buttons.verify_rpii")

    expect(page).to have_content(I18n.t("users.messages.rpii_name_mismatch", user_name: "John Smith", inspector_name: "Chris Winters"))
  end
end
