require "rails_helper"

RSpec.feature "Unit Creation from Inspection", type: :feature do
  let(:inspector_company) { create(:inspector_company, active: true) }
  let(:user) { create(:user, inspection_company: inspector_company) }

  before do
    sign_in(user)
  end

  # Testing creation without unit would be done through controller specs
  # since we're posting directly without a form

  describe "creating unit from inspection" do
    let(:inspection_without_unit) {
      create(:inspection,
        user: user,
        unit: nil,
        inspector_company: inspector_company,
        inspection_location: "Workshop A",
        width: 10.5,
        length: 8.0,
        height: 4.0,
        num_low_anchors: 6,
        num_high_anchors: 2,
        slide_platform_height: 2.5,
        containing_wall_height: 1.2)
    }

    it "shows link to create unit when inspection has no unit" do
      visit inspection_path(inspection_without_unit)

      expect(page).to have_link(I18n.t("inspections.buttons.create_unit"))
    end

    it "displays form for creating unit from inspection" do
      visit new_unit_from_inspection_path(inspection_without_unit)

      expect(page).to have_content(I18n.t("units.titles.new_from_inspection"))
      expect(page).to have_field(I18n.t("units.fields.name"))
      expect(page).to have_field(I18n.t("units.fields.serial"))
      expect(page).to have_field(I18n.t("units.fields.manufacturer"))
      expect(page).to have_field(I18n.t("units.fields.has_slide"))
      expect(page).to have_field(I18n.t("units.fields.model"))
      expect(page).to have_field(I18n.t("units.fields.owner"))

      # Should show dimension info from inspection
      expect(page).to have_content("10.5m × 8m × 4m")
    end

    it "creates unit with form data and copies dimensions from inspection" do
      visit new_unit_from_inspection_path(inspection_without_unit)

      fill_in I18n.t("units.fields.name"), with: "Big Bounce Castle"
      fill_in I18n.t("units.fields.serial"), with: "BBC-2024-001"
      fill_in I18n.t("units.fields.manufacturer"), with: "Bouncy Co Ltd"
      fill_in I18n.t("units.fields.description"), with: "Large bouncy castle for events"
      # Has slide checkbox defaults to unchecked
      fill_in I18n.t("units.fields.model"), with: "MegaBounce 3000"
      fill_in I18n.t("units.fields.owner"), with: "Fun Events Ltd"

      click_button I18n.t("units.buttons.create")

      # Should redirect to inspection with success message
      expect(current_path).to eq(inspection_path(inspection_without_unit))
      expect(page).to have_content(I18n.t("units.messages.created_from_inspection"))

      # Verify unit was created with correct data
      unit = Unit.last
      expect(unit.name).to eq("Big Bounce Castle")
      expect(unit.serial).to eq("BBC-2024-001")
      expect(unit.manufacturer).to eq("Bouncy Co Ltd")
      expect(unit.has_slide).to eq(false)
      expect(unit.model).to eq("MegaBounce 3000")
      expect(unit.owner).to eq("Fun Events Ltd")

      # Verify dimensions were copied
      expect(unit.width).to eq(10.5)
      expect(unit.length).to eq(8.0)
      expect(unit.height).to eq(4.0)
      expect(unit.num_low_anchors).to eq(6)
      expect(unit.num_high_anchors).to eq(2)
      expect(unit.slide_platform_height).to eq(2.5)
      expect(unit.containing_wall_height).to eq(1.2)

      # Verify inspection now has the unit
      inspection_without_unit.reload
      expect(inspection_without_unit.unit).to eq(unit)
    end

    it "validates required fields" do
      visit new_unit_from_inspection_path(inspection_without_unit)

      # Submit without filling required fields
      click_button I18n.t("units.buttons.create")

      expect(page).to have_content("Could not save unit")
      expect(page).to have_content("Name can't be blank")
      expect(page).to have_content("Serial can't be blank")
    end

    it "prevents creating unit if user doesn't own the inspection" do
      other_user = create(:user, inspection_company: inspector_company)
      other_inspection = create(:inspection, user: other_user, unit: nil, inspector_company: inspector_company)

      visit new_unit_from_inspection_path(other_inspection)

      expect(page).to have_content(I18n.t("units.errors.inspection_not_found"))
      expect(current_path).to eq(root_path)
    end

    it "redirects if inspection already has a unit" do
      inspection_with_unit = create(:inspection, user: user, inspector_company: inspector_company)

      visit new_unit_from_inspection_path(inspection_with_unit)

      expect(page).to have_content(I18n.t("units.errors.inspection_has_unit"))
      expect(current_path).to eq(inspection_path(inspection_with_unit))
    end
  end

  describe "inspection index with unit-less inspections" do
    let!(:inspection_with_unit) { create(:inspection, user: user, inspector_company: inspector_company) }
    let!(:inspection_without_unit) {
      create(:inspection,
        user: user,
        unit: nil,
        inspector_company: inspector_company,
        inspection_location: "No Unit Test")
    }

    it "shows indicator for inspections without units" do
      visit inspections_path

      within("tr", text: "No Unit Test") do
        expect(page).to have_content(I18n.t("inspections.labels.no_unit"))
      end
    end
  end
end
