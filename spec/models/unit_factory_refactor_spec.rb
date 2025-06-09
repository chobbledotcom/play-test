require "rails_helper"

RSpec.describe "Unit Factory Refactoring" do
  describe "with_comprehensive_dimensions trait" do
    it "produces the same attributes as the original factory" do
      # Create units with both factories
      original_unit = build(:unit, :with_comprehensive_dimensions)
      
      # Temporarily load the refactored factory
      FactoryBot.factories.clear
      load Rails.root.join("spec/factories/units_refactored.rb")
      refactored_unit = build(:unit, :with_comprehensive_dimensions)
      
      # Compare all dimension attributes
      dimension_attributes = %w[
        width length height
        width_comment length_comment height_comment
        num_low_anchors num_high_anchors
        num_low_anchors_comment num_high_anchors_comment
        stitch_length evacuation_time unit_pressure_value
        blower_tube_length step_size_value fall_off_height_value
        trough_depth_value trough_width_value
        slide_platform_height slide_wall_height runout_value
        slide_first_metre_height slide_beyond_first_metre_height
        slide_permanent_roof
        slide_platform_height_comment slide_wall_height_comment
        runout_value_comment slide_first_metre_height_comment
        slide_beyond_first_metre_height_comment slide_permanent_roof_comment
        containing_wall_height platform_height tallest_user_height
        users_at_1000mm users_at_1200mm users_at_1500mm users_at_1800mm
        play_area_length play_area_width negative_adjustment permanent_roof
        containing_wall_height_comment platform_height_comment
        permanent_roof_comment play_area_length_comment
        play_area_width_comment negative_adjustment_comment
        exit_number exit_number_comment
        rope_size rope_size_comment
        has_slide is_totally_enclosed
      ]
      
      dimension_attributes.each do |attr|
        expect(refactored_unit.send(attr)).to eq(original_unit.send(attr)),
          "Attribute '#{attr}' differs: refactored=#{refactored_unit.send(attr)}, original=#{original_unit.send(attr)}"
      end
      
      # Compare basic attributes
      expect(refactored_unit.name).to eq(original_unit.name)
      expect(refactored_unit.manufacturer).to eq(original_unit.manufacturer)
      expect(refactored_unit.model).to eq(original_unit.model)
      expect(refactored_unit.serial).to eq(original_unit.serial)
      expect(refactored_unit.description).to eq(original_unit.description)
      expect(refactored_unit.owner).to eq(original_unit.owner)
      expect(refactored_unit.manufacture_date).to eq(original_unit.manufacture_date)
      expect(refactored_unit.notes).to eq(original_unit.notes)
    end
  end
  
  describe "trait composition" do
    before do
      FactoryBot.factories.clear
      load Rails.root.join("spec/factories/units_refactored.rb")
    end
    
    it "allows combining multiple dimension traits" do
      unit = build(:unit, :with_slide_dimensions, :with_anchorage_dimensions, :with_user_height_dimensions)
      
      # Check slide dimensions
      expect(unit.has_slide).to be true
      expect(unit.slide_platform_height).to eq(1.8)
      expect(unit.runout_value).to eq(4.0)
      
      # Check anchorage dimensions
      expect(unit.num_low_anchors).to eq(6)
      expect(unit.num_high_anchors).to eq(2)
      
      # Check user height dimensions
      expect(unit.containing_wall_height).to eq(1.2)
      expect(unit.users_at_1000mm).to eq(8)
    end
    
    it "allows overriding specific values after trait application" do
      unit = build(:unit, :with_slide_dimensions, slide_platform_height: 3.5)
      
      expect(unit.slide_platform_height).to eq(3.5)
      expect(unit.slide_wall_height).to eq(1.5) # Other values unchanged
    end
  end
  
  describe "with_inspection_copying_dimensions trait" do
    before do
      FactoryBot.factories.clear
      load Rails.root.join("spec/factories/units_refactored.rb")
    end
    
    it "inherits from comprehensive dimensions but overrides specific values" do
      unit = build(:unit, :with_inspection_copying_dimensions)
      
      # Check overridden values
      expect(unit.name).to eq("Inspection Copy Test Unit")
      expect(unit.width).to eq(15.0)
      expect(unit.slide_platform_height).to eq(3.0)
      expect(unit.users_at_1000mm).to eq(12)
      
      # Check inherited values that weren't overridden
      expect(unit.stitch_length).to eq(25.0) # From structure dimensions
      expect(unit.num_low_anchors).to eq(6) # From anchorage dimensions
    end
  end
  
  # Clean up by reloading original factory
  after(:all) do
    FactoryBot.factories.clear
    FactoryBot.reload
  end
end