module SafetyStandards
  module MaterialValidator
    extend self

    # Material safety standards (EN 14960:2019 & EN 71-3)
    MATERIAL_STANDARDS = {
      fabric: {
        min_tensile_strength: 1850,    # Newtons minimum
        min_tear_strength: 350,        # Newtons minimum
        fire_standard: "EN 71-3"       # Fire retardancy standard
      },
      thread: {
        min_tensile_strength: 88      # Newtons minimum
      },
      rope: {
        min_diameter: 18,              # mm minimum
        max_diameter: 45,              # mm maximum
        max_swing_percentage: 20       # % maximum swing
      },
      netting: {
        max_vertical_mesh: 30,         # mm maximum for >1m height
        max_roof_mesh: 8               # mm maximum
      }
    }.freeze

    # Test examples for material validation
    MATERIAL_TEST_EXAMPLES = {
      rope_diameter: {
        valid: {
          minimum: 18,     # mm - minimum allowed
          medium: 30,      # mm - middle of range
          maximum: 45      # mm - maximum allowed
        },
        invalid: {
          too_thin: 15,    # mm - below minimum
          too_thick: 50,   # mm - above maximum
          nil_value: nil   # nil not allowed
        }
      }
    }.freeze

    def valid_rope_diameter?(diameter_mm)
      # EN 14960:2019 - Rope diameter range prevents finger entrapment while
      # ensuring adequate grip and structural strength
      min_diameter = MATERIAL_STANDARDS[:rope][:min_diameter]
      max_diameter = MATERIAL_STANDARDS[:rope][:max_diameter]
      diameter_mm.present? && diameter_mm.between?(min_diameter, max_diameter)
    end

    def fabric_tensile_requirement(
      fabric_standards = MATERIAL_STANDARDS[:fabric]
    )
      "#{fabric_standards[:min_tensile_strength]} Newtons minimum"
    end

    def fabric_tear_requirement(fabric_standards = MATERIAL_STANDARDS[:fabric])
      "#{fabric_standards[:min_tear_strength]} Newtons minimum"
    end
  end
end
