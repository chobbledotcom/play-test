module SafetyStandards
  module AnchorCalculator
    extend self

    # Anchor calculation constants (EN 14960:2019)
    ANCHOR_CALCULATION_CONSTANTS = {
      area_coefficient: 114.0,     # Area coefficient in anchor formula
      base_divisor: 1600.0,        # Base divisor for anchor calculation
      safety_factor: 1.5           # Safety factor multiplier
    }.freeze

    def calculate_required_anchors(area_m2)
      # EN 14960:2019 - Anchor calculation for adequate ground restraint
      # Formula from original Windows app, rounded up
      return 0 if area_m2.nil? || area_m2 <= 0

      # Formula using constants from ANCHOR_CALCULATION_CONSTANTS
      area_coeff = ANCHOR_CALCULATION_CONSTANTS[:area_coefficient]
      base_div = ANCHOR_CALCULATION_CONSTANTS[:base_divisor]
      safety_mult = ANCHOR_CALCULATION_CONSTANTS[:safety_factor]

      ((area_m2.to_f * area_coeff * safety_mult) / base_div).ceil
    end

    def calculate(length:, width:, height:)
      front_area = (width * height).round(1)
      sides_area = (length * height).round(1)

      required_front = calculate_required_anchors(front_area)
      required_sides = calculate_required_anchors(sides_area)

      total_required = (required_front + required_sides) * 2

      area_coeff = ANCHOR_CALCULATION_CONSTANTS[:area_coefficient]
      base_div = ANCHOR_CALCULATION_CONSTANTS[:base_divisor]
      safety_mult = ANCHOR_CALCULATION_CONSTANTS[:safety_factor]

      formula_front = "((#{front_area} × #{area_coeff} * #{safety_mult}) ÷ "
      formula_front += base_div.to_s
      formula_sides = "((#{sides_area} × #{area_coeff} * #{safety_mult}) ÷ "
      formula_sides += base_div.to_s

      breakdown = [
        [
          "Front/back area",
          "#{width}m (W) × #{height}m (H) = #{front_area}m²"
        ],
        [
          "Sides area",
          "#{length}m (L) × #{height}m (H) = #{sides_area}m²"
        ],
        [
          "Front & back anchor counts",
          "#{formula_front} = #{required_front}"
        ],
        [
          "Left & right anchor counts",
          "#{formula_sides} = #{required_sides}"
        ],
        [
          "Total anchors",
          "(#{required_front} + #{required_sides}) × 2 = #{total_required}"
        ]
      ]

      {
        required_anchors: total_required,
        formula_breakdown: breakdown
      }
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
