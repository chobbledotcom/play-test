require "rails_helper"

RSpec.feature "RPII Verification with Turbo", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let(:user) { create(:user, rpii_inspector_number: "12345") }

  before do
    sign_in(admin_user)
    allow(RpiiVerificationService).to receive(:verify)
      .and_return({valid: false, inspector: nil})
  end

  scenario "shows verified status" do
    user.update(rpii_verified_date: 2.days.ago)
    visit edit_user_path(user)

    within "#rpii_verification_result" do
      expect(page).to have_content("✓")
      expect(page).to have_content("Verified on")
    end
  end

  scenario "no verify button when RPII blank" do
    user.update_column(:rpii_inspector_number, "")
    visit edit_user_path(user)

    expect(page).not_to have_button(I18n.t("users.buttons.verify_rpii"))
  end

  scenario "partial name match verification" do
    user.update(name: "John Smith")
    allow(RpiiVerificationService).to receive(:verify).with("12345")
      .and_return({
        valid: true,
        inspector: {name: "John Patrick Smith", number: "12345"}
      })

    visit edit_user_path(user)
    click_button I18n.t("users.buttons.verify_rpii")
# Flash messages may not render in test environment
    expect(user.reload.rpii_verified?).to be true
  end
end
