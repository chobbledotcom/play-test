require "rails_helper"

RSpec.describe SafetyStandard, "Constants" do
  describe "ANCHOR_CALCULATION_CONSTANTS" do
    it "defines expected anchor calculation values" do
      constants = SafetyStandards::AnchorCalculator::ANCHOR_CALCULATION_CONSTANTS

      expect(constants[:area_coefficient]).to eq(114.0)
      expect(constants[:base_divisor]).to eq(1600.0)
      expect(constants[:safety_factor]).to eq(1.5)
      expect(constants[:minimum_anchors]).to eq(6)
    end

    it "is used in anchor calculations" do
      # Verify the calculation uses these exact constant values
      # For a 5x5x3 unit (25m² base area)
      length = 5.0
      width = 5.0
      height = 3.0

      result = SafetyStandards::AnchorCalculator.calculate(length: length, width: width, height: height)
      expect(result.value).to eq(8) # Known result for 5x5x3 unit
    end
  end

  describe "RUNOUT_CALCULATION_CONSTANTS" do
    it "defines expected runout calculation values" do
      constants = SafetyStandards::SlideCalculator::RUNOUT_CALCULATION_CONSTANTS

      expect(constants[:platform_height_ratio]).to eq(0.5)
      expect(constants[:minimum_runout_meters]).to eq(0.3)
      expect(constants[:stop_wall_addition]).to eq(0.5)
    end

    it "is used in runout calculations" do
      platform_height = 2.5
      expected = [ platform_height * 0.5, 0.3 ].max

      result = SafetyStandards::SlideCalculator.calculate_required_runout(platform_height)
      expect(result.value).to eq(expected)
      expect(result.value).to eq(1.25)

      # Test with stop-wall
      result_with_wall = SafetyStandards::SlideCalculator.calculate_required_runout(platform_height, has_stop_wall: true)
      expect(result_with_wall.value).to eq(1.75) # 1.25 + 0.5
    end
  end

  describe "WALL_HEIGHT_CONSTANTS" do
    it "defines expected wall height multiplier" do
      constants = SafetyStandards::SlideCalculator::WALL_HEIGHT_CONSTANTS

      expect(constants[:enhanced_height_multiplier]).to eq(1.25)
    end

    it "is used in wall height calculations" do
      platform_height = 4.0 # In the enhanced walls range (3.0m - 6.0m)
      user_height = 4.0
      containing_wall_height = 5.0 # 4.0 * 1.25 = 5.0
      has_permanent_roof = false

      result = SafetyStandards::SlideCalculator.meets_height_requirements?(platform_height, user_height, containing_wall_height, has_permanent_roof)
      expect(result).to be true

      # Test that it fails with insufficient wall height (and no roof)
      insufficient_wall = 4.9 # Just under 4.0 * 1.25
      result = SafetyStandards::SlideCalculator.meets_height_requirements?(platform_height, user_height, insufficient_wall, has_permanent_roof)
      expect(result).to be false

      # Test that roof provides an alternative for enhanced walls range
      result_with_roof = SafetyStandards::SlideCalculator.meets_height_requirements?(platform_height, user_height, insufficient_wall, true)
      expect(result_with_roof).to be true
    end
  end

  describe "source code transparency" do
    it "includes constants in method source display" do
      source = SafetyStandard.get_method_source(:calculate, SafetyStandards::AnchorCalculator)

      # Verify constants are shown
      expect(source).to include("ANCHOR_CALCULATION_CONSTANTS")
      expect(source).to include("area_coefficient: 114.0")
      expect(source).to include("base_divisor: 1600.0")
      expect(source).to include("safety_factor: 1.5")
      expect(source).to include("minimum_anchors: 6")

      # Verify method implementation is shown
      expect(source).to include("def calculate")
      expect(source).to include("ANCHOR_CALCULATION_CONSTANTS[:area_coefficient]")
      expect(source).to include("ANCHOR_CALCULATION_CONSTANTS[:minimum_anchors]")
    end

    it "shows multiple constants for methods that use them" do
      source = SafetyStandard.get_method_source(:meets_height_requirements?, SafetyStandards::SlideCalculator)

      # Should include both constant definitions
      expect(source).to include("SLIDE_HEIGHT_THRESHOLDS")
      expect(source).to include("WALL_HEIGHT_CONSTANTS")
      expect(source).to include("enhanced_height_multiplier: 1.25")
      # Should show the updated method signature with roof parameter
      expect(source).to include("has_permanent_roof")
    end
  end

  describe "no magic numbers remain" do
    it "uses constants throughout the codebase" do
      # Verify no hardcoded magic numbers in key calculations
      source_file = Rails.root.join("app/services/safety_standard.rb").read

      # These magic numbers should no longer appear in calculation methods
      # (except in the constants definitions themselves)
      calculation_methods = source_file.split(/def calculate_|def meets_height_|def valid_|def requires_/)[1..]

      calculation_methods.each do |method_content|
        method_lines = method_content.split("\n")
        next if method_lines.empty?

        # Skip the method that just defines constants
        next if method_lines.first.include?("calculation_metadata")

        # Check that magic numbers aren't hardcoded in calculations
        expect(method_content).not_to include("* 114.0"), "Found hardcoded 114.0 in calculation method"
        expect(method_content).not_to include("/ 1600.0"), "Found hardcoded 1600.0 in calculation method"
        expect(method_content).not_to include("* 1.5"), "Found hardcoded 1.5 in calculation method (outside comments)"
        expect(method_content).not_to include("/ 1.5"), "Found hardcoded 1.5 in calculation method"
        expect(method_content).not_to include("/ 2.0"), "Found hardcoded 2.0 in calculation method"
        expect(method_content).not_to include("/ 2.5"), "Found hardcoded 2.5 in calculation method"
        expect(method_content).not_to include("/ 3.0"), "Found hardcoded 3.0 in calculation method"
        expect(method_content).not_to include("* 0.5"), "Found hardcoded 0.5 in calculation method"
        expect(method_content).not_to include(">= 1.0"), "Found hardcoded 1.0 in validation method"
        expect(method_content).not_to include("<= 0.6"), "Found hardcoded 0.6 in validation method"
        expect(method_content).not_to include("between?(3, 8)"), "Found hardcoded 3,8 in validation method"
        expect(method_content).not_to include("between?(18, 45)"), "Found hardcoded 18,45 in validation method"
        expect(method_content).not_to include("> 15"), "Found hardcoded 15 in validation method"
      end
    end

    it "validates new constants exist and are used" do
      # Check new constants are defined
      expect(SafetyStandards::MaterialValidator::MATERIAL_STANDARDS).to be_present
      expect(SafetyStandard::GROUNDING_TEST_WEIGHTS).to be_present
      expect(SafetyStandard::REINSPECTION_INTERVAL_DAYS).to eq(365)

      # Check validation methods use constants
      expect(SafetyStandards::MaterialValidator.valid_stitch_length?(5)).to be true
      expect(SafetyStandards::MaterialValidator.valid_stitch_length?(2)).to be false # Below min
      expect(SafetyStandards::MaterialValidator.valid_stitch_length?(9)).to be false # Above max
    end

    it "generates consistent formula descriptions from constants" do
      anchor_metadata = SafetyStandard.calculation_metadata[:anchors]
      runout_metadata = SafetyStandard.calculation_metadata[:slide_runout]

      # Formula text should include actual constant values
      expect(anchor_metadata[:formula_text]).to include("114.0")
      expect(anchor_metadata[:formula_text]).to include("1600.0")
      expect(anchor_metadata[:formula_text]).to include("1.5")

      expect(runout_metadata[:formula_text]).to include("50%")
      expect(runout_metadata[:formula_text]).to include("300mm")
    end
  end
end
