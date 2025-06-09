require "rails_helper"

RSpec.feature "Comprehensive Attribute Copying Between Units and Inspections", type: :feature do
  let(:inspector_company) { create(:inspector_company, active: true) }
  let(:user) { create(:user, inspection_company: inspector_company) }

  before do
    sign_in(user)
  end

  describe "Unit -> Inspection attribute copying" do
    let(:unit) do
      create(:unit,
        user: user,
        # Set specific values we can test
        width: 12.5,
        length: 10.0,
        height: 4.5,
        has_slide: true,
        is_totally_enclosed: true,
        num_low_anchors: 6,
        rope_size: 18.0,
        slide_platform_height: 2.5,
        tallest_user_height: 1.8)
    end

    scenario "Creating inspection from unit copies all dimensions" do
      visit unit_path(unit)

      # Create inspection from unit
      click_button I18n.t("units.buttons.add_inspection")

      # Should be redirected to edit inspection page
      expect(page).to have_current_path(/\/inspections\/[A-Z0-9]+\/edit/)

      # Find the inspection created for this user with this unit
      inspection = user.inspections.find_by(unit_id: unit.id)
      expect(inspection).to be_present

      # Verify key dimensions were copied
      expect(inspection.width).to eq(unit.width)
      expect(inspection.length).to eq(unit.length)
      expect(inspection.height).to eq(unit.height)
      expect(inspection.has_slide).to eq(unit.has_slide)
      expect(inspection.is_totally_enclosed).to eq(unit.is_totally_enclosed)
      expect(inspection.num_low_anchors).to eq(unit.num_low_anchors)
      expect(inspection.rope_size).to eq(unit.rope_size)
      expect(inspection.slide_platform_height).to eq(unit.slide_platform_height)
      expect(inspection.tallest_user_height).to eq(unit.tallest_user_height)
    end

    scenario "Replace dimensions button copies all attributes from unit" do
      # Create inspection with different dimensions
      inspection = create(:inspection,
        user: user,
        unit: unit,
        inspector_company: inspector_company,
        # Set different values to verify they get replaced
        width: 5.0,
        length: 4.0,
        height: 2.0,
        has_slide: false,
        is_totally_enclosed: false,
        num_low_anchors: 1,
        rope_size: 10.0)

      visit edit_inspection_path(inspection)

      # Click replace dimensions link
      visit replace_dimensions_inspection_path(inspection)

      inspection.reload

      # Verify dimensions were replaced with unit values
      expect(inspection.width).to eq(unit.width)
      expect(inspection.length).to eq(unit.length)
      expect(inspection.height).to eq(unit.height)
      expect(inspection.has_slide).to eq(unit.has_slide)
      expect(inspection.is_totally_enclosed).to eq(unit.is_totally_enclosed)
      expect(inspection.num_low_anchors).to eq(unit.num_low_anchors)
      expect(inspection.rope_size).to eq(unit.rope_size)
    end
  end

  describe "Inspection -> Unit attribute copying" do
    let(:inspection) do
      create(:inspection,
        user: user,
        inspector_company: inspector_company,
        unit: nil,  # Important: inspection must not have a unit
        # Set specific values we can test
        width: 15.0,
        length: 12.0,
        height: 5.0,
        has_slide: true,
        is_totally_enclosed: true,
        num_low_anchors: 8,
        rope_size: 22.0,
        slide_platform_height: 3.0,
        tallest_user_height: 2.0)
    end

    scenario "Creating unit from inspection copies all dimensions" do
      visit new_unit_from_inspection_path(inspection)

      # Debug - check what's on the page
      expect(page).to have_current_path(new_unit_from_inspection_path(inspection))

      # Fill in required unit-specific fields
      fill_in I18n.t("units.fields.name"), with: "Unit from Inspection"
      fill_in I18n.t("units.fields.serial"), with: "UFI-2024-001"
      fill_in I18n.t("units.fields.manufacturer"), with: "Inspection Manufacturer"
      fill_in I18n.t("units.fields.description"), with: "Unit created from inspection"
      fill_in I18n.t("units.fields.owner"), with: "Inspection Owner Ltd"

      click_button I18n.t("units.buttons.create")

      # Should redirect to inspection with success message
      expect(current_path).to eq(inspection_path(inspection))
      expect(page).to have_content(I18n.t("units.messages.created_from_inspection"))

      unit = user.units.find_by(serial: "UFI-2024-001")
      expect(unit).to be_present

      # Verify key dimensions were copied
      expect(unit.width).to eq(inspection.width)
      expect(unit.length).to eq(inspection.length)
      expect(unit.height).to eq(inspection.height)
      expect(unit.has_slide).to eq(inspection.has_slide)
      expect(unit.is_totally_enclosed).to eq(inspection.is_totally_enclosed)
      expect(unit.num_low_anchors).to eq(inspection.num_low_anchors)
      expect(unit.rope_size).to eq(inspection.rope_size)
      expect(unit.slide_platform_height).to eq(inspection.slide_platform_height)
      expect(unit.tallest_user_height).to eq(inspection.tallest_user_height)

      # Verify unit-specific fields are what we set, not copied
      expect(unit.name).to eq("Unit from Inspection")
      expect(unit.serial).to eq("UFI-2024-001")
      expect(unit.manufacturer).to eq("Inspection Manufacturer")
    end
  end

  describe "Unit selection and dimension replacement" do
    let(:original_unit) do
      create(:unit,
        user: user,
        name: "Original Unit",
        width: 10.0,
        length: 8.0,
        height: 3.5,
        has_slide: false,
        num_low_anchors: 4)
    end

    let(:new_unit) do
      create(:unit,
        user: user,
        name: "New Unit",
        width: 15.0,
        length: 12.0,
        height: 5.0,
        has_slide: true,
        num_low_anchors: 8)
    end

    let!(:inspection) do
      create(:inspection,
        user: user,
        unit: original_unit,
        inspector_company: inspector_company)
    end

    scenario "Changing unit on inspection copies dimensions from new unit" do
      # Force units to be created by accessing them
      original_unit
      new_unit

      visit select_unit_inspection_path(inspection)

      # Should see both units
      expect(page).to have_content(original_unit.name)
      expect(page).to have_content(new_unit.name)

      # Select the new unit by clicking the select button for the new unit
      # Find the list item containing the new unit name and click its select button
      list_item = page.find("li", text: new_unit.name)
      within(list_item) do
        click_button I18n.t("units.actions.select")
      end

      # Should redirect to edit page with success message
      expect(current_path).to eq(edit_inspection_path(inspection))
      expect(page).to have_content(I18n.t("inspections.messages.unit_changed", unit_name: new_unit.name))

      inspection.reload

      # Verify unit was changed and dimensions were copied
      expect(inspection.unit_id).to eq(new_unit.id)
      expect(inspection.width).to eq(new_unit.width)
      expect(inspection.length).to eq(new_unit.length)
      expect(inspection.height).to eq(new_unit.height)
      expect(inspection.has_slide).to eq(new_unit.has_slide)
      expect(inspection.num_low_anchors).to eq(new_unit.num_low_anchors)
    end
  end
end
