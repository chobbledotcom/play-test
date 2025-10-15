# typed: false

require "rails_helper"

RSpec.feature "Creating inspection from unit search", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  def search_for_unit(unit_id)
    fill_in I18n.t("forms.unit_search.fields.search"), with: unit_id
    click_button I18n.t("forms.unit_search.submit")
  end

  def expect_unit_found(unit)
    expect(page).to have_content(unit.name)
    expect(page).to have_button(I18n.t("inspections.buttons.create_inspection_for_unit"))
  end

  context "when UNIT_BADGES is enabled" do
    let(:badge) { create(:badge) }
    let!(:unit) { create(:unit, user: user, id: badge.id) }

    before do
      Rails.configuration.units = UnitsConfig.new(badges_enabled: true, reports_unbranded: false)
    end

    after do
      Rails.configuration.units = UnitsConfig.new(badges_enabled: false, reports_unbranded: false)
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

      search_for_unit(unit.id)
      expect_unit_found(unit)

      click_button I18n.t("inspections.buttons.create_inspection_for_unit")

      expect(current_path).to match(%r{/inspections/[A-Z0-9]{8}/edit})
      expect(page).to have_content(I18n.t("inspections.messages.created"))
    end

    scenario "user searches with spaces and lowercase (normalized)" do
      visit new_inspection_from_unit_path

      search_for_unit("  #{unit.id.downcase}  ")
      expect_unit_found(unit)
    end

    scenario "user searches for badge without unit" do
      badge_without_unit = create(:badge)

      visit new_inspection_from_unit_path

      search_for_unit(badge_without_unit.id)

      expect(page).to have_content(I18n.t("inspections.messages.badge_exists_create_unit"))
      expect(page).to have_link(I18n.t("units.buttons.create"))

      click_link I18n.t("units.buttons.create")
      expect(current_path).to eq(new_unit_path)
      expect(page).to have_field("unit[id]", with: badge_without_unit.id, type: :hidden)
    end

    scenario "user searches for invalid ID" do
      visit new_inspection_from_unit_path

      search_for_unit("INVALID1")

      expect(page).to have_content(I18n.t("inspections.messages.invalid_unit_id"))
      expect(page).not_to have_button(I18n.t("inspections.buttons.create_inspection_for_unit"))
    end

    scenario "user can find units created by other users" do
      other_user = create(:user)
      other_badge = create(:badge)
      other_unit = create(:unit, user: other_user, id: other_badge.id)

      visit new_inspection_from_unit_path

      search_for_unit(other_unit.id)
      expect_unit_found(other_unit)
    end

    scenario "unit with last inspection displays dimensions" do
      create(:inspection, :completed, unit: unit, width: 5, length: 4, height: 3)

      visit new_inspection_from_unit_path
      search_for_unit(unit.id)

      expect(page).to have_content("5.0m")
      expect(page).to have_content("4.0m")
      expect(page).to have_content("3.0m")
    end
  end

  context "when UNIT_BADGES is disabled" do
    before do
      Rails.configuration.units = UnitsConfig.new(badges_enabled: false, reports_unbranded: false)
    end

    after do
      Rails.configuration.units = UnitsConfig.new(badges_enabled: false, reports_unbranded: false)
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
