# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Unit Badge Validation", type: :feature do
  let(:user) { create(:user, :with_company) }
  let(:badge_batch) { create(:badge_batch) }
  let(:badge) { create(:badge, badge_batch: badge_batch) }

  before do
    sign_in(user)
    visit new_unit_path
  end

  context "when UNIT_BADGES is enabled" do
    before { allow(ENV).to receive(:[]).with("UNIT_BADGES").and_return("true") }
    after { allow(ENV).to receive(:[]).and_call_original }

    scenario "shows ID field on new unit form" do
      expect(page).to have_field(I18n.t("forms.units.fields.id"))
    end

    scenario "creates unit with valid badge ID" do
      fill_in I18n.t("forms.units.fields.id"), with: badge.id
      fill_in I18n.t("forms.units.fields.name"), with: "Test Unit"
      fill_in I18n.t("forms.units.fields.operator"), with: "Test Operator"
      fill_in I18n.t("forms.units.fields.manufacturer"), with: "Test Manufacturer"
      fill_in I18n.t("forms.units.fields.serial"), with: "TEST123"
      fill_in I18n.t("forms.units.fields.description"), with: "Test description"

      click_button I18n.t("forms.units.submit")

      expect(page).to have_content("Test Unit")
      expect(Unit.find_by(id: badge.id)).to be_present
    end

    scenario "normalizes ID by stripping spaces and uppercasing" do
      # Badge ID with spaces and lowercase
      badge_id_with_spaces = "  #{badge.id.downcase}  "

      fill_in I18n.t("forms.units.fields.id"), with: badge_id_with_spaces
      fill_in I18n.t("forms.units.fields.name"), with: "Test Unit"
      fill_in I18n.t("forms.units.fields.operator"), with: "Test Operator"
      fill_in I18n.t("forms.units.fields.manufacturer"), with: "Test Manufacturer"
      fill_in I18n.t("forms.units.fields.serial"), with: "TEST123"
      fill_in I18n.t("forms.units.fields.description"), with: "Test description"

      click_button I18n.t("forms.units.submit")

      expect(Unit.find_by(id: badge.id.upcase)).to be_present
    end

    scenario "redirects to existing unit when ID already exists" do
      existing_unit = create(:unit, id: badge.id, user: user)

      fill_in I18n.t("forms.units.fields.id"), with: badge.id
      fill_in I18n.t("forms.units.fields.name"), with: "Test Unit"
      fill_in I18n.t("forms.units.fields.operator"), with: "Test Operator"
      fill_in I18n.t("forms.units.fields.manufacturer"), with: "Test Manufacturer"
      fill_in I18n.t("forms.units.fields.serial"), with: "TEST123"
      fill_in I18n.t("forms.units.fields.description"), with: "Test description"

      click_button I18n.t("forms.units.submit")

      expect(page).to have_content(I18n.t("units.messages.existing_unit_found"))
      expect(current_path).to eq(unit_path(existing_unit))
    end

    scenario "shows error when badge ID is invalid" do
      fill_in I18n.t("forms.units.fields.id"), with: "INVALID9"
      fill_in I18n.t("forms.units.fields.name"), with: "Test Unit"
      fill_in I18n.t("forms.units.fields.operator"), with: "Test Operator"
      fill_in I18n.t("forms.units.fields.manufacturer"), with: "Test Manufacturer"
      fill_in I18n.t("forms.units.fields.serial"), with: "TEST123"
      fill_in I18n.t("forms.units.fields.description"), with: "Test description"

      click_button I18n.t("forms.units.submit")

      error_msg = I18n.t("units.validations.invalid_badge_id")
      expect(page).to have_content(error_msg)
    end

    scenario "shows error when ID is blank" do
      fill_in I18n.t("forms.units.fields.name"), with: "Test Unit"
      fill_in I18n.t("forms.units.fields.operator"), with: "Test Operator"
      fill_in I18n.t("forms.units.fields.manufacturer"), with: "Test Manufacturer"
      fill_in I18n.t("forms.units.fields.serial"), with: "TEST123"
      fill_in I18n.t("forms.units.fields.description"), with: "Test description"

      click_button I18n.t("forms.units.submit")

      expect(page).to have_content("can't be blank")
    end
  end

  context "when UNIT_BADGES is disabled" do
    before { allow(ENV).to receive(:[]).with("UNIT_BADGES").and_return(nil) }
    after { allow(ENV).to receive(:[]).and_call_original }

    scenario "does not show ID field on new unit form" do
      expect(page).not_to have_field(I18n.t("forms.units.fields.id"))
    end

    scenario "creates unit without requiring badge ID" do
      fill_in I18n.t("forms.units.fields.name"), with: "Test Unit"
      fill_in I18n.t("forms.units.fields.operator"), with: "Test Operator"
      fill_in I18n.t("forms.units.fields.manufacturer"), with: "Test Manufacturer"
      fill_in I18n.t("forms.units.fields.serial"), with: "TEST123"
      fill_in I18n.t("forms.units.fields.description"), with: "Test description"

      click_button I18n.t("forms.units.submit")

      expect(page).to have_content("Test Unit")
      created_unit = Unit.find_by(name: "Test Unit")
      expect(created_unit).to be_present
      expect(created_unit.id).to match(/\A[A-Z0-9]{8}\z/)
    end
  end
end
