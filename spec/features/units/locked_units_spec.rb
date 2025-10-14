# typed: false

require "rails_helper"

RSpec.feature "Locked Units", type: :feature do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  before do
    login_user_via_form(user)
  end

  context "when LOCK_UNITS_DAYS is configured" do
    let(:old_unit) { create(:unit, user: user, created_at: 91.days.ago) }
    let(:new_unit) { create(:unit, user: user, created_at: 30.days.ago) }

    before do
      ENV["LOCK_UNITS_DAYS"] = "90"
    end

    after do
      ENV.delete("LOCK_UNITS_DAYS")
    end

    scenario "displays lock notice on old unit show page" do
      visit unit_path(old_unit)

      msg = I18n.t("units.messages.locked_unit_notice", days: 90)
      expect(page).to have_content(msg)
    end

    scenario "does not display lock notice on new unit show page" do
      visit unit_path(new_unit)

      msg = I18n.t("units.messages.locked_unit_notice", days: 90)
      expect(page).not_to have_content(msg)
    end

    scenario "redirects edit page for locked unit" do
      visit edit_unit_path(old_unit)

      expect(page).to have_current_path(unit_path(old_unit))
      msg = I18n.t("units.messages.locked_unit", days: 90)
      expect(page).to have_content(msg)
    end

    scenario "allows editing new unit" do
      visit edit_unit_path(new_unit)

      expect(page).to have_current_path(edit_unit_path(new_unit))
      expect(page).to have_button(I18n.t("forms.units.submit"))
    end

    scenario "admin can see locked unit without notice" do
      logout
      login_user_via_form(admin)
      old_admin_unit = create(:unit, user: admin, created_at: 91.days.ago)

      visit unit_path(old_admin_unit)

      msg = I18n.t("units.messages.locked_unit_notice", days: 90)
      expect(page).not_to have_content(msg)
    end

    scenario "admin can edit locked unit" do
      logout
      login_user_via_form(admin)
      old_admin_unit = create(:unit, user: admin, created_at: 91.days.ago)

      visit edit_unit_path(old_admin_unit)

      expect(page).to have_current_path(edit_unit_path(old_admin_unit))
      expect(page).to have_button(I18n.t("forms.units.submit"))

      fill_in "unit[name]", with: "Admin Updated Name"
      click_button I18n.t("forms.units.submit")

      old_admin_unit.reload
      expect(old_admin_unit.name).to eq("Admin Updated Name")
    end
  end

  context "when LOCK_UNITS_DAYS is not configured" do
    let(:very_old_unit) { create(:unit, user: user, created_at: 365.days.ago) }

    before do
      ENV.delete("LOCK_UNITS_DAYS")
    end

    scenario "does not display lock notice" do
      visit unit_path(very_old_unit)

      expect(page).not_to have_css("aside.notice")
    end

    scenario "allows editing very old units" do
      visit edit_unit_path(very_old_unit)

      expect(page).to have_current_path(edit_unit_path(very_old_unit))
      expect(page).to have_button(I18n.t("forms.units.submit"))
    end
  end
end
