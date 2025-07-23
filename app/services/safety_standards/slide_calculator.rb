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
      minimum_runout_meters: 0.3,  # Absolute minimum 300mm (0.3m)
      stop_wall_addition: 0.5      # 50cm addition when stop-wall fitted (Line 936)
    }.freeze

    # Wall height calculation constants (EN 14960:2019)
    WALL_HEIGHT_CONSTANTS = {
      enhanced_height_multiplier: 1.25  # 1.25× multiplier for enhanced walls
    }.freeze

    # Test examples for height requirements validation
    # Format: [platform_height, user_height, containing_wall_height, has_permanent_roof]
    HEIGHT_TEST_EXAMPLES = {
      # Valid scenarios
      valid: {
        # No walls required (under 0.6m)
        no_walls_required: [0.5, 1.5, 0, false],
        no_walls_required_low: [0.3, 1.5, 0, false],

        # Basic walls (0.6m - 3.0m) - wall height >= user height
        basic_walls_exact: [1.5, 1.5, 1.5, false],
        basic_walls_exceeds: [2, 2, 2.5, false],

        # Enhanced walls (3.0m - 6.0m) - wall height >= 1.25x user height OR roof
        enhanced_walls: [4, 4, 5, false], # 4 * 1.25 = 5
        enhanced_walls_exact: [5, 5, 6.25, false], # 5 * 1.25 = 6.25
        enhanced_walls_with_roof: [4, 4, 3, true], # Insufficient walls but has roof
        enhanced_walls_roof_alternative: [5, 5, 5, true], # Has roof, walls don't need to be 1.25x

        # Maximum height (6.0m - 8.0m) - wall height >= 1.25x user height AND roof
        max_height_with_roof: [7, 7, 8.75, true], # 7 * 1.25 = 8.75 AND has roof
        max_height_exact_with_roof: [6.5, 6.5, 8.125, true] # 6.5 * 1.25 = 8.125 AND has roof
      },

      # Invalid scenarios
      invalid: {
        # Nil values
        nil_user_height: [1, nil, 2, false],
        nil_wall_height: [1, 1.5, nil, false],
        nil_roof: [1, 1.5, 2, nil],

        # Insufficient wall heights
        basic_walls_too_low: [2, 2, 1.8, false],
        enhanced_walls_too_low: [4, 4, 4.8, false], # Needs 5m or roof
        max_height_too_low: [7, 7, 8, true], # Needs 8.75m even with roof
        max_height_no_roof: [7, 7, 8.75, false], # Has correct walls but needs roof

        # Exceeds safe limits (over 8.0m)
        exceeds_safe_height: [9, 7, 12, true],
        exceeds_safe_height_high: [10, 7, 15, true]
      }
    }.freeze

    # Test examples for runout requirements validation
    # Format: [runout_length, platform_height]
    RUNOUT_TEST_EXAMPLES = {
      # Valid scenarios
      valid: {
        # Runout is 50% of platform height
        runout_exact: [1, 2],
        runout_half: [0.5, 1],

        # Minimum runout (0.3m)
        runout_minimum: [0.3, 0.1] # Platform needs 0.05m but minimum is 0.3m
      },

      # Invalid scenarios
      invalid: {
        # Nil values
        runout_nil: [nil, 2],
        platform_nil: [1.5, nil],

        # Insufficient runout
        runout_too_short: [0.8, 2], # Needs 1m
        runout_insufficient: [0.2, 1], # Needs 0.5m

        # Below minimum
        runout_below_min: [0.25, 0.1] # Below 0.3m minimum
      }
    }.freeze

    # Simple calculation method that returns just the numeric value
    def calculate_runout_value(platform_height, has_stop_wall: false)
      return 0 if platform_height.nil? || platform_height <= 0

      height_ratio = RUNOUT_CALCULATION_CONSTANTS[:platform_height_ratio]
      minimum_runout = RUNOUT_CALCULATION_CONSTANTS[:minimum_runout_meters]
      stop_wall_add = RUNOUT_CALCULATION_CONSTANTS[:stop_wall_addition]

      calculated_runout = platform_height * height_ratio
      base_runout = [calculated_runout, minimum_runout].max

      has_stop_wall ? base_runout + stop_wall_add : base_runout
    end

    def calculate_required_runout(platform_height, has_stop_wall: false)
      # EN 14960-1:2019 Section 4.2.11 (Lines 930-939) - Runout requirements
      # Line 934-935: The runout distance must be at least half the height of the slide's
      # highest platform (measured from ground level), with an absolute minimum of 300mm
      # Line 936: If a stop-wall is installed at the runout's end, an additional
      # 50cm must be added to the total runout length
      return CalculatorResponse.new(value: 0, value_suffix: "m", breakdown: []) if platform_height.nil? || platform_height <= 0

      # Get constants
      height_ratio = RUNOUT_CALCULATION_CONSTANTS[:platform_height_ratio]
      minimum_runout = RUNOUT_CALCULATION_CONSTANTS[:minimum_runout_meters]
      stop_wall_add = RUNOUT_CALCULATION_CONSTANTS[:stop_wall_addition]

      # Calculate values using the shared method
      calculated_runout = platform_height * height_ratio
      base_runout = calculate_runout_value(platform_height, has_stop_wall: false)
      final_runout = calculate_runout_value(platform_height, has_stop_wall: has_stop_wall)

      # Build breakdown
      breakdown = [
        [
          I18n.t("safety_standards.calculators.runout.calculation_label"),
          "#{platform_height}m × 0.5 = #{calculated_runout}m"
        ],
        [
          I18n.t("safety_standards.calculators.runout.minimum_label"),
          "#{minimum_runout}m (300mm)"
        ],
        [
          I18n.t("safety_standards.calculators.runout.base_runout_label"),
          "#{I18n.t("safety_standards.calculators.runout.maximum_of")} #{calculated_runout}m #{I18n.t("safety_standards.calculators.runout.and")} #{minimum_runout}m = #{base_runout}m"
        ]
      ]

      # Add stop-wall if applicable
      if has_stop_wall
        breakdown << [
          I18n.t("safety_standards.calculators.runout.stop_wall_addition_label"),
          "#{base_runout}m + #{stop_wall_add}m = #{final_runout}m"
        ]
      end

      CalculatorResponse.new(
        value: final_runout,
        value_suffix: "m",
        breakdown: breakdown
      )
    end

    def meets_height_requirements?(platform_height, user_height, containing_wall_height, has_permanent_roof)
      # EN 14960-1:2019 Section 4.2.9 (Lines 854-887) - Containment requirements
      # Lines 859-860: Containing walls become mandatory for platforms exceeding 0.6m in height
      # Lines 861-862: Platforms between 0.6m and 3.0m need walls at least as tall as the maximum user height
      # Lines 863-864: Platforms between 3.0m and 6.0m require walls at least 1.25 times the maximum user height OR a permanent roof
      # Lines 865-866: Platforms over 6.0m must have both containing walls and a permanent roof structure
      return false if platform_height.nil? || user_height.nil? || containing_wall_height.nil? || has_permanent_roof.nil?

      enhanced_multiplier = WALL_HEIGHT_CONSTANTS[:enhanced_height_multiplier]

      case platform_height
      when 0..SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]
        true # No containing walls required
      when (SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]..
            SLIDE_HEIGHT_THRESHOLDS[:basic_walls])
        containing_wall_height >= user_height
      when (SLIDE_HEIGHT_THRESHOLDS[:basic_walls]..
            SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls])
        # EITHER walls at 1.25x user height OR permanent roof
        has_permanent_roof || containing_wall_height >= (user_height * enhanced_multiplier)
      when (SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]..
            SLIDE_HEIGHT_THRESHOLDS[:max_safe_height])
        # BOTH containing walls AND permanent roof required
        has_permanent_roof && containing_wall_height >= (user_height * enhanced_multiplier)
      else
        false # Exceeds safe height limits
      end
    end

    def meets_runout_requirements?(runout_length, platform_height, has_stop_wall: false)
      # EN 14960-1:2019 Section 4.2.11 (Lines 930-939) - Runout requirements
      # Lines 934-935: The runout area must extend at least half the platform's height
      # or 300mm (whichever is greater) to allow users to decelerate safely
      return false if runout_length.nil? || platform_height.nil?

      required_runout = calculate_runout_value(platform_height, has_stop_wall: has_stop_wall)
      runout_length >= required_runout
    end

    def slide_runout_formula_text
      ratio_constant = RUNOUT_CALCULATION_CONSTANTS[:platform_height_ratio]
      height_ratio = (ratio_constant * 100).to_i
      min_constant = RUNOUT_CALCULATION_CONSTANTS[:minimum_runout_meters]
      min_runout = (min_constant * 1000).to_i
      "#{height_ratio}% of platform height, minimum #{min_runout}mm"
    end

    def calculate_wall_height_requirements(platform_height, user_height, has_permanent_roof = nil)
      # EN 14960-1:2019 Section 4.2.9 (Lines 854-887) - Containment requirements
      return CalculatorResponse.new(value: 0, value_suffix: "m", breakdown: []) if platform_height.nil? || user_height.nil? || platform_height <= 0 || user_height <= 0

      # Get requirement details and breakdown
      requirement_details = get_wall_height_requirement_details(platform_height, user_height, has_permanent_roof)

      # Extract the required wall height from the details
      required_height = extract_required_wall_height(platform_height, user_height)

      CalculatorResponse.new(
        value: required_height,
        value_suffix: "m",
        breakdown: requirement_details[:breakdown]
      )
    end

    def get_wall_height_requirement_details(platform_height, user_height, has_permanent_roof)
      no_walls_threshold = SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]
      basic_threshold = SLIDE_HEIGHT_THRESHOLDS[:basic_walls]
      enhanced_threshold = SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]
      max_threshold = SLIDE_HEIGHT_THRESHOLDS[:max_safe_height]
      enhanced_multiplier = WALL_HEIGHT_CONSTANTS[:enhanced_height_multiplier]

      case platform_height
      when 0..no_walls_threshold
        {
          text: I18n.t("safety_standards.wall_heights.no_walls_required"),
          breakdown: [
            [
              I18n.t("safety_standards.wall_heights.height_range"),
              I18n.t("safety_standards.wall_heights.under_600mm")
            ],
            [
              I18n.t("safety_standards.wall_heights.requirement"),
              I18n.t("safety_standards.wall_heights.no_walls_required")
            ]
          ]
        }
      when (no_walls_threshold..basic_threshold)
        {
          text: I18n.t("safety_standards.wall_heights.walls_equal_user_height", height: user_height),
          breakdown: [
            [
              I18n.t("safety_standards.wall_heights.height_range"),
              I18n.t("safety_standards.wall_heights.600mm_to_3m")
            ],
            [
              I18n.t("safety_standards.wall_heights.calculation"),
              I18n.t("safety_standards.wall_heights.equal_to_user_height", height: user_height)
            ]
          ]
        }
      when (basic_threshold..enhanced_threshold)
        required_height = (user_height * enhanced_multiplier).round(2)
        breakdown = [
          [
            I18n.t("safety_standards.wall_heights.height_range"),
            I18n.t("safety_standards.wall_heights.3m_to_6m")
          ],
          [
            I18n.t("safety_standards.wall_heights.calculation"),
            "#{user_height}m × #{enhanced_multiplier} = #{required_height}m"
          ],
          [
            I18n.t("safety_standards.wall_heights.alternative_requirement"),
            I18n.t("safety_standards.wall_heights.permanent_roof_alternative")
          ]
        ]

        # Add roof status if known
        if !has_permanent_roof.nil?
          breakdown << if has_permanent_roof
            [
              I18n.t("safety_standards.wall_heights.permanent_roof"),
              I18n.t("safety_standards.wall_heights.roof_fitted")
            ]
          else
            [
              I18n.t("safety_standards.wall_heights.permanent_roof"),
              I18n.t("safety_standards.wall_heights.roof_not_fitted")
            ]
          end
        end

        {
          text: I18n.t("safety_standards.wall_heights.walls_125_user_height", height: required_height),
          breakdown: breakdown
        }
      when (enhanced_threshold..max_threshold)
        required_height = (user_height * enhanced_multiplier).round(2)
        breakdown = [
          [
            I18n.t("safety_standards.wall_heights.height_range"),
            I18n.t("safety_standards.wall_heights.over_6m")
          ],
          [
            I18n.t("safety_standards.wall_heights.calculation"),
            "#{user_height}m × #{enhanced_multiplier} = #{required_height}m"
          ],
          [
            I18n.t("safety_standards.wall_heights.additional_requirement"),
            I18n.t("safety_standards.wall_heights.permanent_roof_required")
          ]
        ]

        # Add roof status if known
        if !has_permanent_roof.nil?
          breakdown << if has_permanent_roof
            [
              I18n.t("safety_standards.wall_heights.permanent_roof"),
              I18n.t("safety_standards.wall_heights.roof_required_and_fitted")
            ]
          else
            [
              I18n.t("safety_standards.wall_heights.permanent_roof"),
              I18n.t("safety_standards.wall_heights.roof_required_but_not_fitted")
            ]
          end
        end

        {
          text: I18n.t("safety_standards.wall_heights.walls_125_plus_roof_required", height: required_height),
          breakdown: breakdown
        }
      else
        {
          text: I18n.t("safety_standards.wall_heights.exceeds_safe_limits"),
          breakdown: [
            [
              I18n.t("safety_standards.wall_heights.status"),
              I18n.t("safety_standards.wall_heights.exceeds_safe_limits")
            ]
          ]
        }
      end
    end

    private

    def extract_required_wall_height(platform_height, user_height)
      no_walls_threshold = SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]
      basic_threshold = SLIDE_HEIGHT_THRESHOLDS[:basic_walls]
      enhanced_threshold = SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]
      enhanced_multiplier = WALL_HEIGHT_CONSTANTS[:enhanced_height_multiplier]

      case platform_height
      when 0..no_walls_threshold
        0 # No walls required
      when (no_walls_threshold..basic_threshold)
        user_height # Equal to user height
      when (basic_threshold..enhanced_threshold), (enhanced_threshold..SLIDE_HEIGHT_THRESHOLDS[:max_safe_height])
        (user_height * enhanced_multiplier).round(2) # 1.25× user height
      else
        0 # Exceeds safe limits
      end
    end

    public

    def requires_permanent_roof?(platform_height)
      # EN 14960-1:2019 Section 4.2.9 (Lines 865-866)
      # Inflatable structures with platforms higher than 6.0m must be equipped
      # with both containing walls and a permanent roof
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
