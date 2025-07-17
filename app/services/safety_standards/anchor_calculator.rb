module SafetyStandards
  module AnchorCalculator
    extend self

    # Anchor calculation constants from EN 14960-1:2019
    # Line 450: Each anchor must withstand 1600N force
    # Lines 441-442: Minimum 6 anchorage points required
    # Lines 1194-1199: Cw=1.5, ρ=1.24 kg/m³, V=11.1 m/s
    # Pre-calculated: 0.5 × 1.5 × 1.24 × 11.1² ≈ 114
    ANCHOR_CALCULATION_CONSTANTS = {
      area_coefficient: 114.0,     # Pre-calculated wind force coefficient
      base_divisor: 1600.0,        # Force per anchor in Newtons (Line 450)
      safety_factor: 1.5,          # Safety factor multiplier
      minimum_anchors: 6           # Minimum required anchors (Lines 441-442)
    }.freeze

    # Test examples for anchor calculations
    # Formula: (Area * 114 * 1.5) / 1600, rounded up
    # EN 14960-1:2019 Lines 441-442: Minimum 6 anchors required
    ANCHOR_TEST_EXAMPLES = {
      # Basic area calculations
      basic: {
        small_area: {
          input: 5,
          expected: 1 # (5 * 114 * 1.5) / 1600 = 0.534 → 1
        },
        medium_area: {
          input: 10,
          expected: 2 # (10 * 114 * 1.5) / 1600 = 1.069 → 2
        },
        large_area: {
          input: 25,
          expected: 3 # (25 * 114 * 1.5) / 1600 = 2.672 → 3
        }
      },

      # Invalid inputs
      invalid: {
        nil_area: {
          input: nil,
          expected: 0
        },
        zero_area: {
          input: 0,
          expected: 0
        },
        negative_area: {
          input: -5.0,
          expected: 0
        }
      },

      # Full unit calculations
      units: {
        small_unit: {
          dimensions: { length: 1, width: 1, height: 1 },
          expected_anchors: 6 # Front/back: 1m² → 1, Sides: 1m² → 1, Total: (1+1)*2 = 4, Min: 6
        },
        standard_unit: {
          dimensions: { length: 5, width: 4, height: 3 },
          expected_anchors: 8 # Front/back: 12m² → 2, Sides: 15m² → 2, Total: (2+2)*2 = 8
        },
        large_unit: {
          dimensions: { length: 10, width: 8, height: 4 },
          expected_anchors: 18 # Front/back: 32m² → 4, Sides: 40m² → 5, Total: (4+5)*2 = 18
        }
      }
    }.freeze

    def calculate_required_anchors(area_m2)
      # EN 14960-1:2019 Annex A (Lines 1175-1210) - Anchor calculation formula
      # Force = 0.5 × Cw × ρ × V² × A
      # Where: Cw = 1.5, ρ = 1.24 kg/m³, V = 11.1 m/s (Lines 1194-1199)
      # Number of anchors = Force / 1600N (Line 450 - each anchor withstands 1600N)
      return 0 if area_m2.nil? || area_m2 <= 0

      # Pre-calculated: 0.5 × 1.5 × 1.24 × 11.1² ≈ 114
      area_coeff = ANCHOR_CALCULATION_CONSTANTS[:area_coefficient]
      base_div = ANCHOR_CALCULATION_CONSTANTS[:base_divisor]
      safety_mult = ANCHOR_CALCULATION_CONSTANTS[:safety_factor]

      ((area_m2.to_f * area_coeff * safety_mult) / base_div).ceil
    end

    def calculate(length:, width:, height:)
      # EN 14960-1:2019 Lines 1175-1210 (Annex A) - Calculate exposed surface areas
      front_area = (width * height).round(1)
      sides_area = (length * height).round(1)

      required_front = calculate_required_anchors(front_area)
      required_sides = calculate_required_anchors(sides_area)

      # EN 14960-1:2019 Line 1204 - Calculate for each side
      total_required = (required_front + required_sides) * 2

      # EN 14960-1:2019 Lines 441-442 - "Each inflatable shall have at least six anchorage points"
      minimum = ANCHOR_CALCULATION_CONSTANTS[:minimum_anchors]
      total_required = [ total_required, minimum ].max

      area_coeff = ANCHOR_CALCULATION_CONSTANTS[:area_coefficient]
      base_div = ANCHOR_CALCULATION_CONSTANTS[:base_divisor]
      safety_mult = ANCHOR_CALCULATION_CONSTANTS[:safety_factor]

      formula_front = "((#{front_area} × #{area_coeff} * #{safety_mult}) ÷ "
      formula_front += base_div.to_s
      formula_sides = "((#{sides_area} × #{area_coeff} * #{safety_mult}) ÷ "
      formula_sides += base_div.to_s

      calculated_total = (required_front + required_sides) * 2

      breakdown = [
        [
          I18n.t("safety_standards.calculators.anchor.front_back_area_label"),
          "#{width}m (W) × #{height}m (H) = #{front_area}m²"
        ],
        [
          I18n.t("safety_standards.calculators.anchor.sides_area_label"),
          "#{length}m (L) × #{height}m (H) = #{sides_area}m²"
        ],
        [
          I18n.t("safety_standards.calculators.anchor.front_back_anchors_label"),
          "#{formula_front} = #{required_front}"
        ],
        [
          I18n.t("safety_standards.calculators.anchor.left_right_anchors_label"),
          "#{formula_sides} = #{required_sides}"
        ],
        [
          I18n.t("safety_standards.calculators.anchor.total_anchors_label"),
          "(#{required_front} + #{required_sides}) × 2 = #{calculated_total}"
        ]
      ]

      # Add minimum requirement note if applicable
      if calculated_total < minimum
        breakdown << [
          I18n.t("safety_standards.calculators.anchor.en_minimum_label"),
          I18n.t("safety_standards.calculators.anchor.minimum_required", minimum: minimum)
        ]
      end

      CalculatorResponse.new(
        value: total_required,
        value_suffix: "",
        breakdown: breakdown
      )
    end

    def anchor_formula_text
      area_coeff = ANCHOR_CALCULATION_CONSTANTS[:area_coefficient]
      base_div = ANCHOR_CALCULATION_CONSTANTS[:base_divisor]
      safety_fact = ANCHOR_CALCULATION_CONSTANTS[:safety_factor]
      "((Area × #{area_coeff} × #{safety_fact}) ÷ #{base_div})"
    end

    def anchor_calculation_description
      I18n.t("safety_standards.calculators.anchor.description")
    end
  end
end
