require "rails_helper"

RSpec.describe SafetyStandard, type: :model do
  # Helper methods for testing
  def meets_height_requirements?(*args)
    SafetyStandards::SlideCalculator.meets_height_requirements?(*args)
  end

  def meets_runout_requirements?(*args)
    SafetyStandards::SlideCalculator.meets_runout_requirements?(*args)
  end

  def calculate_required_runout(*args)
    SafetyStandards::SlideCalculator.calculate_required_runout(*args)
  end

  def calculate_required_anchors(*args)
    SafetyStandards::AnchorCalculator.calculate_required_anchors(*args)
  end

  describe "HEIGHT_CATEGORIES" do
    it "has correct height categories with labels" do
      expect(SafetyStandard::HEIGHT_CATEGORIES).to include(
        1000 => {label: "1.0m (Young children)", max_users: :calculate_by_area},
        1200 => {label: "1.2m (Children)", max_users: :calculate_by_area},
        1500 => {label: "1.5m (Adolescents)", max_users: :calculate_by_area},
        1800 => {label: "1.8m (Adults)", max_users: :calculate_by_area}
      )
    end
  end

  describe "SLIDE_HEIGHT_THRESHOLDS" do
    it "has correct safety thresholds" do
      expect(SafetyStandards::SlideCalculator::SLIDE_HEIGHT_THRESHOLDS).to eq({
        no_walls_required: 0.6,
        basic_walls: 3.0,
        enhanced_walls: 6.0,
        max_safe_height: 8.0
      })
    end
  end

  describe ".height_categories" do
    it "returns the HEIGHT_CATEGORIES constant" do
      expect(SafetyStandard.height_categories).to eq(SafetyStandard::HEIGHT_CATEGORIES)
    end
  end

  describe ".meets_height_requirements?" do
    # Test all valid examples
    SafetyStandards::SlideCalculator::HEIGHT_TEST_EXAMPLES[:valid].each do |scenario, params|
      it "returns true for valid scenario: #{scenario}" do
        expect(meets_height_requirements?(*params)).to be true
      end
    end

    # Test all invalid examples
    SafetyStandards::SlideCalculator::HEIGHT_TEST_EXAMPLES[:invalid].each do |scenario, params|
      it "returns false for invalid scenario: #{scenario}" do
        expect(meets_height_requirements?(*params)).to be false
      end
    end
  end

  describe ".meets_runout_requirements?" do
    # Test all valid examples
    SafetyStandards::SlideCalculator::RUNOUT_TEST_EXAMPLES[:valid].each do |scenario, params|
      it "returns true for valid scenario: #{scenario}" do
        expect(meets_runout_requirements?(*params)).to be true
      end
    end

    # Test all invalid examples
    SafetyStandards::SlideCalculator::RUNOUT_TEST_EXAMPLES[:invalid].each do |scenario, params|
      it "returns false for invalid scenario: #{scenario}" do
        expect(meets_runout_requirements?(*params)).to be false
      end
    end
  end

  describe ".calculate_required_runout" do
    context "with nil or invalid inputs" do
      it "returns 0 for nil platform_height" do
        expect(calculate_required_runout(nil)).to eq(0)
      end

      it "returns 0 for zero or negative platform_height" do
        expect(calculate_required_runout(0)).to eq(0)
        expect(calculate_required_runout(-1.0)).to eq(0)
      end
    end

    context "with valid inputs" do
      it "calculates 50% of platform height" do
        expect(calculate_required_runout(2.0)).to eq(1.0)
        expect(calculate_required_runout(4.0)).to eq(2.0)
      end

      it "enforces minimum 300mm (0.3m)" do
        expect(calculate_required_runout(0.4)).to eq(0.3) # 50% would be 0.2m
        expect(calculate_required_runout(0.1)).to eq(0.3) # 50% would be 0.05m
      end
    end
  end

  describe ".calculate_required_anchors" do
    # Test basic area calculations
    SafetyStandards::AnchorCalculator::ANCHOR_TEST_EXAMPLES[:basic].each do |scenario, data|
      it "calculates anchors correctly for #{scenario}" do
        expect(calculate_required_anchors(data[:input])).to eq(data[:expected])
      end
    end

    # Test invalid inputs
    SafetyStandards::AnchorCalculator::ANCHOR_TEST_EXAMPLES[:invalid].each do |scenario, data|
      it "returns 0 for #{scenario}" do
        expect(calculate_required_anchors(data[:input])).to eq(data[:expected])
      end
    end
  end

  describe ".calculate" do
    # Test full unit calculations
    SafetyStandards::AnchorCalculator::ANCHOR_TEST_EXAMPLES[:units].each do |scenario, data|
      it "calculates total anchors correctly for #{scenario}" do
        result = SafetyStandards::AnchorCalculator.calculate(**data[:dimensions])
        expect(result[:required_anchors]).to eq(data[:expected_anchors])
        expect(result[:formula_breakdown]).to be_an(Array)
        expect(result[:formula_breakdown].size).to eq(5)
      end
    end
  end

  describe "validation methods" do
    describe ".valid_stitch_length?" do
      # Test valid stitch lengths
      SafetyStandards::MaterialValidator::MATERIAL_TEST_EXAMPLES[:stitch_length][:valid].each do |scenario, value|
        it "returns true for #{scenario}: #{value}mm" do
          expect(SafetyStandards::MaterialValidator.valid_stitch_length?(value)).to be true
        end
      end

      # Test invalid stitch lengths
      SafetyStandards::MaterialValidator::MATERIAL_TEST_EXAMPLES[:stitch_length][:invalid].each do |scenario, value|
        it "returns false for #{scenario}: #{value.inspect}" do
          expect(SafetyStandards::MaterialValidator.valid_stitch_length?(value)).to be false
        end
      end
    end


    describe ".valid_rope_diameter?" do
      # Test valid rope diameters
      SafetyStandards::MaterialValidator::MATERIAL_TEST_EXAMPLES[:rope_diameter][:valid].each do |scenario, value|
        it "returns true for #{scenario}: #{value}mm" do
          expect(SafetyStandards::MaterialValidator.valid_rope_diameter?(value)).to be true
        end
      end

      # Test invalid rope diameters
      SafetyStandards::MaterialValidator::MATERIAL_TEST_EXAMPLES[:rope_diameter][:invalid].each do |scenario, value|
        it "returns false for #{scenario}: #{value.inspect}" do
          expect(SafetyStandards::MaterialValidator.valid_rope_diameter?(value)).to be false
        end
      end
    end

    describe ".requires_permanent_roof?" do
      it "returns true for heights requiring permanent roof (>6.0m)" do
        expect(SafetyStandards::SlideCalculator.requires_permanent_roof?(6.5)).to be true
        expect(SafetyStandards::SlideCalculator.requires_permanent_roof?(7.0)).to be true
      end

      it "returns false for heights not requiring permanent roof (≤6.0m)" do
        expect(SafetyStandards::SlideCalculator.requires_permanent_roof?(5.0)).to be false
        expect(SafetyStandards::SlideCalculator.requires_permanent_roof?(6.0)).to be false
        expect(SafetyStandards::SlideCalculator.requires_permanent_roof?(nil)).to be false
      end
    end

  end

  describe "informational methods" do
    describe ".slide_calculations" do
      it "returns slide calculation information" do
        result = SafetyStandard.slide_calculations

        expect(result).to have_key(:containing_wall_heights)
        expect(result).to have_key(:runout_requirements)
        expect(result).to have_key(:safety_factors)
        expect(result[:containing_wall_heights]).to include(:under_600mm, :between_600_3000mm)
      end
    end
  end
end
