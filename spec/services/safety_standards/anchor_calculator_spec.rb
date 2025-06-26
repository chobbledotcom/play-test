require "rails_helper"

RSpec.describe SafetyStandards::AnchorCalculator do
  describe ".calculate" do
    # EN 14960-1:2019 Line 441-442: "Each inflatable shall have at least six anchorage points"
    context "minimum anchor requirements" do
      it "returns at least 6 anchors for small inflatables" do
        result = described_class.calculate(length: 1, width: 1, height: 1)
        expect(result[:required_anchors]).to eq(6)

        # Should include minimum requirement note
        expect(result[:formula_breakdown]).to include(
          ["EN 14960 minimum", "Minimum 6 anchors required, using 6"]
        )
      end

      it "returns at least 6 anchors for tiny inflatables" do
        result = described_class.calculate(length: 0.5, width: 0.5, height: 0.5)
        expect(result[:required_anchors]).to eq(6)

        # Should include minimum requirement note
        expect(result[:formula_breakdown]).to include(
          ["EN 14960 minimum", "Minimum 6 anchors required, using 6"]
        )
      end

      it "does not apply minimum when calculated anchors exceed 6" do
        result = described_class.calculate(length: 5, width: 4, height: 3)
        expect(result[:required_anchors]).to eq(8)

        # Should NOT include minimum requirement note
        expect(result[:formula_breakdown]).not_to include(
          ["EN 14960 minimum", "Minimum 6 anchors required, using 6"]
        )
      end
    end

    # EN 14960-1:2019 Lines 1175-1210 (Annex A): Anchor calculation formula
    # Formula: F = 0.5 × Cw × ρ × V² × A
    # Where: Cw = 1.5, ρ = 1.24 kg/m³, V = 11.1 m/s
    # Number of anchors = Force / 1600N (rounded up)
    context "anchor calculation formula" do
      it "calculates anchors based on exposed surface area" do
        # Test a 5m × 4m × 3m inflatable
        result = described_class.calculate(length: 5, width: 4, height: 3)

        # Front/back area: 4 × 3 = 12m²
        # Sides area: 5 × 3 = 15m²
        # Front anchors: ceil((12 × 114 × 1.5) / 1600) = ceil(1.28) = 2
        # Side anchors: ceil((15 × 114 × 1.5) / 1600) = ceil(1.60) = 2
        # Total: (2 + 2) × 2 = 8
        expect(result[:required_anchors]).to eq(8)
      end

      it "calculates anchors for larger inflatables" do
        # Test a 10m × 8m × 4m inflatable
        result = described_class.calculate(length: 10, width: 8, height: 4)

        # Front/back area: 8 × 4 = 32m²
        # Sides area: 10 × 4 = 40m²
        # Front anchors: ceil((32 × 114 × 1.5) / 1600) = ceil(3.42) = 4
        # Side anchors: ceil((40 × 114 × 1.5) / 1600) = ceil(4.28) = 5
        # Total: (4 + 5) × 2 = 18
        expect(result[:required_anchors]).to eq(18)
      end
    end

    # EN 14960-1:2019 Line 443: "The number of anchorage points shall be calculated in accordance with Annex A"
    context "formula breakdown" do
      it "provides detailed calculation breakdown" do
        result = described_class.calculate(length: 5, width: 4, height: 3)

        expect(result[:formula_breakdown]).to include(
          ["Front/back area", "4m (W) × 3m (H) = 12m²"],
          ["Sides area", "5m (L) × 3m (H) = 15m²"]
        )
      end
    end

    # EN 14960-1:2019 Lines 1194-1199: Default values for calculation
    # Cw = 1.5 (wind coefficient)
    # ρ = 1.24 kg/m³ (air density)
    # V = 11.1 m/s (wind speed - Force 6 Beaufort)
    context "uses correct EN 14960 constants" do
      it "uses area coefficient of 114 (derived from 0.5 × 1.5 × 1.24 × 11.1²)" do
        # Verify the pre-calculated constant
        wind_force_coefficient = 0.5 * 1.5 * 1.24 * (11.1**2)
        expect(wind_force_coefficient).to be_within(1).of(114)

        # Verify it's used in the calculator
        expect(described_class::ANCHOR_CALCULATION_CONSTANTS[:area_coefficient]).to eq(114.0)
      end

      it "uses 1600N as the base divisor per anchor point" do
        # EN 14960-1:2019 Line 450: "withstand a force of 1 600 N"
        expect(described_class::ANCHOR_CALCULATION_CONSTANTS[:base_divisor]).to eq(1600.0)
      end

      it "uses safety factor of 1.5" do
        expect(described_class::ANCHOR_CALCULATION_CONSTANTS[:safety_factor]).to eq(1.5)
      end
    end

    # EN 14960-1:2019 Line 443-444: "They shall be distributed around the perimeter"
    context "anchor distribution" do
      it "calculates anchors for all four sides" do
        result = described_class.calculate(length: 5, width: 4, height: 3)

        breakdown = result[:formula_breakdown]
        expect(breakdown).to include(
          ["Front & back anchor counts", "((12 × 114.0 * 1.5) ÷ 1600.0 = 2"],
          ["Left & right anchor counts", "((15 × 114.0 * 1.5) ÷ 1600.0 = 2"]
        )
      end

      it "multiplies by 2 for both front/back and left/right sides" do
        result = described_class.calculate(length: 5, width: 4, height: 3)

        breakdown = result[:formula_breakdown]
        expect(breakdown).to include(
          ["Total anchors", "(2 + 2) × 2 = 8"]
        )
      end
    end

    # EN 14960-1:2019 Line 1206: "Corner anchors count 50% on each side"
    # Note: Current implementation doesn't specifically handle corner anchors
    # but the total calculation accounts for all sides
  end

  describe ".calculate_required_anchors" do
    # EN 14960-1:2019 Lines 1201-1203: Number of anchors = Force / 1600N (rounded up)
    context "individual side calculations" do
      it "returns 0 for nil area" do
        expect(described_class.calculate_required_anchors(nil)).to eq(0)
      end

      it "returns 0 for zero area" do
        expect(described_class.calculate_required_anchors(0)).to eq(0)
      end

      it "returns 0 for negative area" do
        expect(described_class.calculate_required_anchors(-5)).to eq(0)
      end

      it "rounds up fractional anchor counts" do
        # Area that would give exactly 1.01 anchors
        area = (1.01 * 1600) / (114 * 1.5)
        result = described_class.calculate_required_anchors(area)
        expect(result).to eq(2)
      end

      it "calculates correctly for exact anchor counts" do
        # Area that would give exactly 2.0 anchors
        area = (2.0 * 1600) / (114 * 1.5)
        result = described_class.calculate_required_anchors(area)
        expect(result).to eq(2)
      end
    end
  end

  describe ".anchor_formula_text" do
    it "returns the formula text with correct constants" do
      expect(described_class.anchor_formula_text).to eq("((Area × 114.0 × 1.5) ÷ 1600.0)")
    end
  end

  describe ".anchor_calculation_description" do
    it "returns the i18n description" do
      expect(described_class.anchor_calculation_description).to eq(
        I18n.t("safety_standards.calculators.anchor.description")
      )
    end
  end
end
