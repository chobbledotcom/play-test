require "rails_helper"

RSpec.feature "Inactive User Restrictions", type: :feature do
  let(:active_user) { create(:user, active_until: nil) }
  let(:inactive_user) { create(:user, active_until: Date.current - 1.day) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:user) { inactive_user }

  shared_context "signed in as inactive user" do
    before { sign_in(inactive_user) }
  end

  shared_context "signed in as active user" do
    before { sign_in(active_user) }
  end

  describe "inactive user" do
    include_context "signed in as inactive user"

    it "sees inactive message on pages" do
      visit units_path
      expect(page).to have_content(I18n.t("users.messages.user_inactive"))
    end

    it "can view but not edit resources" do
      visit unit_path(unit)
      expect(page).to have_content(unit.name)

      visit edit_unit_path(unit)
      expect(page).to have_current_path(units_path)

      visit inspection_path(inspection)

      visit edit_inspection_path(inspection)
      expect(page).to have_current_path(inspection_path(inspection))
    end
  end

  describe "active user" do
    include_context "signed in as active user"
    let(:user) { active_user }

    it "has full access without restrictions" do
      visit new_unit_path
      expect(page).to have_content(I18n.t("forms.units.header"))
      expect(page).not_to have_content(I18n.t("users.messages.user_inactive"))

      visit edit_unit_path(unit)
      expect(page).to have_content(I18n.t("forms.units.header"))
    end
  end
end
