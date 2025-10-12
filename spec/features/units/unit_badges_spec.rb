# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Unit Badge Validation", type: :feature do
  let(:user) { create(:user) }
  let(:badge_batch) { create(:badge_batch) }
  let(:badge) { create(:badge, badge_batch: badge_batch) }

  before do
    sign_in(user)
  end

  context "when UNIT_BADGES is enabled" do
    before do
      ENV["UNIT_BADGES"] = "true"
      visit new_unit_path
    end

    after do
      ENV.delete("UNIT_BADGES")
    end

    scenario "shows ID field on new unit form" do
      expect_field_present(:units, :id)
    end

    scenario "creates unit with valid badge ID" do
      fill_in_form(:units, :id, badge.id)
      fill_in_form(:units, :name, "Test Unit")
      fill_in_form(:units, :operator, "Test Operator")
      fill_in_form(:units, :manufacturer, "Test Manufacturer")
      fill_in_form(:units, :serial, "TEST123")
      fill_in_form(:units, :description, "Test description")

      submit_form(:units)

      expect(page).to have_content("Test Unit")
      expect(Unit.find_by(id: badge.id)).to be_present
    end

    scenario "normalizes ID by stripping spaces and uppercasing" do
      badge_id_with_spaces = "  #{badge.id.downcase}  "

      fill_in_form(:units, :id, badge_id_with_spaces)
      fill_in_form(:units, :name, "Test Unit")
      fill_in_form(:units, :operator, "Test Operator")
      fill_in_form(:units, :manufacturer, "Test Manufacturer")
      fill_in_form(:units, :serial, "TEST123")
      fill_in_form(:units, :description, "Test description")

      submit_form(:units)

      expect(Unit.find_by(id: badge.id.upcase)).to be_present
    end

    scenario "redirects to existing unit when ID already exists" do
      existing_unit = create(:unit, id: badge.id, user: user)

      fill_in_form(:units, :id, badge.id)
      fill_in_form(:units, :name, "Test Unit")
      fill_in_form(:units, :operator, "Test Operator")
      fill_in_form(:units, :manufacturer, "Test Manufacturer")
      fill_in_form(:units, :serial, "TEST123")
      fill_in_form(:units, :description, "Test description")

      submit_form(:units)

      expect_i18n_content("units.messages.existing_unit_found")
      expect(current_path).to eq(unit_path(existing_unit))
    end

    scenario "shows error when badge ID is invalid" do
      fill_in_form(:units, :id, "INVALID9")
      fill_in_form(:units, :name, "Test Unit")
      fill_in_form(:units, :operator, "Test Operator")
      fill_in_form(:units, :manufacturer, "Test Manufacturer")
      fill_in_form(:units, :serial, "TEST123")
      fill_in_form(:units, :description, "Test description")

      submit_form(:units)

      expect_i18n_content("units.validations.invalid_badge_id")
    end

    scenario "shows error when ID is blank" do
      fill_in_form(:units, :name, "Test Unit")
      fill_in_form(:units, :operator, "Test Operator")
      fill_in_form(:units, :manufacturer, "Test Manufacturer")
      fill_in_form(:units, :serial, "TEST123")
      fill_in_form(:units, :description, "Test description")

      submit_form(:units)

      expect(page).to have_content("can't be blank")
    end
  end

  context "when UNIT_BADGES is disabled" do
    before do
      ENV.delete("UNIT_BADGES")
      visit new_unit_path
    end

    scenario "does not show ID field on new unit form" do
      expect_field_not_present(:units, :id)
    end

    scenario "creates unit without requiring badge ID" do
      fill_in_form(:units, :name, "Test Unit")
      fill_in_form(:units, :operator, "Test Operator")
      fill_in_form(:units, :manufacturer, "Test Manufacturer")
      fill_in_form(:units, :serial, "TEST123")
      fill_in_form(:units, :description, "Test description")

      submit_form(:units)

      expect(page).to have_content("Test Unit")
      created_unit = Unit.find_by(name: "Test Unit")
      expect(created_unit).to be_present
      expect(created_unit.id).to match(/\A[A-Z0-9]{8}\z/)
    end
  end
end
