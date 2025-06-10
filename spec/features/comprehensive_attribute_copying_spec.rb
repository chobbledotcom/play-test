require "rails_helper"

RSpec.feature "Comprehensive Attribute Copying", type: :feature do
  let(:inspector_company) { create(:inspector_company, active: true) }
  let(:user) { create(:user, inspection_company: inspector_company) }

  before do
    sign_in(user)
  end

  describe "unit to inspection copying" do
    let(:unit) { create(:unit, :with_comprehensive_dimensions, user: user) }

    scenario "copies all dimensions when creating inspection from unit" do
      visit unit_path(unit)
      click_button I18n.t("units.buttons.add_inspection")

      expect(page).to have_current_path(/\/inspections\/[A-Z0-9]+\/edit/)
      
      inspection = user.inspections.find_by(unit_id: unit.id)
      expect(inspection).to be_present
      expect_all_dimensions_copied(unit, inspection)
    end

    scenario "replaces dimensions when using replace dimensions button" do
      inspection = create(:inspection, user: user, unit: unit, inspector_company: inspector_company,
                         width: 5.0, length: 4.0, height: 2.0, has_slide: false, is_totally_enclosed: false,
                         num_low_anchors: 1, rope_size: 10.0)
      visit edit_inspection_path(inspection)
      visit replace_dimensions_inspection_path(inspection)
      
      inspection.reload
      expect_all_dimensions_copied(unit, inspection)
    end
  end

  describe "inspection to unit copying" do
    let(:inspection) { create(:inspection, :with_comprehensive_dimensions, user: user, inspector_company: inspector_company, unit: nil) }

    scenario "copies all dimensions when creating unit from inspection" do
      visit new_unit_from_inspection_path(inspection)
      
      fill_in I18n.t("units.fields.name"), with: "Unit from Inspection"
      fill_in I18n.t("units.fields.serial"), with: "UFI-2024-001"
      fill_in I18n.t("units.fields.manufacturer"), with: "Inspection Manufacturer"
      fill_in I18n.t("units.fields.description"), with: "Unit created from inspection"
      fill_in I18n.t("units.fields.owner"), with: "Inspection Owner Ltd"
      click_button I18n.t("units.buttons.create")

      expect(current_path).to eq(inspection_path(inspection))
      expect(page).to have_content(I18n.t("units.messages.created_from_inspection"))

      unit = user.units.find_by(serial: "UFI-2024-001")
      expect(unit).to be_present
      expect_all_dimensions_copied(inspection, unit)
      
      expect(unit.name).to eq("Unit from Inspection")
      expect(unit.serial).to eq("UFI-2024-001")
      expect(unit.manufacturer).to eq("Inspection Manufacturer")
    end
  end

  describe "unit selection and dimension replacement" do
    let(:original_unit) { create(:unit, user: user, name: "Original Unit") }
    let(:new_unit) { create(:unit, :with_comprehensive_dimensions, user: user, name: "New Unit") }
    let!(:inspection) { create(:inspection, user: user, unit: original_unit, inspector_company: inspector_company) }

    scenario "copies dimensions when changing unit on inspection" do
      original_unit
      new_unit

      visit select_unit_inspection_path(inspection)

      expect(page).to have_content(original_unit.name)
      expect(page).to have_content(new_unit.name)

      list_item = page.find("li", text: new_unit.name)
      within(list_item) do
        click_button I18n.t("units.actions.select")
      end

      expect(current_path).to eq(edit_inspection_path(inspection))
      expect(page).to have_content(I18n.t("inspections.messages.unit_changed", unit_name: new_unit.name))

      inspection.reload
      expect(inspection.unit_id).to eq(new_unit.id)
      %w[width length height has_slide num_low_anchors].each do |attr|
        expect(inspection.send(attr)).to eq(new_unit.send(attr)), "#{attr} should be copied from new unit"
      end
    end
  end

  private

  def expect_all_dimensions_copied(source, target)
    %w[width length height has_slide is_totally_enclosed num_low_anchors rope_size 
       slide_platform_height tallest_user_height].each do |attr|
      expect(target.send(attr)).to eq(source.send(attr)), "#{attr} should be copied"
    end
  end
end
