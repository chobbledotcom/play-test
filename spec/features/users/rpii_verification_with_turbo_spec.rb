require "rails_helper"

RSpec.feature "RPII Verification", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let(:user) { create(:user, name: "John Smith", rpii_inspector_number: "12345") }

  before do
    sign_in(admin_user)
  end

  scenario "successful verification with matching name" do
    allow(RpiiVerificationService).to receive(:verify).with("12345").and_return({
      valid: true,
      inspector: {
        name: "John Smith",
        number: "12345",
        qualifications: "RPII Inspector"
      }
    })

    visit edit_user_path(user)

    expect(page).to have_button(I18n.t("users.buttons.verify_rpii"))
    expect(page).not_to have_content(I18n.t("users.verification.success_header"))

    click_button I18n.t("users.buttons.verify_rpii")

    expect(page).to have_content(I18n.t("users.messages.rpii_verified"))

    user.reload
    expect(user.rpii_verified?).to be true
    expect(user.rpii_verified_date).to be_present
  end

  scenario "failed verification with name mismatch" do
    allow(RpiiVerificationService).to receive(:verify).with("12345").and_return({
      valid: true,
      inspector: {
        name: "Jane Doe",
        number: "12345",
        qualifications: "RPII Inspector"
      }
    })

    visit edit_user_path(user)

    click_button I18n.t("users.buttons.verify_rpii")

    expect(page).to have_content(I18n.t("users.messages.rpii_name_mismatch",
      user_name: "John Smith",
      inspector_name: "Jane Doe"))

    user.reload
    expect(user.rpii_verified?).to be false
    expect(user.rpii_verified_date).to be_nil
  end

  scenario "failed verification with number not found" do
    allow(RpiiVerificationService).to receive(:verify).with("12345").and_return({
      valid: false,
      inspector: nil
    })

    visit edit_user_path(user)

    click_button I18n.t("users.buttons.verify_rpii")

    expect(page).to have_content(I18n.t("users.messages.rpii_not_found"))

    user.reload
    expect(user.rpii_verified?).to be false
    expect(user.rpii_verified_date).to be_nil
  end

  scenario "no verify button shown for new user without RPII number" do
    new_user = create(:user, name: "New User", rpii_inspector_number: "TEMP123")

    visit edit_user_path(new_user)

    fill_in I18n.t("users.forms.rpii_inspector_number"), with: ""
    click_button I18n.t("users.buttons.update_user")

    expect(page).to have_content(I18n.t("users.messages.user_updated"))
    expect(page).not_to have_button(I18n.t("users.buttons.verify_rpii"))
  end

  scenario "shows existing verification status" do
    user.update(rpii_verified_date: 2.days.ago)

    visit edit_user_path(user)

    expect(page).to have_button(I18n.t("users.buttons.verify_rpii"))

    within "#rpii_verification_result" do
      expect(page).to have_content("✓")

      expect(page).to have_content("Verified on")
    end
  end

  scenario "successful verification with partial name match" do
    user.update(name: "John Smith")

    allow(RpiiVerificationService).to receive(:verify).with("12345").and_return({
      valid: true,
      inspector: {
        name: "John Patrick Smith", # Inspector has middle name, user doesn't
        number: "12345",
        qualifications: "RPII Inspector"
      }
    })

    visit edit_user_path(user)

    click_button I18n.t("users.buttons.verify_rpii")

    expect(page).to have_content(I18n.t("users.messages.rpii_verified"))

    user.reload
    expect(user.rpii_verified?).to be true
  end
end
