# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Shared Unit Inspections with Badges", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let(:user_a) { create(:user) }
  let(:user_b) { create(:user) }
  let(:badge_batch) { create(:badge_batch, count: 1) }
  let(:badge) { create(:badge, badge_batch: badge_batch) }

  context "when UNIT_BADGES is enabled" do
    around { |example| with_unit_badges_enabled(&example) }

    scenario "user B can create inspection for unit created by user A" do
      # Admin creates a badge batch (already done via let)
      expect(badge_batch).to be_present
      expect(badge).to be_present

      # User A creates a unit using the badge ID
      sign_in(user_a)
      visit new_unit_path

      fill_in_form(:units, :id, badge.id)
      fill_in_form(:units, :name, "Shared Test Unit")
      fill_in_form(:units, :operator, "Test Operator")
      fill_in_form(:units, :manufacturer, "Test Manufacturer")
      fill_in_form(:units, :serial, "SHARED123")
      fill_in_form(:units, :description, "Shared inspection test unit")

      submit_form(:units)

      expect(page).to have_content("Shared Test Unit")
      unit = Unit.find_by(id: badge.id)
      expect(unit).to be_present
      expect(unit.user_id).to eq(user_a.id)

      # User A creates a complete inspection for the unit
      visit new_inspection_from_unit_path
      search_field_key = "inspections.fields.search_unit_id"
      fill_in I18n.t(search_field_key), with: unit.id
      click_i18n_button("inspections.buttons.search")

      expect(page).to have_content(unit.name)
      click_i18n_button("inspections.buttons.create_inspection_for_unit")

      expect(current_path).to match(%r{/inspections/[A-Z0-9]{8}/edit})
      inspection_path_regex = %r{/inspections/([A-Z0-9]{8})/edit}
      first_inspection_id = current_path.match(inspection_path_regex)[1]

      # Complete the first inspection (mark as passed)
      visit inspection_path(first_inspection_id)
      inspection = Inspection.find(first_inspection_id)
      inspection.update!(
        complete_date: Time.current,
        passed: true,
        width: 5.0,
        length: 4.0,
        height: 3.0
      )

      # User A logs out
      logout

      # User B logs in
      sign_in(user_b)

      # User B creates a new inspection for the same unit
      visit new_inspection_from_unit_path
      search_field_key = "inspections.fields.search_unit_id"
      fill_in I18n.t(search_field_key), with: unit.id
      click_i18n_button("inspections.buttons.search")

      expect(page).to have_content(unit.name)
      create_button_key = "inspections.buttons.create_inspection_for_unit"
      expect(page).to have_button(I18n.t(create_button_key))

      click_i18n_button(create_button_key)

      expect(current_path).to match(%r{/inspections/[A-Z0-9]{8}/edit})
      expect_i18n_content("inspections.messages.created")

      inspection_id_regex = %r{/inspections/([A-Z0-9]{8})/edit}
      second_inspection_id = current_path.match(inspection_id_regex)[1]
      expect(second_inspection_id).not_to eq(first_inspection_id)

      second_inspection = Inspection.find(second_inspection_id)
      expect(second_inspection.user_id).to eq(user_b.id)
      expect(second_inspection.unit_id).to eq(unit.id)

      # Verify User B cannot edit the unit (gets 404)
      visit edit_unit_path(unit)
      expect(page.status_code).to eq(404)
    end

    scenario "user B cannot edit unit created by user A" do
      # Create unit as user A
      sign_in(user_a)
      unit = create(:unit, id: badge.id, user: user_a)
      logout

      # Try to edit as user B
      sign_in(user_b)
      visit edit_unit_path(unit)

      expect(page.status_code).to eq(404)
    end

    scenario "multiple users create inspections for badge unit" do
      # Create unit with badge
      sign_in(user_a)
      unit = create(:unit, id: badge.id, user: user_a)
      create(:inspection, :completed, unit: unit, user: user_a, passed: true)
      logout

      # User B creates inspection
      sign_in(user_b)
      visit new_inspection_from_unit_path
      search_field_key = "inspections.fields.search_unit_id"
      fill_in I18n.t(search_field_key), with: unit.id
      click_i18n_button("inspections.buttons.search")

      create_button_key = "inspections.buttons.create_inspection_for_unit"
      expect(page).to have_button(I18n.t(create_button_key))
      click_i18n_button(create_button_key)

      expect(current_path).to match(%r{/inspections/[A-Z0-9]{8}/edit})
      inspection_regex = %r{/inspections/([A-Z0-9]{8})/edit}
      inspection_id = current_path.match(inspection_regex)[1]
      inspection = Inspection.find(inspection_id)
      expect(inspection.user_id).to eq(user_b.id)
      expect(inspection.unit_id).to eq(unit.id)
    end
  end

  context "when UNIT_BADGES is disabled" do
    around { |example| with_unit_badges_disabled(&example) }

    scenario "user B cannot create inspection for user A's unit" do
      # User A creates a unit (without badges, gets auto-generated ID)
      sign_in(user_a)
      visit new_unit_path

      fill_in_form(:units, :name, "User A's Unit")
      fill_in_form(:units, :operator, "Test Operator")
      fill_in_form(:units, :manufacturer, "Test Manufacturer")
      fill_in_form(:units, :serial, "USERA123")
      fill_in_form(:units, :description, "Private unit for user A")

      submit_form(:units)

      expect(page).to have_content("User A's Unit")
      unit = Unit.find_by(name: "User A's Unit")
      expect(unit).to be_present
      expect(unit.user_id).to eq(user_a.id)

      logout

      # User B tries to create inspection for User A's unit
      sign_in(user_b)

      # Try via new_from_unit path (should fail to find)
      visit new_inspection_from_unit_path
      search_field_key = "inspections.fields.search_unit_id"
      fill_in I18n.t(search_field_key), with: unit.id
      click_i18n_button("inspections.buttons.search")

      # Unit should be found (show page is public)
      expect(page).to have_content(unit.name)
      create_button_key = "inspections.buttons.create_inspection_for_unit"
      expect(page).to have_button(I18n.t(create_button_key))

      # But creating inspection should fail
      click_i18n_button(create_button_key)

      # Should redirect with error
      expect_i18n_content("inspections.errors.invalid_unit")
      expect(current_path).to eq("/")
    end

    scenario "user can only create inspections for own units" do
      # User A creates a unit
      sign_in(user_a)
      create(:unit, user: user_a)
      logout

      # User B creates a unit
      sign_in(user_b)
      unit_b = create(:unit, user: user_b)

      # User B can create inspection for their own unit
      visit new_inspection_from_unit_path
      search_field_key = "inspections.fields.search_unit_id"
      fill_in I18n.t(search_field_key), with: unit_b.id
      click_i18n_button("inspections.buttons.search")

      expect(page).to have_content(unit_b.name)
      create_button_key = "inspections.buttons.create_inspection_for_unit"
      click_i18n_button(create_button_key)

      expect(current_path).to match(%r{/inspections/[A-Z0-9]{8}/edit})
      expect_i18n_content("inspections.messages.created")
    end
  end
end
