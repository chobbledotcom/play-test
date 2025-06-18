require "rails_helper"

RSpec.feature "Unit Deletion Restrictions", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before do
    sign_in(user)
  end

  context "when unit has no inspections" do
    it "shows delete link on unit show page" do
      visit unit_path(unit)
      expect(page).to have_link(I18n.t("units.buttons.delete"))
    end

    it "shows delete button on unit edit page" do
      visit edit_unit_path(unit)
      expect(page).to have_button(I18n.t("units.buttons.delete"))
    end
  end

  context "when unit has only draft inspections" do
    before do
      create(:inspection, unit: unit, user: user, complete_date: nil)
    end

    it "shows delete link on unit show page" do
      visit unit_path(unit)
      expect(page).to have_link(I18n.t("units.buttons.delete"))
    end

    it "shows delete button on unit edit page" do
      visit edit_unit_path(unit)
      expect(page).to have_button(I18n.t("units.buttons.delete"))
    end
  end

  context "when unit has completed inspections" do
    before do
      create(:inspection, unit: unit, user: user, complete_date: Time.current)
    end

    it "hides delete link on unit show page" do
      visit unit_path(unit)
      expect(page).not_to have_link(I18n.t("units.buttons.delete"))
    end

    it "hides delete button on unit edit page" do
      visit edit_unit_path(unit)
      expect(page).not_to have_button(I18n.t("units.buttons.delete"))
    end
  end

  context "when unit has both draft and completed inspections" do
    before do
      create(:inspection, unit: unit, user: user, complete_date: nil)
      create(:inspection, unit: unit, user: user, complete_date: Time.current)
    end

    it "hides delete link on unit show page" do
      visit unit_path(unit)
      expect(page).not_to have_link(I18n.t("units.buttons.delete"))
    end

    it "hides delete button on unit edit page" do
      visit edit_unit_path(unit)
      expect(page).not_to have_button(I18n.t("units.buttons.delete"))
    end
  end
end
