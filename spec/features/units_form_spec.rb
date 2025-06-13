require "rails_helper"

RSpec.describe "Units Form", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe "Creating a new unit" do
    before do
      visit "/units/new"
    end

    it "successfully creates a unit with valid data" do
      fill_in_form :units, :name, "Test Bouncy Castle"
      fill_in_form :units, :manufacturer, "JumpCo"
      fill_in_form :units, :model, "JC-2000"
      fill_in_form :units, :serial, "ASSET-001"
      fill_in_form :units, :description, "Large bouncy castle for events"
      fill_in_form :units, :owner, "Test Company Ltd"
      fill_in_form :units, :manufacture_date, "2023-01-15"
      fill_in_form :units, :notes, "Recently purchased, excellent condition"

      submit_form :units

      expect(page).to have_content("Test Bouncy Castle")
      expect(page).to have_content("JumpCo")
      # Should redirect to the unit show page
      expect(current_path).to match(%r{^/units/[A-Z0-9]{8}$})
    end

    it "shows validation errors for missing required fields" do
      submit_form :units

      expect_form_errors :units, count: 5
      expect(page).to have_content(I18n.t("units.validations.name_blank"))
      expect(page).to have_content(I18n.t("units.validations.manufacturer_blank"))
      expect(page).to have_content(I18n.t("units.validations.serial_blank"))
      expect(page).to have_content(I18n.t("units.validations.description_blank"))
      expect(page).to have_content(I18n.t("units.validations.owner_blank"))
    end

    it "validates serial uniqueness per user" do
      create(:unit, user: user, serial: "DUPLICATE-001")

      fill_in_form :units, :name, "Test Unit"
      fill_in_form :units, :manufacturer, "Test Mfg"
      fill_in_form :units, :serial, "DUPLICATE-001"
      fill_in_form :units, :description, "Test description"
      fill_in_form :units, :owner, "Test Owner"

      submit_form :units

      expect(page).to have_content("Serial has already been taken")
    end
  end

  describe "Editing an existing unit" do
    let(:unit) { create(:unit, user: user, name: "Original Name") }

    before do
      visit edit_unit_path(unit)
    end

    it "populates form with existing unit data" do
      expect(page).to have_field(I18n.t("forms.units.fields.name"), with: unit.name)
      expect(page).to have_field(I18n.t("forms.units.fields.manufacturer"), with: unit.manufacturer)
      expect(page).to have_button(I18n.t("forms.units.submit"))
    end

    it "successfully updates unit with new data" do
      fill_in_form :units, :name, "Updated Name"
      fill_in_form :units, :description, "Updated description"

      submit_form :units

      expect(page).to have_current_path(unit_path(unit))
      expect(page).to have_content("Updated Name")
    end
  end
end
