# typed: false

require "rails_helper"

RSpec.feature "User deletion confirmation", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let(:target_user) { create(:user) }

  let(:confirmation_label) do
    I18n.t("forms.user_destroy.fields.confirmation_name", name: target_user.name)
  end

  background do
    sign_in(admin_user)
  end

  scenario "clicking delete on the edit page shows the confirmation page" do
    visit edit_user_path(target_user)

    click_link I18n.t("users.buttons.delete")

    expect(page).to have_content(I18n.t("forms.user_destroy.header"))
    expect(User.exists?(target_user.id)).to be true
  end

  scenario "confirmation page warns about inspection loss and offers deactivation" do
    unit = create(:unit, user: target_user)
    create_list(:inspection, 3, user: target_user, unit: unit)

    visit confirm_destroy_user_path(target_user)

    expect(page).to have_content(I18n.t("users.messages.delete_warning", count: 3))
    expect(page).to have_button(I18n.t("users.buttons.deactivate_instead"))
  end

  scenario "typing the wrong name does not delete the user" do
    visit confirm_destroy_user_path(target_user)

    fill_in confirmation_label, with: target_user.name.downcase
    click_button I18n.t("forms.user_destroy.submit")

    expect(page).to have_content(I18n.t("users.messages.delete_name_mismatch"))
    expect(User.exists?(target_user.id)).to be true
  end

  scenario "typing the exact name deletes the user" do
    visit confirm_destroy_user_path(target_user)

    fill_in confirmation_label, with: "  #{target_user.name}  "
    click_button I18n.t("forms.user_destroy.submit")

    expect(page).to have_content(I18n.t("users.messages.user_deleted"))
    expect(current_path).to eq(users_path)
    expect(User.exists?(target_user.id)).to be false
  end

  scenario "deactivate instead deactivates the user without deleting" do
    visit confirm_destroy_user_path(target_user)

    click_button I18n.t("users.buttons.deactivate_instead")

    expect(page).to have_content(I18n.t("users.messages.user_deactivated"))
    expect(target_user.reload.active_until).to eq(Date.current)
    expect(target_user.is_active?).to be false
    expect(User.exists?(target_user.id)).to be true
  end

  scenario "non-admin is denied access to the confirmation page" do
    logout
    sign_in(target_user)

    visit confirm_destroy_user_path(admin_user)

    expect(page).to have_content(I18n.t("forms.session_new.status.admin_required"))
    expect(current_path).to eq(root_path)
    expect(User.exists?(admin_user.id)).to be true
  end
end
