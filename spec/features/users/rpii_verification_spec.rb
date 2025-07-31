require "rails_helper"

RSpec.feature "RPII Verification", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let(:user) { create(:user, rpii_inspector_number: "12345") }

  before do
    sign_in(admin_user)
    allow(RpiiVerificationService).to receive(:verify)
      .and_return({valid: false, inspector: nil})
  end

  scenario "successful verification" do
    allow(RpiiVerificationService).to receive(:verify).with("12345")
      .and_return({
        valid: true,
        inspector: {name: user.name, number: "12345"}
      })

    visit edit_user_path(user)
    click_button I18n.t("users.buttons.verify_rpii")

    expect(page).to have_content(I18n.t("users.messages.rpii_verified"))
    expect(user.reload.rpii_verified?).to be true
  end

  scenario "failed verification" do
    visit edit_user_path(user)
    click_button I18n.t("users.buttons.verify_rpii")

    expect(page).to have_content(I18n.t("users.messages.rpii_not_found"))
    expect(user.reload.rpii_verified?).to be false
  end

  scenario "name mismatch" do
    allow(RpiiVerificationService).to receive(:verify).with("12345")
      .and_return({
        valid: true,
        inspector: {name: "Different Name", number: "12345"}
      })

    visit edit_user_path(user)
    click_button I18n.t("users.buttons.verify_rpii")

    user_name = user.name
    inspector_name = "Different Name"
    expect(page).to have_content(
      I18n.t("users.messages.rpii_name_mismatch",
        user_name:, inspector_name:)
    )
    expect(user.reload.rpii_verified?).to be false
  end
end
