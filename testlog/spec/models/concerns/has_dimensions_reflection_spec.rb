require "rails_helper"

RSpec.describe HasDimensions, type: :model do
  describe "Reflection-based attribute copying" do
    let(:inspector_company) { create(:inspector_company, active: true) }
    let(:user) { create(:user, inspection_company: inspector_company) }
    
    let(:source_unit) do
      create(:unit,
        user: user,
        name: "Source Test Unit",
        serial: "SRC-001",
        manufacturer: "Test Manufacturer",
        model: "Test Model",
        owner: "Test Owner",
        description: "Source unit for testing",
        manufacture_date: Date.new(2023, 1, 1),
        condition: "excellent",
        notes: "Source unit notes",
        
        # All copyable dimension fields
        width: 10.0,
        length: 8.0,
        height: 5.0,
        has_slide: true,
        is_totally_enclosed: false,
        
        # Comments for basic dimensions
        width_comment: "Source width comment",
        length_comment: "Source length comment",
        height_comment: "Source height comment",
        
        # Anchorage fields
        num_low_anchors: 6,
        num_high_anchors: 4,
        num_low_anchors_comment: "Source low anchors comment",
        num_high_anchors_comment: "Source high anchors comment",
        
        # Enclosed fields
        exit_number: 2,
        exit_number_comment: "Source exit comment",
        
        # Materials fields
        rope_size: 25.0,
        rope_size_comment: "Source rope comment",
        
        # Slide fields
        slide_platform_height: 3.0,
        slide_wall_height: 2.0,
        runout_value: 4.0,
        slide_first_metre_height: 1.0,
        slide_beyond_first_metre_height: 0.5,
        slide_permanent_roof: true,
        slide_platform_height_comment: "Source platform comment",
        slide_wall_height_comment: "Source wall comment",
        runout_value_comment: "Source runout comment",
        slide_first_metre_height_comment: "Source first metre comment",
        slide_beyond_first_metre_height_comment: "Source beyond first metre comment",
        slide_permanent_roof_comment: "Source roof comment",
        
        # Structure fields
        stitch_length: 15.0,
        unit_pressure_value: 300.0,
        blower_tube_length: 3.5,
        step_size_value: 250.0,
        fall_off_height_value: 1.5,
        trough_depth_value: 0.3,
        trough_width_value: 0.8,
        
        # User height fields
        containing_wall_height: 1.8,
        platform_height: 1.2,
        user_height: 1.6,
        users_at_1000mm: 5,
        users_at_1200mm: 8,
        users_at_1500mm: 10,
        users_at_1800mm: 12,
        play_area_length: 7.0,
        play_area_width: 9.0,
        negative_adjustment: 0.5,
        permanent_roof: false,
        containing_wall_height_comment: "Source containing wall comment",
        platform_height_comment: "Source platform comment",
        permanent_roof_comment: "Source permanent roof comment",
        play_area_length_comment: "Source play area length comment",
        play_area_width_comment: "Source play area width comment",
        negative_adjustment_comment: "Source negative adjustment comment"
      )
    end
    
    let(:target_inspection) do
      create(:inspection,
        user: user,
        inspector_company: inspector_company,
        inspection_location: "Test Location"
      )
    end

    describe "reflection-based field detection" do
      it "identifies all copyable attributes from Unit model" do
        unit_columns = Unit.column_names
        inspection_columns = Inspection.column_names
        
        # Find common attributes between Unit and Inspection
        common_attributes = unit_columns & inspection_columns
        
        # Attributes that should never be copied (system fields, IDs, etc.)
        excluded_attributes = %w[
          id created_at updated_at user_id unit_id inspection_id
          unique_report_number status passed comments recommendations
          general_notes inspector_signature signature_timestamp
          pdf_last_accessed_at inspection_date inspection_location
          name serial manufacturer model owner description
          manufacture_date condition notes serial_number
        ]
        
        # Calculate expected copyable attributes
        expected_copyable = common_attributes - excluded_attributes
        
        expect(expected_copyable).to be_present
        expect(expected_copyable.length).to be >= 40 # Should have many dimension fields
        
        # Verify some key fields are included
        expect(expected_copyable).to include("width", "length", "height")
        expect(expected_copyable).to include("has_slide", "is_totally_enclosed")
        expect(expected_copyable).to include("num_low_anchors", "num_high_anchors")
        expect(expected_copyable).to include("slide_platform_height", "runout_value")
      end
      
      it "excludes non-copyable attributes correctly" do
        unit_columns = Unit.column_names
        inspection_columns = Inspection.column_names
        common_attributes = unit_columns & inspection_columns
        
        # These should NOT be in copyable attributes
        non_copyable = %w[id created_at updated_at user_id]
        
        non_copyable.each do |attr|
          if common_attributes.include?(attr)
            # If it's in common_attributes, copy_shared_attributes should exclude it
            expect(Unit.new.send(:excluded_copyable_attributes)).to include(attr)
          end
        end
      end
    end

    describe "copy_attributes_from with reflection" do
      it "copies all expected dimension fields from unit to inspection" do
        target_inspection.copy_attributes_from(source_unit)
        
        # Basic dimensions
        expect(target_inspection.width).to eq(source_unit.width)
        expect(target_inspection.length).to eq(source_unit.length)
        expect(target_inspection.height).to eq(source_unit.height)
        expect(target_inspection.has_slide).to eq(source_unit.has_slide)
        expect(target_inspection.is_totally_enclosed).to eq(source_unit.is_totally_enclosed)
        
        # Comments
        expect(target_inspection.width_comment).to eq(source_unit.width_comment)
        expect(target_inspection.length_comment).to eq(source_unit.length_comment)
        expect(target_inspection.height_comment).to eq(source_unit.height_comment)
        
        # Anchorage
        expect(target_inspection.num_low_anchors).to eq(source_unit.num_low_anchors)
        expect(target_inspection.num_high_anchors).to eq(source_unit.num_high_anchors)
        expect(target_inspection.num_low_anchors_comment).to eq(source_unit.num_low_anchors_comment)
        expect(target_inspection.num_high_anchors_comment).to eq(source_unit.num_high_anchors_comment)
        
        # Slide fields
        expect(target_inspection.slide_platform_height).to eq(source_unit.slide_platform_height)
        expect(target_inspection.slide_wall_height).to eq(source_unit.slide_wall_height)
        expect(target_inspection.runout_value).to eq(source_unit.runout_value)
        expect(target_inspection.slide_platform_height_comment).to eq(source_unit.slide_platform_height_comment)
        
        # Structure fields
        expect(target_inspection.stitch_length).to eq(source_unit.stitch_length)
        expect(target_inspection.unit_pressure_value).to eq(source_unit.unit_pressure_value)
        expect(target_inspection.blower_tube_length).to eq(source_unit.blower_tube_length)
      end
      
      it "does not copy non-copyable attributes" do
        original_inspection_id = target_inspection.id
        original_created_at = target_inspection.created_at
        original_user_id = target_inspection.user_id
        
        target_inspection.copy_attributes_from(source_unit)
        
        # These should remain unchanged
        expect(target_inspection.id).to eq(original_inspection_id)
        expect(target_inspection.created_at).to eq(original_created_at)
        expect(target_inspection.user_id).to eq(original_user_id)
        
        # Unit-specific fields should not be copied (these don't exist as database columns on Inspection)
        expect(target_inspection.attribute_names).not_to include("name")
        expect(target_inspection.attribute_names).not_to include("serial")
        expect(target_inspection.attribute_names).not_to include("manufacturer")
      end
      
      it "copies in reverse direction (inspection to unit)" do
        target_unit = create(:unit, user: user, name: "Target Unit", serial: "TGT-001")
        
        # Set some values on the inspection
        target_inspection.update!(
          width: 15.0,
          length: 12.0,
          height: 6.0,
          has_slide: false,
          num_low_anchors: 8,
          width_comment: "Inspection width comment"
        )
        
        target_unit.copy_attributes_from(target_inspection)
        
        expect(target_unit.width).to eq(target_inspection.width)
        expect(target_unit.length).to eq(target_inspection.length)
        expect(target_unit.height).to eq(target_inspection.height)
        expect(target_unit.has_slide).to eq(target_inspection.has_slide)
        expect(target_unit.num_low_anchors).to eq(target_inspection.num_low_anchors)
        expect(target_unit.width_comment).to eq(target_inspection.width_comment)
        
        # Unit-specific fields should remain unchanged
        expect(target_unit.name).to eq("Target Unit")
        expect(target_unit.serial).to eq("TGT-001")
      end
    end

    describe "reflection-based approach completeness" do
      it "includes all expected dimension and comment fields" do
        # Get reflection-based copyable attributes
        unit_columns = Unit.column_names.map(&:to_sym)
        inspection_columns = Inspection.column_names.map(&:to_sym)
        common_attributes = unit_columns & inspection_columns
        
        # These are core fields that should definitely be included
        expected_core_attributes = %i[
          width length height has_slide is_totally_enclosed
          width_comment length_comment height_comment
          num_low_anchors num_high_anchors
          slide_platform_height runout_value
          stitch_length unit_pressure_value
        ]
        
        # All expected core attributes should be in the common attributes
        missing_core = expected_core_attributes - common_attributes
        expect(missing_core).to be_empty, 
          "These core attributes are missing from reflection: #{missing_core}"
      end
      
      it "reflection approach doesn't include extra unwanted fields" do
        unit_columns = Unit.column_names.map(&:to_sym)
        inspection_columns = Inspection.column_names.map(&:to_sym)
        common_attributes = unit_columns & inspection_columns
        
        # Fields that should be excluded
        excluded = %i[
          id created_at updated_at user_id unit_id inspection_id
          unique_report_number status passed comments recommendations
          general_notes inspector_signature signature_timestamp
          pdf_last_accessed_at inspection_date inspection_location
          name serial manufacturer model owner description
          manufacture_date condition notes serial_number
        ]
        
        # Check that excluded fields are present in common attributes (they exist on both models)
        # but should be handled by the exclusion logic
        problematic_fields = common_attributes & excluded
        expect(problematic_fields).to include(:id, :created_at, :updated_at, :user_id)
        
        # Verify that these are properly excluded by our exclusion method
        unit = Unit.new
        excluded_attrs = unit.send(:excluded_copyable_attributes)
        problematic_fields.each do |field|
          expect(excluded_attrs).to include(field.to_s), 
            "Field #{field} should be in excluded_copyable_attributes"
        end
      end
    end

    describe "edge cases and robustness" do
      it "handles nil source gracefully" do
        original_width = target_inspection.width
        expect { target_inspection.copy_attributes_from(nil) }.not_to raise_error
        expect(target_inspection.width).to eq(original_width) # Should remain unchanged
      end
      
      it "handles source without attributes method" do
        fake_source = Object.new
        expect { target_inspection.copy_attributes_from(fake_source) }.not_to raise_error
      end
      
      it "handles false values correctly" do
        source_unit.update!(has_slide: false, is_totally_enclosed: false, permanent_roof: false)
        target_inspection.copy_attributes_from(source_unit)
        
        expect(target_inspection.has_slide).to be false
        expect(target_inspection.is_totally_enclosed).to be false
        expect(target_inspection.permanent_roof).to be false
      end
      
      it "handles zero values correctly" do
        source_unit.update!(
          num_low_anchors: 0, 
          users_at_1000mm: 0, 
          negative_adjustment: 0.0
        )
        target_inspection.copy_attributes_from(source_unit)
        
        expect(target_inspection.num_low_anchors).to eq(0)
        expect(target_inspection.users_at_1000mm).to eq(0)
        expect(target_inspection.negative_adjustment).to eq(0.0)
      end
    end
  end

  describe "method to get excluded attributes" do
    it "defines excluded_copyable_attributes method" do
      unit = Unit.new
      expect(unit.respond_to?(:excluded_copyable_attributes, true)).to be true # true = include private methods
      
      excluded = unit.send(:excluded_copyable_attributes)
      expect(excluded).to include("id", "created_at", "updated_at")
      expect(excluded).to be_an(Array)
      expect(excluded).to all(be_a(String))
    end
  end
end