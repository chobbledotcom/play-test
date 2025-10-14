# typed: false

require "rails_helper"

RSpec.feature "Creating inspection from unit search", type: :feature do
  let(:user) { create(:user) }
  let(:badge) { create(:badge) }
  let!(:unit) { create(:unit, user: user, id: badge.id) }

  before do
    sign_in(user)
  end

  context "when UNIT_BADGES is enabled" do
    before do
      Rails.configuration.unit_badges = true
    end

    after do
      Rails.configuration.unit_badges = false
    end

    scenario "index page shows 'Create Inspection from Unit' button" do
      visit inspections_path

      expect(page).not_to have_button(I18n.t("inspections.buttons.add_inspection"))
      expect(page).to have_link(I18n.t("inspections.buttons.add_inspection_from_unit"))
    end

    scenario "user searches for unit and creates inspection" do
      visit new_inspection_from_unit_path

      expect(page).to have_content(I18n.t("inspections.titles.new_from_unit"))
      expect(page).to have_content(I18n.t("inspections.messages.search_unit_prompt"))

      fill_in I18n.t("inspections.fields.search_unit_id"), with: unit.id
      click_button I18n.t("inspections.buttons.search")

      expect(page).to have_content(unit.name)
      expect(page).to have_content(unit.serial)
      expect(page).to have_content(unit.manufacturer)
      expect(page).to have_content(unit.operator)
      expect(page).to have_button(I18n.t("inspections.buttons.create_inspection_for_unit"))

      click_button I18n.t("inspections.buttons.create_inspection_for_unit")

      expect(current_path).to match(%r{/inspections/[A-Z0-9]{8}/edit})
      expect(page).to have_content(I18n.t("inspections.messages.created"))
    end

    scenario "user searches with spaces and lowercase (normalized)" do
      visit new_inspection_from_unit_path

      fill_in I18n.t("inspections.fields.search_unit_id"), with: "  #{unit.id.downcase}  "
      click_button I18n.t("inspections.buttons.search")

      expect(page).to have_content(unit.name)
      expect(page).to have_button(I18n.t("inspections.buttons.create_inspection_for_unit"))
    end

    scenario "user searches for badge without unit" do
      badge_without_unit = create(:badge)

      visit new_inspection_from_unit_path

      fill_in I18n.t("inspections.fields.search_unit_id"), with: badge_without_unit.id
      click_button I18n.t("inspections.buttons.search")

      expect(page).to have_content(I18n.t("inspections.messages.badge_exists_create_unit"))
      expect(page).to have_link(I18n.t("units.buttons.create"))

      click_link I18n.t("units.buttons.create")
      expect(current_path).to eq(new_unit_path)
      expect(page).to have_field("unit[id]", with: badge_without_unit.id)
    end

    scenario "user searches for invalid ID" do
      visit new_inspection_from_unit_path

      fill_in I18n.t("inspections.fields.search_unit_id"), with: "INVALID1"
      click_button I18n.t("inspections.buttons.search")

      expect(page).to have_content(I18n.t("inspections.messages.invalid_unit_id"))
      expect(page).not_to have_button(I18n.t("inspections.buttons.create_inspection_for_unit"))
    end

    scenario "user can find units created by other users" do
      other_user = create(:user)
      other_badge = create(:badge)
      other_unit = create(:unit, user: other_user, id: other_badge.id)

      visit new_inspection_from_unit_path

      fill_in I18n.t("inspections.fields.search_unit_id"), with: other_unit.id
      click_button I18n.t("inspections.buttons.search")

      expect(page).to have_content(other_unit.name)
      expect(page).to have_button(I18n.t("inspections.buttons.create_inspection_for_unit"))
    end

    scenario "unit with photo displays photo" do
      unit.photo.attach(fixture_file_upload("test_image.jpg", "image/jpeg"))

      visit new_inspection_from_unit_path

      fill_in I18n.t("inspections.fields.search_unit_id"), with: unit.id
      click_button I18n.t("inspections.buttons.search")

      expect(page).to have_css("img")
    end

    scenario "unit with last inspection displays size" do
      create(:inspection, :completed, unit: unit, width: 5, length: 4, height: 3)

      visit new_inspection_from_unit_path

      fill_in I18n.t("inspections.fields.search_unit_id"), with: unit.id
      click_button I18n.t("inspections.buttons.search")

      expect(page).to have_content("5m × 4m × 3m")
    end
  end

  context "when UNIT_BADGES is disabled" do
    before do
      Rails.configuration.unit_badges = false
    end

    scenario "index page shows original 'Add Inspection' button" do
      visit inspections_path

      expect(page).to have_button(I18n.t("inspections.buttons.add_inspection"))
      expect(page).not_to have_link(I18n.t("inspections.buttons.add_inspection_from_unit"))
    end

    scenario "new_from_unit route is still accessible" do
      visit new_inspection_from_unit_path

      expect(page).to have_content(I18n.t("inspections.titles.new_from_unit"))
    end

    scenario "direct inspection creation still works" do
      visit inspections_path

      click_button I18n.t("inspections.buttons.add_inspection")

      expect(current_path).to match(%r{/inspections/[A-Z0-9]{8}/edit})
    end
  end
end
