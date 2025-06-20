module SafetyStandard
  extend self

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

  # Anchor calculation constants (EN 14960:2019)
  ANCHOR_CALCULATION_CONSTANTS = {
    area_coefficient: 114.0,     # Area coefficient in anchor formula
    base_divisor: 1600.0,        # Base divisor for anchor calculation
    safety_factor: 1.5           # Safety factor multiplier
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

  # Material safety standards (EN 14960:2019 & EN 71-3)
  MATERIAL_STANDARDS = {
    fabric: {
      min_tensile_strength: 1850,    # Newtons minimum
      min_tear_strength: 350,        # Newtons minimum
      fire_standard: "EN 71-3"       # Fire retardancy standard
    },
    thread: {
      min_tensile_strength: 88,      # Newtons minimum
      stitch_length_min: 3,          # mm minimum
      stitch_length_max: 8           # mm maximum
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

  # Equipment safety limits (EN 14960:2019)
  EQUIPMENT_SAFETY_LIMITS = {
    max_fall_height: 0.6,            # meters (600mm)
    min_pressure: 1.0,               # KPA operational pressure
    max_evacuation_time: 30,         # seconds
    min_blower_distance: 1.2,        # meters from equipment edge
    multi_exit_threshold: 15,        # users requiring multiple exits
    max_inclination_degrees: 10      # degrees maximum for runouts
  }.freeze

  # Grounding test weights by user height (EN 14960:2019)
  GROUNDING_TEST_WEIGHTS = {
    height_1000mm: 25,               # kg test weight for 1.0m users
    height_1200mm: 35,               # kg test weight for 1.2m users
    height_1500mm: 65,               # kg test weight for 1.5m users
    height_1800mm: 85                # kg test weight for 1.8m users
  }.freeze

  # Reinspection interval
  REINSPECTION_INTERVAL_DAYS = 365  # days

  # API Example Parameters
  API_EXAMPLE_PARAMS = {
    anchors: {
      type: "anchors",
      length: 5.0,
      width: 5.0,
      height: 3.0
    },
    slide_runout: {
      type: "slide_runout",
      platform_height: 2.5
    },
    wall_height: {
      type: "wall_height",
      user_height: 1.5
    }
  }.freeze

  # API Example Responses
  API_EXAMPLE_RESPONSES = {
    anchors: {
      passed: true,
      status: "Calculation completed successfully",
      result: {
        required_anchors: 8,
        formula_breakdown: [
          ["Front/back area", "5.0m (W) × 3.0m (H) = 15.0m²"],
          ["Sides area", "5.0m (L) × 3.0m (H) = 15.0m²"],
          ["Front & back anchor counts", "((15.0 × 114.0 * 1.5) ÷ 1600.0 = 2"],
          ["Left & right anchor counts", "((15.0 × 114.0 * 1.5) ÷ 1600.0 = 2"],
          ["Total anchors", "(2 + 2) × 2 = 8"]
        ]
      }
    },
    slide_runout: {
      passed: true,
      status: "Calculation completed successfully",
      result: {
        platform_height: 2.5,
        required_runout: 1.25,
        calculation: "50% of 2.5m = 1.25m, minimum 0.3m = 1.25m"
      }
    },
    wall_height: {
      passed: true,
      status: "Calculation completed successfully",
      result: {
        user_height: 1.5,
        requirement: "Walls must be at least 1.5m (equal to user height)",
        requires_roof: false
      }
    }
  }.freeze

  class << self
    def height_categories
      HEIGHT_CATEGORIES
    end

    def calculation_metadata
      {
        anchors: {
          title: "Anchor Requirements",
          description: anchor_calculation_description,
          method_name: :calculate_required_anchors,
          example_input: 25.0,
          input_unit: "m²",
          output_unit: "anchors",
          formula_text: anchor_formula_text,
          standard_reference: "EN 14960:2019"
        },
        slide_runout: {
          title: "Slide Runout Requirements",
          description: "Minimum runout distance for safe slide deceleration.",
          method_name: :calculate_required_runout,
          example_input: 2.5,
          input_unit: "m",
          output_unit: "m",
          formula_text: slide_runout_formula_text,
          standard_reference: "EN 14960:2019"
        },
        wall_height: {
          title: "Wall Height Requirements",
          description: "Containing wall heights must scale with user height.",
          method_name: :meets_height_requirements?,
          example_input: 1.2,
          input_unit: "m",
          output_unit: "requirement text",
          formula_text: "Tiered requirements based on user height thresholds",
          standard_reference: "EN 14960:2019"
        }
      }
    end

    def anchor_formula_text
      area_coeff = ANCHOR_CALCULATION_CONSTANTS[:area_coefficient]
      base_div = ANCHOR_CALCULATION_CONSTANTS[:base_divisor]
      safety_fact = ANCHOR_CALCULATION_CONSTANTS[:safety_factor]
      "((Area × #{area_coeff} × #{safety_fact}) ÷ #{base_div})"
    end

    def slide_runout_formula_text
      ratio_constant = RUNOUT_CALCULATION_CONSTANTS[:platform_height_ratio]
      height_ratio = (ratio_constant * 100).to_i
      min_constant = RUNOUT_CALCULATION_CONSTANTS[:minimum_runout_meters]
      min_runout = (min_constant * 1000).to_i
      "#{height_ratio}% of platform height, minimum #{min_runout}mm"
    end

    def calculate_required_runout(platform_height)
      # EN 14960:2019 - Minimum runout distance calculation using
      # RUNOUT_CALCULATION_CONSTANTS for safe landing
      return 0 if platform_height.nil? || platform_height <= 0

      # Calculate using constants from RUNOUT_CALCULATION_CONSTANTS
      height_ratio = RUNOUT_CALCULATION_CONSTANTS[:platform_height_ratio]
      minimum_runout = RUNOUT_CALCULATION_CONSTANTS[:minimum_runout_meters]

      [platform_height * height_ratio, minimum_runout].max
    end

    def get_method_source(method_name)
      method_obj = method(method_name)
      source_location = method_obj.source_location

      return "Source code not available" unless source_location

      file_path, line_number = source_location
      return "Source file not found" unless File.exist?(file_path)

      lines = File.readlines(file_path)
      method_lines = extract_method_lines(lines, line_number - 1, method_name)

      # Add related constants for complete transparency
      related_constants = get_related_constants(method_name)

      if related_constants.any?
        constants_section = "\n# Related Constants:\n"
        related_constants.each do |constant_name|
          constants_section += extract_constant_definition(lines, constant_name)
        end
        constants_section + "\n# Method Implementation:\n" +
          method_lines.join("")
      else
        method_lines.join("")
      end
    end

    def get_related_constants(method_name)
      case method_name
      when :calculate_required_anchors
        ["ANCHOR_CALCULATION_CONSTANTS"]
      when :calculate_required_runout
        ["RUNOUT_CALCULATION_CONSTANTS"]
      when :meets_height_requirements?
        ["SLIDE_HEIGHT_THRESHOLDS", "WALL_HEIGHT_CONSTANTS"]
      else
        []
      end
    end

    def extract_constant_definition(lines, constant_name)
      constant_lines = []
      in_constant = false
      brace_count = 0

      lines.each_with_index do |line, index|
        if line.strip.start_with?("#{constant_name} =")
          in_constant = true
          constant_lines << "#{index + 1}: #{line}"
          brace_count += line.count("{") - line.count("}")
          next
        end

        if in_constant
          constant_lines << "#{index + 1}: #{line}"
          brace_count += line.count("{") - line.count("}")

          # Check if we've closed all braces and reached the end
          if brace_count <= 0 && (line.strip.end_with?(".freeze") || line.strip == "}")
            break
          end
        end
      end

      constant_lines.join("")
    end

    def generate_example(calculation_type)
      metadata = calculation_metadata[calculation_type]
      return "No metadata available" unless metadata

      case calculation_type
      when :anchors
        area = metadata[:example_input]
        result = calculate_required_anchors(area)
        input_unit = metadata[:input_unit]
        area_input = "#{area}#{input_unit} area"
        output_unit = metadata[:output_unit]
        "For #{area_input}: #{result} #{output_unit} required"
      when :slide_runout
        platform_height = metadata[:example_input]
        result = calculate_required_runout(platform_height)
        input_unit = metadata[:input_unit]
        platform_desc = "#{platform_height}#{input_unit} platform"
        output_unit = metadata[:output_unit]
        "For #{platform_desc}: #{result}#{output_unit} runout required"
      when :wall_height
        user_height = metadata[:example_input]
        case user_height
        when 0..SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]
          requirement = "No containing walls required"
        when (SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]..
              SLIDE_HEIGHT_THRESHOLDS[:basic_walls])
          height_desc = "(equal to user height)"
          requirement = "Walls must be at least #{user_height}m #{height_desc}"
        when (SLIDE_HEIGHT_THRESHOLDS[:basic_walls]..
              SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls])
          multiplier = WALL_HEIGHT_CONSTANTS[:enhanced_height_multiplier]
          wall_height = (user_height * multiplier).round(2)
          height_desc = "(#{multiplier}× user height)"
          requirement = "Walls must be at least #{wall_height}m #{height_desc}"
        end
        input_unit = metadata[:input_unit]
        height_desc = "#{user_height}#{input_unit} user height"
        "For #{height_desc}: #{requirement}"
      else
        "Example not available for #{calculation_type}"
      end
    end

    def meets_height_requirements?(user_height, containing_wall_height)
      # EN 14960:2019 - Containing wall heights must scale with user height
      # using WALL_HEIGHT_CONSTANTS
      return false if user_height.nil? || containing_wall_height.nil?

      enhanced_multiplier = WALL_HEIGHT_CONSTANTS[:enhanced_height_multiplier]

      case user_height
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

    def build_anchor_result(length:, width:, height:)
      front_area = (width * height).round(1)
      sides_area = (length * height).round(1)

      required_front =
        SafetyStandard.calculate_required_anchors(front_area)

      required_sides =
        SafetyStandard.calculate_required_anchors(sides_area)

      total_required = (required_front + required_sides) * 2

      area_coeff = ANCHOR_CALCULATION_CONSTANTS[:area_coefficient]
      base_div = ANCHOR_CALCULATION_CONSTANTS[:base_divisor]
      safety_mult = ANCHOR_CALCULATION_CONSTANTS[:safety_factor]

      formula_front = "((#{front_area} × #{area_coeff} * #{safety_mult}) ÷ #{base_div}"
      formula_sides = "((#{sides_area} × #{area_coeff} * #{safety_mult}) ÷ #{base_div}"

      breakdown = [
        [
          "Front/back area", "#{width}m (W) × #{height}m (H) = #{front_area}m²"
        ],
        [
          "Sides area", "#{length}m (L) × #{height}m (H) = #{sides_area}m²"
        ],
        [
          "Front & back anchor counts", "#{formula_front} = #{required_front}"
        ],
        [
          "Left & right anchor counts", "#{formula_sides} = #{required_sides}"
        ],
        [
          "Total anchors", "(#{required_front} + #{required_sides}) × 2 = #{total_required}"
        ]
      ]

      {
        required_anchors: total_required,
        formula_breakdown: breakdown
      }
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

    # Validation methods for business rules
    def valid_stitch_length?(length_mm)
      # EN 14960:2019 - Stitch length must be within specified range to ensure
      # adequate seam strength while maintaining fabric integrity
      min_length = MATERIAL_STANDARDS[:thread][:stitch_length_min]
      max_length = MATERIAL_STANDARDS[:thread][:stitch_length_max]
      length_mm.present? && length_mm.between?(min_length, max_length)
    end

    def valid_pressure?(pressure_kpa)
      # EN 14960:2019 - Minimum operational pressure required to maintain
      # structural integrity and prevent collapse
      min_pressure = EQUIPMENT_SAFETY_LIMITS[:min_pressure]
      pressure_kpa.present? && pressure_kpa >= min_pressure
    end

    def valid_fall_height?(height_m)
      # EN 14960:2019 - Maximum fall height to minimize injury risk from
      # accidental falls outside the structure
      max_height = EQUIPMENT_SAFETY_LIMITS[:max_fall_height]
      height_m.present? && height_m <= max_height
    end

    def valid_rope_diameter?(diameter_mm)
      # EN 14960:2019 - Rope diameter range prevents finger entrapment while
      # ensuring adequate grip and structural strength
      min_diameter = MATERIAL_STANDARDS[:rope][:min_diameter]
      max_diameter = MATERIAL_STANDARDS[:rope][:max_diameter]
      diameter_mm.present? && diameter_mm.between?(min_diameter, max_diameter)
    end

    def requires_permanent_roof?(user_height)
      # EN 14960:2019 - Permanent roof mandatory for user heights above enhanced
      # walls threshold to prevent users from being thrown clear
      user_height.present? && user_height > SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]
    end

    def requires_multiple_exits?(user_count)
      # EN 14960:2019 - Multiple exits required above threshold
      threshold = EQUIPMENT_SAFETY_LIMITS[:multi_exit_threshold]
      user_count.present? && user_count > threshold
    end

    def wall_height_requirement
      multiplier = WALL_HEIGHT_CONSTANTS[:enhanced_height_multiplier]
      "Containing walls required #{multiplier} times user height"
    end

    def fabric_tensile_requirement(fabric_standards)
      "#{fabric_standards[:min_tensile_strength]} Newtons minimum"
    end

    def fabric_tear_requirement(fabric_standards)
      "#{fabric_standards[:min_tear_strength]} Newtons minimum"
    end

    def anchor_calculation_description
      I18n.t("safety_standards.calculators.anchor.description")
    end


    def extract_method_lines(lines, start_line, method_name)
      method_lines = []
      current_line = start_line
      indent_level = nil

      # Find the method definition line
      while current_line < lines.length
        line = lines[current_line]
        if line.strip.start_with?("def #{method_name}")
          indent_level = line.index("def")
          method_lines << "#{current_line + 1}: #{line}"
          current_line += 1
          break
        end
        current_line += 1
      end

      return ["Method definition not found"] if indent_level.nil?

      # Extract method body until we reach the same or lesser indentation with 'end'
      while current_line < lines.length
        line = lines[current_line]
        method_lines << "#{current_line + 1}: #{line}"

        # Check if we've reached the end of the method
        if line.strip == "end" && (line.index(/\S/) || 0) <= indent_level
          break
        end

        current_line += 1
      end

      method_lines
    end
  end
end
