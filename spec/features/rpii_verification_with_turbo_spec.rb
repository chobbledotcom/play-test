require "rails_helper"

RSpec.feature "RPII Verification", type: :feature do
  let(:admin_user) { create(:user, email: "admin@example.com", name: "Admin User") }
  let(:user) { create(:user, name: "John Smith", rpii_inspector_number: "12345") }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_EMAILS_PATTERN").and_return("admin@")
    sign_in(admin_user)
  end

  scenario "successful verification with matching name" do
    # Mock the RPII service to return a matching inspector
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

    # Check for flash message in non-Turbo mode
    expect(page).to have_content(I18n.t("users.messages.rpii_verified"))

    # Verify the database was updated
    user.reload
    expect(user.rpii_verified?).to be true
    expect(user.rpii_verified_date).to be_present
  end

  scenario "failed verification with name mismatch" do
    # Mock the RPII service to return a different name
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

    # Check for flash message in non-Turbo mode
    expect(page).to have_content(I18n.t("users.messages.rpii_name_mismatch",
      user_name: "John Smith",
      inspector_name: "Jane Doe"))

    # Verify the database was NOT updated
    user.reload
    expect(user.rpii_verified?).to be false
    expect(user.rpii_verified_date).to be_nil
  end

  scenario "failed verification with number not found" do
    # Mock the RPII service to return not found
    allow(RpiiVerificationService).to receive(:verify).with("12345").and_return({
      valid: false,
      inspector: nil
    })

    visit edit_user_path(user)

    click_button I18n.t("users.buttons.verify_rpii")

    # Check for flash message in non-Turbo mode
    expect(page).to have_content(I18n.t("users.messages.rpii_not_found"))

    # Verify the database was NOT updated
    user.reload
    expect(user.rpii_verified?).to be false
    expect(user.rpii_verified_date).to be_nil
  end

  scenario "no verify button shown for new user without RPII number" do
    new_user = create(:user, name: "New User", rpii_inspector_number: "TEMP123")

    visit edit_user_path(new_user)

    # Update to empty string which would make the button disappear
    fill_in I18n.t("users.forms.rpii_inspector_number"), with: ""
    click_button I18n.t("users.buttons.update_user")

    # After clearing RPII number, verify button should not be shown
    expect(page).to have_content(I18n.t("users.messages.user_updated"))
    expect(page).not_to have_button(I18n.t("users.buttons.verify_rpii"))
  end

  scenario "shows existing verification status" do
    # Set user as already verified
    user.update(rpii_verified_date: 2.days.ago)

    visit edit_user_path(user)

    expect(page).to have_button(I18n.t("users.buttons.verify_rpii"))

    within "#rpii_verification_result" do
      expect(page).to have_content("✓")
      # Just check that "Verified on" text is present
      expect(page).to have_content("Verified on")
    end
  end

  scenario "successful verification with partial name match" do
    # Test the name matching logic - inspector has full name, user has partial
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

    # Check for flash message in non-Turbo mode
    expect(page).to have_content(I18n.t("users.messages.rpii_verified"))

    user.reload
    expect(user.rpii_verified?).to be true
  end
end
