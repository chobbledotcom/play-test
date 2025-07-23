require "rails_helper"

RSpec.feature "Unit Inspection Association", type: :feature do
  let(:inspector_company) { create(:inspector_company, active: true) }
  let(:user) { create(:user, inspection_company: inspector_company) }

  before do
    sign_in(user)
  end

  def fill_unit_field(field, value)
    fill_in I18n.t("forms.units.fields.#{field}"), with: value
  end

  describe "creating inspection from unit" do
    let(:unit) { create(:unit, user: user) }

    scenario "creates inspection linked to unit" do
      visit unit_path(unit)
      click_button I18n.t("units.buttons.add_inspection")

      expect(page).to have_current_path(/\/inspections\/[A-Z0-9]+\/edit/)

      inspection = user.inspections.find_by(unit_id: unit.id)
      expect(inspection).to be_present
      expect(inspection.unit).to eq(unit)
    end
  end

  describe "creating unit from inspection" do
    let(:inspection) { create(:inspection, user: user, inspector_company: inspector_company, unit: nil) }

    scenario "creates unit and links it to inspection" do
      visit new_unit_from_inspection_path(inspection)

      fill_unit_field(:name, "Unit from Inspection")
      fill_unit_field(:serial, "UFI-2024-001")
      fill_unit_field(:manufacturer, "Inspection Manufacturer")
      fill_unit_field(:description, "Unit created from inspection")
      fill_unit_field(:operator, "Inspection Operator Ltd")
      click_button I18n.t("forms.units.submit")

      expect(page).to have_content(I18n.t("units.messages.created_from_inspection"))

      expect(current_path).to eq(inspection_path(inspection))

      unit = user.units.find_by(serial: "UFI-2024-001")
      expect(unit).to be_present

      inspection.reload
      expect(inspection.unit).to eq(unit)

      expect(unit.name).to eq("Unit from Inspection")
      expect(unit.serial).to eq("UFI-2024-001")
      expect(unit.manufacturer).to eq("Inspection Manufacturer")
    end
  end

  describe "changing unit on inspection" do
    let!(:original_unit) { create(:unit, user: user, name: "Original Unit") }
    let!(:new_unit) { create(:unit, user: user, name: "New Unit") }
    let!(:inspection) { create(:inspection, user: user, unit: original_unit, inspector_company: inspector_company) }

    scenario "updates unit association on inspection" do
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
      expect(inspection.unit).to eq(new_unit)
    end
  end
end
