module SafetyStandards
  module SlideCalculator
    extend self

    # Slide safety thresholds
    SLIDE_HEIGHT_THRESHOLDS = {
      no_walls_required: 0.6,      # Under 600mm
      basic_walls: 3.0,            # 600mm - 3000mm
      enhanced_walls: 6.0,         # 3000mm - 6000mm
      max_safe_height: 8.0         # Maximum recommended height
    }.freeze

    # Slide runout calculation constants (EN 14960:2019)
    RUNOUT_CALCULATION_CONSTANTS = {
      platform_height_ratio: 0.5, # 50% of platform height
      minimum_runout_meters: 0.3   # Absolute minimum 300mm (0.3m)
    }.freeze

    # Wall height calculation constants (EN 14960:2019)
    WALL_HEIGHT_CONSTANTS = {
      enhanced_height_multiplier: 1.25  # 1.25× multiplier for enhanced walls
    }.freeze

    def calculate_required_runout(platform_height)
      # EN 14960:2019 - Minimum runout distance calculation using
      # RUNOUT_CALCULATION_CONSTANTS for safe landing
      return 0 if platform_height.nil? || platform_height <= 0

      # Calculate using constants from RUNOUT_CALCULATION_CONSTANTS
      height_ratio = RUNOUT_CALCULATION_CONSTANTS[:platform_height_ratio]
      minimum_runout = RUNOUT_CALCULATION_CONSTANTS[:minimum_runout_meters]

      [platform_height * height_ratio, minimum_runout].max
    end

    def meets_height_requirements?(platform_height, user_height, containing_wall_height)
      # EN 14960:2019 - Containing wall heights must scale with user height
      # based on platform height thresholds
      return false if platform_height.nil? || user_height.nil? || containing_wall_height.nil?

      enhanced_multiplier = WALL_HEIGHT_CONSTANTS[:enhanced_height_multiplier]

      case platform_height
      when 0..SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]
        true # No containing walls required
      when (SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]..
            SLIDE_HEIGHT_THRESHOLDS[:basic_walls])
        containing_wall_height >= user_height
      when (SLIDE_HEIGHT_THRESHOLDS[:basic_walls]..
            SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls])
        containing_wall_height >= (user_height * enhanced_multiplier)
      when (SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]..
            SLIDE_HEIGHT_THRESHOLDS[:max_safe_height])
        # Plus permanent roof required
        containing_wall_height >= (user_height * enhanced_multiplier)
      else
        false # Exceeds safe height limits
      end
    end

    def meets_runout_requirements?(runout_length, platform_height)
      # EN 14960:2019 - Slide runout length must be minimum 50% of platform
      # height or 300mm, whichever is greater, to ensure safe deceleration
      return false if runout_length.nil? || platform_height.nil?

      required_runout = calculate_required_runout(platform_height)
      runout_length >= required_runout
    end

    def slide_runout_formula_text
      ratio_constant = RUNOUT_CALCULATION_CONSTANTS[:platform_height_ratio]
      height_ratio = (ratio_constant * 100).to_i
      min_constant = RUNOUT_CALCULATION_CONSTANTS[:minimum_runout_meters]
      min_runout = (min_constant * 1000).to_i
      "#{height_ratio}% of platform height, minimum #{min_runout}mm"
    end

    def requires_permanent_roof?(platform_height)
      # EN 14960:2019 - Permanent roof mandatory for platform heights above
      # enhanced walls threshold to prevent users from being thrown clear
      threshold = SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]
      platform_height.present? && platform_height > threshold
    end

    def wall_height_requirement
      multiplier = WALL_HEIGHT_CONSTANTS[:enhanced_height_multiplier]
      "Containing walls required #{multiplier} times user height"
    end

    def slide_calculations
      # EN 14960:2019 - Comprehensive slide safety requirements
      {
        containing_wall_heights: {
          under_600mm: "No containing walls required",
          between_600_3000mm: "Containing walls required of user height",
          between_3000_6000mm: wall_height_requirement,
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
  end
end
