# typed: false

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
      if Rails.configuration.units.badges_enabled
        badge = create(:badge, badge_batch: create(:badge_batch))
        fill_in_form :units, :id, badge.id
      end

      fill_in_form :units, :name, "Test Bouncy Castle"
      fill_in_form :units, :manufacturer, "JumpCo"
      fill_in_form :units, :serial, "ASSET-001"
      fill_in_form :units, :description, "Large bouncy castle for events"
      fill_in_form :units, :manufacture_date, "2023-01-15"

      submit_form :units

      expect(page).to have_content("Test Bouncy Castle")
      expect(page).to have_content("JumpCo")

      expect(current_path).to match(%r{^/units/[A-Z0-9]{8}$})

      # Check audit log shows creation
      click_link I18n.t("units.links.view_log")
      expect(page).to have_content(I18n.t("events.actions.created"))

      # Creation events shouldn't have changes
      expect(page).not_to have_content(I18n.t("events.messages.view_changes"))
    end

    it "shows validation errors for missing required fields" do
      submit_form :units

      expected_count = Rails.configuration.units.badges_enabled ? 5 : 4
      expect_form_errors :units, count: expected_count
      expect(page).to have_content(I18n.t("units.validations.name_blank"))
      expect(page).to have_content(I18n.t("units.validations.manufacturer_blank"))
      expect(page).to have_content(I18n.t("units.validations.serial_blank"))
      expect(page).to have_content(I18n.t("units.validations.description_blank"))

      if Rails.configuration.units.badges_enabled
        expect(page).to have_content(I18n.t("units.validations.id_blank"))
      end
    end

    it "validates serial uniqueness per user" do
      create(:unit, user: user, serial: "DUPLICATE-001")

      fill_in_form :units, :name, "Test Unit"
      fill_in_form :units, :manufacturer, "Test Mfg"
      fill_in_form :units, :serial, "DUPLICATE-001"
      fill_in_form :units, :description, "Test description"

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

    it "successfully updates unit with new data and creates audit log" do
      fill_in_form :units, :name, "Updated Name"
      fill_in_form :units, :description, "Updated description"

      submit_form :units

      expect(page).to have_current_path(unit_path(unit))
      expect(page).to have_content("Updated Name")

      # Check audit log was created
      click_link I18n.t("units.links.view_log")

      # Check audit log shows the update
      expect(page).to have_content(I18n.t("events.actions.updated"))

      # First check if there's a changes column with content
      changes_cell = find("tbody tr td:last-child")

      # If changes were recorded, there should be a details element
      if changes_cell.text.strip != "-"
        within(changes_cell) do
          find("summary").click
          expect(page).to have_content("Original Name → Updated Name")
          expect(page).to have_content("Test Bouncy Castle → Updated description")
        end
      else
        # If no changes recorded, fail the test with helpful message
        fail "No changes were recorded in the audit log"
      end
    end
  end
end
