require "rails_helper"

RSpec.feature "Comprehensive Attribute Copying Between Units and Inspections", type: :feature do
  let(:inspector_company) { create(:inspector_company, active: true) }
  let(:user) { create(:user, inspection_company: inspector_company) }

  before do
    sign_in(user)
  end

  describe "Unit -> Inspection attribute copying" do
    let(:comprehensive_unit) { create(:unit, :with_comprehensive_dimensions, user: user) }

    scenario "Creating inspection from unit copies all attributes" do
      visit unit_path(comprehensive_unit)
      
      # Create inspection from unit
      click_button I18n.t("units.buttons.add_inspection")
      
      # Should be redirected to edit inspection page
      expect(page).to have_current_path(/\/inspections\/[A-Z0-9]+\/edit/)
      
      inspection = Inspection.last
      expect(inspection.unit_id).to eq(comprehensive_unit.id)
      
      # Verify all copyable attributes were copied from unit to inspection
      # Basic dimensions
      expect(inspection.width).to eq(12.5)
      expect(inspection.length).to eq(10.0)
      expect(inspection.height).to eq(4.5)
      expect(inspection.width_comment).to eq("Width comment")
      expect(inspection.length_comment).to eq("Length comment")
      expect(inspection.height_comment).to eq("Height comment")
      
      # Boolean flags
      expect(inspection.has_slide).to eq(true)
      expect(inspection.is_totally_enclosed).to eq(true)
      
      # Anchorage dimensions
      expect(inspection.num_low_anchors).to eq(6)
      expect(inspection.num_high_anchors).to eq(2)
      expect(inspection.num_low_anchors_comment).to eq("Low anchor comment")
      expect(inspection.num_high_anchors_comment).to eq("High anchor comment")
      
      # Structure dimensions
      expect(inspection.stitch_length).to eq(25.0)
      expect(inspection.unit_pressure_value).to eq(350.0)
      expect(inspection.blower_tube_length).to eq(12.0)
      expect(inspection.step_size_value).to eq(1.5)
      expect(inspection.fall_off_height_value).to eq(2.0)
      expect(inspection.trough_depth_value).to eq(0.8)
      expect(inspection.trough_width_value).to eq(1.2)
      
      # Slide dimensions
      expect(inspection.slide_platform_height).to eq(2.5)
      expect(inspection.slide_wall_height).to eq(1.8)
      expect(inspection.runout_value).to eq(6.0)
      expect(inspection.slide_first_metre_height).to eq(1.0)
      expect(inspection.slide_beyond_first_metre_height).to eq(0.5)
      expect(inspection.slide_permanent_roof).to eq(true)
      expect(inspection.slide_platform_height_comment).to eq("Platform height comment")
      expect(inspection.slide_wall_height_comment).to eq("Wall height comment")
      expect(inspection.runout_value_comment).to eq("Runout comment")
      expect(inspection.slide_first_metre_height_comment).to eq("First metre comment")
      expect(inspection.slide_beyond_first_metre_height_comment).to eq("Beyond first metre comment")
      expect(inspection.slide_permanent_roof_comment).to eq("Permanent roof comment")
      
      # User height dimensions
      expect(inspection.containing_wall_height).to eq(1.2)
      expect(inspection.platform_height).to eq(1.5)
      expect(inspection.tallest_user_height).to eq(1.8)
      expect(inspection.users_at_1000mm).to eq(8)
      expect(inspection.users_at_1200mm).to eq(10)
      expect(inspection.users_at_1500mm).to eq(12)
      expect(inspection.users_at_1800mm).to eq(15)
      expect(inspection.play_area_length).to eq(8.0)
      expect(inspection.play_area_width).to eq(6.0)
      expect(inspection.negative_adjustment).to eq(0.2)
      expect(inspection.permanent_roof).to eq(false)
      expect(inspection.containing_wall_height_comment).to eq("Containing wall comment")
      expect(inspection.platform_height_comment).to eq("Platform height comment")
      expect(inspection.permanent_roof_comment).to eq("Permanent roof comment")
      expect(inspection.play_area_length_comment).to eq("Play area length comment")
      expect(inspection.play_area_width_comment).to eq("Play area width comment")
      expect(inspection.negative_adjustment_comment).to eq("Negative adjustment comment")
      
      # Enclosed dimensions
      expect(inspection.exit_number).to eq(3)
      expect(inspection.exit_number_comment).to eq("Exit number comment")
      
      # Other dimensions
      expect(inspection.rope_size).to eq(18.0)
      expect(inspection.rope_size_comment).to eq("Rope size comment")
    end

    scenario "Replace dimensions button copies all attributes from unit" do
      # Create inspection with different dimensions
      inspection = create(:inspection,
        user: user,
        unit: comprehensive_unit,
        inspector_company: inspector_company,
        # Set different values to verify they get replaced
        width: 5.0,
        length: 4.0,
        height: 2.0,
        has_slide: false,
        is_totally_enclosed: false,
        num_low_anchors: 1,
        rope_size: 10.0
      )
      
      visit edit_inspection_path(inspection)
      
      # Click replace dimensions link (we can't test the confirmation dialog without JS)
      # So we'll test by directly making the request
      visit replace_dimensions_inspection_path(inspection)
      
      inspection.reload
      
      # Verify all attributes were replaced with unit values
      expect(inspection.width).to eq(12.5)
      expect(inspection.length).to eq(10.0) 
      expect(inspection.height).to eq(4.5)
      expect(inspection.has_slide).to eq(true)
      expect(inspection.is_totally_enclosed).to eq(true)
      expect(inspection.num_low_anchors).to eq(6)
      expect(inspection.rope_size).to eq(18.0)
      
      # Check a few more key attributes to ensure comprehensive copying
      expect(inspection.slide_platform_height).to eq(2.5)
      expect(inspection.exit_number).to eq(3)
      expect(inspection.users_at_1800mm).to eq(15)
    end
  end

  describe "Inspection -> Unit attribute copying" do
    let(:comprehensive_inspection) { create(:inspection, :with_comprehensive_dimensions, user: user, inspector_company: inspector_company) }

    scenario "Creating unit from inspection copies all attributes" do
      visit new_unit_from_inspection_path(comprehensive_inspection)
      
      # Fill in required unit-specific fields
      fill_in I18n.t("units.fields.name"), with: "Unit from Inspection"
      fill_in I18n.t("units.fields.serial"), with: "UFI-2024-001"
      fill_in I18n.t("units.fields.manufacturer"), with: "Inspection Manufacturer"
      fill_in I18n.t("units.fields.description"), with: "Unit created from comprehensive inspection"
      fill_in I18n.t("units.fields.owner"), with: "Inspection Owner Ltd"
      
      click_button I18n.t("units.buttons.create")
      
      # Should redirect to inspection with success message
      expect(current_path).to eq(inspection_path(comprehensive_inspection))
      expect(page).to have_content(I18n.t("units.messages.created_from_inspection"))
      
      unit = Unit.last
      comprehensive_inspection.reload
      expect(comprehensive_inspection.unit).to eq(unit)
      
      # Verify all copyable attributes were copied from inspection to unit
      # Basic dimensions
      expect(unit.width).to eq(15.0)
      expect(unit.length).to eq(12.0)
      expect(unit.height).to eq(5.0)
      expect(unit.width_comment).to eq("Inspection width comment")
      expect(unit.length_comment).to eq("Inspection length comment")
      expect(unit.height_comment).to eq("Inspection height comment")
      
      # Boolean flags
      expect(unit.has_slide).to eq(true)
      expect(unit.is_totally_enclosed).to eq(true)
      
      # Anchorage dimensions  
      expect(unit.num_low_anchors).to eq(8)
      expect(unit.num_high_anchors).to eq(4)
      expect(unit.num_low_anchors_comment).to eq("Inspection low anchor comment")
      expect(unit.num_high_anchors_comment).to eq("Inspection high anchor comment")
      
      # Structure dimensions
      expect(unit.stitch_length).to eq(30.0)
      expect(unit.unit_pressure_value).to eq(400.0)
      expect(unit.blower_tube_length).to eq(15.0)
      expect(unit.step_size_value).to eq(2.0)
      expect(unit.fall_off_height_value).to eq(2.5)
      expect(unit.trough_depth_value).to eq(1.0)
      expect(unit.trough_width_value).to eq(1.5)
      
      # Slide dimensions
      expect(unit.slide_platform_height).to eq(3.0)
      expect(unit.slide_wall_height).to eq(2.2)
      expect(unit.runout_value).to eq(8.0)
      expect(unit.slide_first_metre_height).to eq(1.2)
      expect(unit.slide_beyond_first_metre_height).to eq(0.8)
      expect(unit.slide_permanent_roof).to eq(false)
      expect(unit.slide_platform_height_comment).to eq("Inspection platform comment")
      expect(unit.slide_wall_height_comment).to eq("Inspection wall comment")
      expect(unit.runout_value_comment).to eq("Inspection runout comment")
      expect(unit.slide_first_metre_height_comment).to eq("Inspection first metre comment")
      expect(unit.slide_beyond_first_metre_height_comment).to eq("Inspection beyond first metre comment")
      expect(unit.slide_permanent_roof_comment).to eq("Inspection roof comment")
      
      # User height dimensions
      expect(unit.containing_wall_height).to eq(1.5)
      expect(unit.platform_height).to eq(1.8)
      expect(unit.user_height).to eq(2.0)
      expect(unit.users_at_1000mm).to eq(12)
      expect(unit.users_at_1200mm).to eq(15)
      expect(unit.users_at_1500mm).to eq(18)
      expect(unit.users_at_1800mm).to eq(20)
      expect(unit.play_area_length).to eq(10.0)
      expect(unit.play_area_width).to eq(8.0)
      expect(unit.negative_adjustment).to eq(0.3)
      expect(unit.permanent_roof).to eq(true)
      expect(unit.containing_wall_height_comment).to eq("Inspection containing wall comment")
      expect(unit.platform_height_comment).to eq("Inspection platform height comment")
      expect(unit.permanent_roof_comment).to eq("Inspection permanent roof comment")
      expect(unit.play_area_length_comment).to eq("Inspection play area length comment")
      expect(unit.play_area_width_comment).to eq("Inspection play area width comment")
      expect(unit.negative_adjustment_comment).to eq("Inspection negative adjustment comment")
      
      # Enclosed dimensions
      expect(unit.exit_number).to eq(5)
      expect(unit.exit_number_comment).to eq("Inspection exit number comment")
      
      # Other dimensions
      expect(unit.rope_size).to eq(22.0)
      expect(unit.rope_size_comment).to eq("Inspection rope size comment")
      
      # Verify unit-specific fields are what we set, not copied
      expect(unit.name).to eq("Unit from Inspection")
      expect(unit.serial).to eq("UFI-2024-001")
      expect(unit.manufacturer).to eq("Inspection Manufacturer")
      expect(unit.description).to eq("Unit created from comprehensive inspection")
      expect(unit.owner).to eq("Inspection Owner Ltd")
    end
  end

  describe "Unit selection and dimension replacement" do
    let(:original_unit) {
      create(:unit,
        user: user,
        name: "Original Unit",
        width: 10.0,
        length: 8.0,
        height: 3.5,
        has_slide: false,
        num_low_anchors: 4
      )
    }

    let(:new_unit) {
      create(:unit,
        user: user,
        name: "New Unit",
        width: 15.0,
        length: 12.0,
        height: 5.0,
        has_slide: true,
        num_low_anchors: 8,
        slide_platform_height: 2.5
      )
    }

    let(:inspection) {
      create(:inspection,
        user: user,
        unit: original_unit,
        inspector_company: inspector_company
      )
    }

    scenario "Changing unit selection copies attributes from new unit" do
      # Force creation of both units before visiting any pages
      original_unit
      new_unit
      
      visit edit_inspection_path(inspection)
      
      # Go to unit selection page
      click_link I18n.t("inspections.buttons.change_unit")
      expect(page).to have_current_path(select_unit_inspection_path(inspection))
      
      # Select the new unit
      within("li", text: new_unit.name) do
        click_button I18n.t("units.actions.select")
      end
      
      # Should redirect back to edit page
      expect(page).to have_current_path(edit_inspection_path(inspection))
      expect(page).to have_content(I18n.t("inspections.messages.unit_changed", unit_name: new_unit.name))
      
      inspection.reload
      
      # Verify inspection now has new unit and its attributes
      expect(inspection.unit).to eq(new_unit)
      expect(inspection.width).to eq(15.0)
      expect(inspection.length).to eq(12.0)
      expect(inspection.height).to eq(5.0)
      expect(inspection.has_slide).to eq(true)
      expect(inspection.num_low_anchors).to eq(8)
      expect(inspection.slide_platform_height).to eq(2.5)
    end
  end
end