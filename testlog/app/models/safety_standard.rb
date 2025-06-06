# RPII Utility - Business rules and calculations model
class SafetyStandard
  include ActiveModel::Model

  # Height category constants based on EN 14960:2019
  HEIGHT_CATEGORIES = {
    1000 => {label: "1.0m (Young children)", max_users: :calculate_by_area},
    1200 => {label: "1.2m (Children)", max_users: :calculate_by_area},
    1500 => {label: "1.5m (Adolescents)", max_users: :calculate_by_area},
    1800 => {label: "1.8m (Adults)", max_users: :calculate_by_area}
  }.freeze

  # Slide safety thresholds
  SLIDE_HEIGHT_THRESHOLDS = {
    no_walls_required: 0.6,      # Under 600mm
    basic_walls: 3.0,            # 600mm - 3000mm
    enhanced_walls: 6.0,         # 3000mm - 6000mm
    max_safe_height: 8.0         # Maximum recommended height
  }.freeze

  class << self
    def height_categories
      HEIGHT_CATEGORIES
    end

    def meets_height_requirements?(user_height, containing_wall_height)
      # EN 14960:2019 - Containing wall heights must scale with user height: no walls <0.6m, equal height 0.6-3m, 1.25x height 3-6m, plus permanent roof >6m
      return false if user_height.nil? || containing_wall_height.nil?

      case user_height
      when 0..SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]
        true # No containing walls required
      when SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]..SLIDE_HEIGHT_THRESHOLDS[:basic_walls]
        containing_wall_height >= user_height
      when SLIDE_HEIGHT_THRESHOLDS[:basic_walls]..SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]
        containing_wall_height >= (user_height * 1.25)
      when SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]..SLIDE_HEIGHT_THRESHOLDS[:max_safe_height]
        containing_wall_height >= (user_height * 1.25) # Plus permanent roof required
      else
        false # Exceeds safe height limits
      end
    end

    def meets_runout_requirements?(runout_length, platform_height)
      # EN 14960:2019 - Slide runout length must be minimum 50% of platform height or 300mm, whichever is greater, to ensure safe deceleration
      return false if runout_length.nil? || platform_height.nil?

      required_runout = calculate_required_runout(platform_height)
      runout_length >= required_runout
    end

    def calculate_required_runout(platform_height)
      # EN 14960:2019 - Minimum runout distance calculation: 50% of platform height with absolute minimum of 300mm for safe landing
      return 0 if platform_height.nil? || platform_height <= 0

      # 50% of platform height, minimum 300mm (0.3m)
      [platform_height * 0.5, 0.3].max
    end

    def calculate_required_anchors(area_m2)
      # EN 14960:2019 - Anchor point calculation: ((Area² × 114) ÷ 1600) × 1.5 safety factor, ensuring adequate ground restraint for wind loads
      return 0 if area_m2.nil? || area_m2 <= 0

      # Formula from original Windows app: ((Area² * 114)/1600) * 1.5, rounded up
      # Use to_f to ensure proper floating point calculation
      ((area_m2.to_f**2 * 114.0) / 1600.0 * 1.5).ceil
    end

    def calculate_user_capacity(length, width, negative_adjustment = 0)
      # EN 14960:2019 - User capacity based on age-appropriate space allocation: 1.5m²/child (1m), 2m²/child (1.2m), 2.5m²/adolescent (1.5m), 3m²/adult (1.8m)
      return {} if length.nil? || width.nil?

      usable_area = (length * width) - (negative_adjustment || 0)
      return {} if usable_area <= 0

      # Standard capacity calculation (varies by age group)
      # Based on space requirements per user by height category
      {
        users_1000mm: (usable_area / 1.5).floor,  # 1.5m² per young child
        users_1200mm: (usable_area / 2.0).floor,  # 2.0m² per child
        users_1500mm: (usable_area / 2.5).floor,  # 2.5m² per adolescent
        users_1800mm: (usable_area / 3.0).floor   # 3.0m² per adult
      }
    end

    def slide_calculations
      # EN 14960:2019 - Comprehensive slide safety requirements including containing wall heights, runout specifications, and gradient limitations
      {
        containing_wall_heights: {
          under_600mm: "No containing walls required",
          between_600_3000mm: "Containing walls required of user height",
          between_3000_6000mm: "Containing walls required 1.25 times user height",
          over_6000mm: "Both containing walls AND permanent roof required"
        },
        runout_requirements: {
          minimum_length: "50% of highest platform height",
          absolute_minimum: "300mm in any case",
          maximum_inclination: "Not more than 10°",
          stop_wall_addition: "If fitted, adds 50cm to required run-out length",
          wall_height_requirement: "50% of user height on run-out sides"
        },
        safety_factors: {
          first_metre_gradient: "Special requirements for first metre of slope",
          surface_requirements: "Non-slip surface material required",
          edge_protection: "Rounded edges and smooth transitions"
        }
      }
    end

    def anchor_formulas
      # EN 14960:2019 - Anchoring system calculations and requirements for secure ground attachment with specified pull strength minimums
      {
        calculation: "((Area² × 114) ÷ 1600) × 1.5",
        description: "Number of anchor points per side, rounded up",
        example: "For 25m² area: ((25² × 114) ÷ 1600) × 1.5 = 6.6 → 7 anchors",
        requirements: {
          low_anchors: "Ground-level anchoring points",
          high_anchors: "Elevated anchoring points for tall structures",
          angle_requirements: "30° to 45° angle to ground",
          strength_requirements: "1600 Newton pull strength minimum"
        }
      }
    end

    def material_requirements
      # EN 14960:2019 & EN 71-3 - Material specifications for fabric tensile strength, thread durability, rope dimensions, and fire retardancy standards
      {
        fabric: {
          tensile_strength: "1850 Newtons minimum",
          tear_strength: "350 Newtons minimum",
          fire_retardancy: "Must meet EN 71-3 requirements"
        },
        thread: {
          material: "Non-rotting yarn required",
          tensile_strength: "88 Newtons minimum",
          stitch_type: "Lock stitching required"
        },
        rope: {
          diameter_range: "18mm - 45mm",
          material: "Non-monofilament",
          attachment: "Fixed at both ends",
          swing_limitation: "No greater than 20% swing to prevent strangulation"
        },
        netting: {
          vertical_mesh_size: "30mm maximum for >1m height",
          roof_mesh_size: "8mm maximum",
          strength: "Support heaviest intended user"
        }
      }
    end

    def electrical_requirements
      # PAT testing standards and EN 14960:2019 - Electrical safety requirements for blowers including minimum pressure, grounding tests, and safety distances
      {
        pat_testing: "Portable Appliance Test required",
        blower_requirements: {
          minimum_pressure: "1.0 KPA operational pressure",
          finger_probe: "8mm probe must not contact moving/hot parts",
          return_flap: "Required to reduce deflation time",
          distance: "1.2m minimum from equipment edge"
        },
        grounding_test: {
          "1.0m_height": "25kg test weight",
          "1.2m_height": "35kg test weight",
          "1.5m_height": "65kg test weight",
          "1.8m_height": "85kg test weight"
        }
      }
    end

    def inspection_intervals
      # RPII guidelines - Mandatory inspection frequencies based on usage intensity to ensure ongoing safety compliance and equipment integrity
      {
        standard_interval: 12.months,
        high_use_interval: 6.months,
        commercial_interval: 3.months,
        post_repair_interval: 1.month
      }
    end

    # Validation methods for business rules
    def valid_stitch_length?(length_mm)
      # EN 14960:2019 - Stitch length must be 3-8mm to ensure adequate seam strength while maintaining fabric integrity
      length_mm.present? && length_mm.between?(3, 8)
    end

    def valid_evacuation_time?(time_seconds)
      # EN 14960:2019 - Maximum 30-second evacuation time ensures rapid deflation for emergency situations and user safety
      time_seconds.present? && time_seconds <= 30
    end

    def valid_pressure?(pressure_kpa)
      # EN 14960:2019 - Minimum 1.0 KPA operational pressure required to maintain structural integrity and prevent collapse
      pressure_kpa.present? && pressure_kpa >= 1.0
    end

    def valid_fall_height?(height_m)
      # EN 14960:2019 - Maximum 0.6m (600mm) fall height to minimize injury risk from accidental falls outside the structure
      height_m.present? && height_m <= 0.6
    end

    def valid_rope_diameter?(diameter_mm)
      # EN 14960:2019 - Rope diameter 18-45mm prevents finger entrapment while ensuring adequate grip and structural strength
      diameter_mm.present? && diameter_mm.between?(18, 45)
    end

    def requires_permanent_roof?(user_height)
      # EN 14960:2019 - Permanent roof mandatory for user heights >6m to prevent users from being thrown clear of containing walls
      user_height.present? && user_height > SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]
    end

    def requires_multiple_exits?(user_count)
      # EN 14960:2019 - Multiple exits required for >15 users to ensure adequate emergency evacuation capacity and prevent overcrowding
      user_count.present? && user_count > 15
    end
  end
end
