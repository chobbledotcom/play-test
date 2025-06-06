require "rails_helper"

RSpec.describe SafetyStandard, type: :model do
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
      expect(SafetyStandard::SLIDE_HEIGHT_THRESHOLDS).to eq({
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
    context "with nil values" do
      it "returns false when user_height is nil" do
        expect(SafetyStandard.meets_height_requirements?(nil, 2.0)).to be false
      end

      it "returns false when containing_wall_height is nil" do
        expect(SafetyStandard.meets_height_requirements?(1.5, nil)).to be false
      end
    end

    context "no walls required (under 0.6m)" do
      it "returns true for heights under 0.6m" do
        expect(SafetyStandard.meets_height_requirements?(0.5, 0)).to be true
        expect(SafetyStandard.meets_height_requirements?(0.3, 0)).to be true
      end
    end

    context "basic walls required (0.6m - 3.0m)" do
      it "requires containing wall height >= user height" do
        expect(SafetyStandard.meets_height_requirements?(1.5, 1.5)).to be true
        expect(SafetyStandard.meets_height_requirements?(2.0, 2.5)).to be true
        expect(SafetyStandard.meets_height_requirements?(2.0, 1.8)).to be false
      end
    end

    context "enhanced walls required (3.0m - 6.0m)" do
      it "requires containing wall height >= 1.25 times user height" do
        expect(SafetyStandard.meets_height_requirements?(4.0, 5.0)).to be true
        expect(SafetyStandard.meets_height_requirements?(4.0, 4.8)).to be false
        expect(SafetyStandard.meets_height_requirements?(5.0, 6.25)).to be true
      end
    end

    context "maximum height range (6.0m - 8.0m)" do
      it "requires containing wall height >= 1.25 times user height plus permanent roof" do
        expect(SafetyStandard.meets_height_requirements?(7.0, 8.75)).to be true
        expect(SafetyStandard.meets_height_requirements?(7.0, 8.0)).to be false
      end
    end

    context "exceeds safe height limits (over 8.0m)" do
      it "returns false for heights over 8.0m" do
        expect(SafetyStandard.meets_height_requirements?(9.0, 12.0)).to be false
        expect(SafetyStandard.meets_height_requirements?(10.0, 15.0)).to be false
      end
    end
  end

  describe ".meets_runout_requirements?" do
    context "with nil values" do
      it "returns false when runout_length is nil" do
        expect(SafetyStandard.meets_runout_requirements?(nil, 2.0)).to be false
      end

      it "returns false when platform_height is nil" do
        expect(SafetyStandard.meets_runout_requirements?(1.5, nil)).to be false
      end
    end

    context "with valid inputs" do
      it "returns true when runout meets requirements" do
        expect(SafetyStandard.meets_runout_requirements?(1.0, 2.0)).to be true # 50% = 1.0m
        expect(SafetyStandard.meets_runout_requirements?(0.5, 1.0)).to be true # 50% = 0.5m
      end

      it "returns false when runout is insufficient" do
        expect(SafetyStandard.meets_runout_requirements?(0.8, 2.0)).to be false # Needs 1.0m
        expect(SafetyStandard.meets_runout_requirements?(0.2, 1.0)).to be false # Needs 0.5m
      end

      it "enforces minimum 300mm runout" do
        expect(SafetyStandard.meets_runout_requirements?(0.3, 0.1)).to be true # Min 0.3m
        expect(SafetyStandard.meets_runout_requirements?(0.25, 0.1)).to be false # Below min
      end
    end
  end

  describe ".calculate_required_runout" do
    context "with nil or invalid inputs" do
      it "returns 0 for nil platform_height" do
        expect(SafetyStandard.calculate_required_runout(nil)).to eq(0)
      end

      it "returns 0 for zero or negative platform_height" do
        expect(SafetyStandard.calculate_required_runout(0)).to eq(0)
        expect(SafetyStandard.calculate_required_runout(-1.0)).to eq(0)
      end
    end

    context "with valid inputs" do
      it "calculates 50% of platform height" do
        expect(SafetyStandard.calculate_required_runout(2.0)).to eq(1.0)
        expect(SafetyStandard.calculate_required_runout(4.0)).to eq(2.0)
      end

      it "enforces minimum 300mm (0.3m)" do
        expect(SafetyStandard.calculate_required_runout(0.4)).to eq(0.3) # 50% would be 0.2m
        expect(SafetyStandard.calculate_required_runout(0.1)).to eq(0.3) # 50% would be 0.05m
      end
    end
  end

  describe ".calculate_required_anchors" do
    context "with nil or invalid inputs" do
      it "returns 0 for nil area" do
        expect(SafetyStandard.calculate_required_anchors(nil)).to eq(0)
      end

      it "returns 0 for zero or negative area" do
        expect(SafetyStandard.calculate_required_anchors(0)).to eq(0)
        expect(SafetyStandard.calculate_required_anchors(-5.0)).to eq(0)
      end
    end

    context "with valid inputs" do
      it "calculates anchors using the formula ((Area² * 114)/1600) * 1.5, rounded up" do
        # For 25m²: ((25² * 114)/1600) * 1.5 = (71250/1600) * 1.5 = 66.796875 → 67
        expect(SafetyStandard.calculate_required_anchors(25)).to eq(67)

        # For 10m²: ((10² * 114)/1600) * 1.5 = (11400/1600) * 1.5 = 10.6875 → 11
        expect(SafetyStandard.calculate_required_anchors(10)).to eq(11)

        # For 5m²: ((5² * 114)/1600) * 1.5 = (2850/1600) * 1.5 = 2.671875 → 3
        expect(SafetyStandard.calculate_required_anchors(5)).to eq(3)
      end
    end
  end

  describe ".calculate_user_capacity" do
    context "with nil inputs" do
      it "returns empty hash for nil length" do
        expect(SafetyStandard.calculate_user_capacity(nil, 5.0)).to eq({})
      end

      it "returns empty hash for nil width" do
        expect(SafetyStandard.calculate_user_capacity(10.0, nil)).to eq({})
      end
    end

    context "with invalid area" do
      it "returns empty hash when usable area is zero or negative" do
        expect(SafetyStandard.calculate_user_capacity(5.0, 4.0, 20.0)).to eq({}) # 20-20=0
        expect(SafetyStandard.calculate_user_capacity(5.0, 4.0, 25.0)).to eq({}) # 20-25=-5
      end
    end

    context "with valid inputs" do
      it "calculates capacity for each age group" do
        result = SafetyStandard.calculate_user_capacity(10.0, 5.0) # 50m² area

        expect(result).to eq({
          users_1000mm: 33,  # 50 / 1.5 = 33.33 → 33
          users_1200mm: 25,  # 50 / 2.0 = 25
          users_1500mm: 20,  # 50 / 2.5 = 20
          users_1800mm: 16   # 50 / 3.0 = 16.67 → 16
        })
      end

      it "accounts for negative adjustments" do
        result = SafetyStandard.calculate_user_capacity(10.0, 5.0, 5.0) # 45m² usable

        expect(result).to eq({
          users_1000mm: 30,  # 45 / 1.5 = 30
          users_1200mm: 22,  # 45 / 2.0 = 22.5 → 22
          users_1500mm: 18,  # 45 / 2.5 = 18
          users_1800mm: 15   # 45 / 3.0 = 15
        })
      end

      it "handles nil negative adjustment" do
        result = SafetyStandard.calculate_user_capacity(6.0, 4.0, nil) # 24m² area

        expect(result).to eq({
          users_1000mm: 16,  # 24 / 1.5 = 16
          users_1200mm: 12,  # 24 / 2.0 = 12
          users_1500mm: 9,   # 24 / 2.5 = 9.6 → 9
          users_1800mm: 8    # 24 / 3.0 = 8
        })
      end
    end
  end

  describe "validation methods" do
    describe ".valid_stitch_length?" do
      it "returns true for valid stitch lengths (3-8mm)" do
        expect(SafetyStandard.valid_stitch_length?(3)).to be true
        expect(SafetyStandard.valid_stitch_length?(5)).to be true
        expect(SafetyStandard.valid_stitch_length?(8)).to be true
      end

      it "returns false for invalid stitch lengths" do
        expect(SafetyStandard.valid_stitch_length?(2)).to be false
        expect(SafetyStandard.valid_stitch_length?(9)).to be false
        expect(SafetyStandard.valid_stitch_length?(nil)).to be false
      end
    end

    describe ".valid_evacuation_time?" do
      it "returns true for valid evacuation times (≤30 seconds)" do
        expect(SafetyStandard.valid_evacuation_time?(20)).to be true
        expect(SafetyStandard.valid_evacuation_time?(30)).to be true
        expect(SafetyStandard.valid_evacuation_time?(15)).to be true
      end

      it "returns false for invalid evacuation times" do
        expect(SafetyStandard.valid_evacuation_time?(35)).to be false
        expect(SafetyStandard.valid_evacuation_time?(nil)).to be false
      end
    end

    describe ".valid_pressure?" do
      it "returns true for valid pressures (≥1.0 KPA)" do
        expect(SafetyStandard.valid_pressure?(1.0)).to be true
        expect(SafetyStandard.valid_pressure?(1.5)).to be true
        expect(SafetyStandard.valid_pressure?(2.0)).to be true
      end

      it "returns false for invalid pressures" do
        expect(SafetyStandard.valid_pressure?(0.8)).to be false
        expect(SafetyStandard.valid_pressure?(nil)).to be false
      end
    end

    describe ".valid_fall_height?" do
      it "returns true for valid fall heights (≤0.6m)" do
        expect(SafetyStandard.valid_fall_height?(0.5)).to be true
        expect(SafetyStandard.valid_fall_height?(0.6)).to be true
        expect(SafetyStandard.valid_fall_height?(0.3)).to be true
      end

      it "returns false for invalid fall heights" do
        expect(SafetyStandard.valid_fall_height?(0.7)).to be false
        expect(SafetyStandard.valid_fall_height?(1.0)).to be false
        expect(SafetyStandard.valid_fall_height?(nil)).to be false
      end
    end

    describe ".valid_rope_diameter?" do
      it "returns true for valid rope diameters (18-45mm)" do
        expect(SafetyStandard.valid_rope_diameter?(18)).to be true
        expect(SafetyStandard.valid_rope_diameter?(30)).to be true
        expect(SafetyStandard.valid_rope_diameter?(45)).to be true
      end

      it "returns false for invalid rope diameters" do
        expect(SafetyStandard.valid_rope_diameter?(15)).to be false
        expect(SafetyStandard.valid_rope_diameter?(50)).to be false
        expect(SafetyStandard.valid_rope_diameter?(nil)).to be false
      end
    end

    describe ".requires_permanent_roof?" do
      it "returns true for heights requiring permanent roof (>6.0m)" do
        expect(SafetyStandard.requires_permanent_roof?(6.5)).to be true
        expect(SafetyStandard.requires_permanent_roof?(7.0)).to be true
      end

      it "returns false for heights not requiring permanent roof (≤6.0m)" do
        expect(SafetyStandard.requires_permanent_roof?(5.0)).to be false
        expect(SafetyStandard.requires_permanent_roof?(6.0)).to be false
        expect(SafetyStandard.requires_permanent_roof?(nil)).to be false
      end
    end

    describe ".requires_multiple_exits?" do
      it "returns true for user counts requiring multiple exits (>15)" do
        expect(SafetyStandard.requires_multiple_exits?(16)).to be true
        expect(SafetyStandard.requires_multiple_exits?(20)).to be true
      end

      it "returns false for user counts not requiring multiple exits (≤15)" do
        expect(SafetyStandard.requires_multiple_exits?(15)).to be false
        expect(SafetyStandard.requires_multiple_exits?(10)).to be false
        expect(SafetyStandard.requires_multiple_exits?(nil)).to be false
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

    describe ".anchor_formulas" do
      it "returns anchor calculation information" do
        result = SafetyStandard.anchor_formulas

        expect(result).to have_key(:calculation)
        expect(result).to have_key(:description)
        expect(result).to have_key(:example)
        expect(result).to have_key(:requirements)
        expect(result[:calculation]).to eq("((Area² × 114) ÷ 1600) × 1.5")
      end
    end

    describe ".material_requirements" do
      it "returns material requirement information" do
        result = SafetyStandard.material_requirements

        expect(result).to have_key(:fabric)
        expect(result).to have_key(:thread)
        expect(result).to have_key(:rope)
        expect(result).to have_key(:netting)
        expect(result[:fabric]).to include(:tensile_strength, :tear_strength)
      end
    end

    describe ".electrical_requirements" do
      it "returns electrical requirement information" do
        result = SafetyStandard.electrical_requirements

        expect(result).to have_key(:pat_testing)
        expect(result).to have_key(:blower_requirements)
        expect(result).to have_key(:grounding_test)
        expect(result[:blower_requirements]).to include(:minimum_pressure)
      end
    end

    describe ".inspection_intervals" do
      it "returns inspection interval information" do
        result = SafetyStandard.inspection_intervals

        expect(result).to have_key(:standard_interval)
        expect(result).to have_key(:high_use_interval)
        expect(result).to have_key(:commercial_interval)
        expect(result).to have_key(:post_repair_interval)
        expect(result[:standard_interval]).to eq(12.months)
      end
    end
  end
end
