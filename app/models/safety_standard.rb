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

  # Anchor calculation constants (EN 14960:2019)
  ANCHOR_CALCULATION_CONSTANTS = {
    area_coefficient: 114.0,     # Area coefficient in anchor formula
    base_divisor: 1600.0,        # Base divisor for anchor calculation
    safety_factor: 1.5           # Safety factor multiplier
  }.freeze

  # User space requirements by age group (EN 14960:2019)
  USER_SPACE_REQUIREMENTS = {
    young_children_1000mm: 1.5,  # 1.5m² per young child (1.0m height)
    children_1200mm: 2.0,        # 2.0m² per child (1.2m height)
    adolescents_1500mm: 2.5,     # 2.5m² per adolescent (1.5m height)
    adults_1800mm: 3.0           # 3.0m² per adult (1.8m height)
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

  class << self
    def height_categories
      HEIGHT_CATEGORIES
    end

    def calculation_metadata
      {
        anchors: {
          title: "Anchor Requirements",
          description: "Anchors must be calculated based on the play area to " \
                       "ensure adequate ground restraint for wind loads.",
          method_name: :calculate_required_anchors,
          example_input: 25.0,
          input_unit: "m²",
          output_unit: "anchors",
          formula_text: anchor_formula_text,
          standard_reference: "EN 14960:2019"
        },
        user_capacity: {
          title: "User Capacity Calculations",
          description: "Based on age-appropriate space allocation per " \
                       "user by height category.",
          method_name: :calculate_user_capacity,
          example_input: [5.0, 4.0, 2.0],
          input_unit: ["length (m)", "width (m)", "negative adjustment (m²)"],
          output_unit: "users per category",
          formula_text: "Usable area ÷ space requirement per age group",
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

    private

    def anchor_formula_text
      area_coeff = ANCHOR_CALCULATION_CONSTANTS[:area_coefficient]
      base_div = ANCHOR_CALCULATION_CONSTANTS[:base_divisor]
      safety_fact = ANCHOR_CALCULATION_CONSTANTS[:safety_factor]
      "((Area² × #{area_coeff}) ÷ #{base_div}) × #{safety_fact} safety factor"
    end

    def slide_runout_formula_text
      height_ratio = (RUNOUT_CALCULATION_CONSTANTS[:platform_height_ratio] * 100).to_i
      min_runout = (RUNOUT_CALCULATION_CONSTANTS[:minimum_runout_meters] * 1000).to_i
      "#{height_ratio}% of platform height, minimum #{min_runout}mm"
    end

    public

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
    rescue => e
      "Error retrieving source: #{e.message}"
    end

    def get_related_constants(method_name)
      case method_name
      when :calculate_required_anchors
        ["ANCHOR_CALCULATION_CONSTANTS"]
      when :calculate_user_capacity
        ["USER_SPACE_REQUIREMENTS"]
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
        area_input = "#{area}#{metadata[:input_unit]} area"
        "For #{area_input}: #{result} #{metadata[:output_unit]} required"
      when :user_capacity
        length, width, negative_adj = metadata[:example_input]
        result = calculate_user_capacity(length, width, negative_adj)
        usable_area = (length * width) - negative_adj
        area_desc = "#{length}m × #{width}m (#{usable_area}m² usable)"
        "For #{area_desc}: #{result[:users_1200mm]} children (1.2m category)"
      when :slide_runout
        platform_height = metadata[:example_input]
        result = calculate_required_runout(platform_height)
        platform_desc = "#{platform_height}#{metadata[:input_unit]} platform"
        "For #{platform_desc}: #{result}#{metadata[:output_unit]} runout required"
      when :wall_height
        user_height = metadata[:example_input]
        case user_height
        when 0..SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]
          requirement = "No containing walls required"
        when SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]..
             SLIDE_HEIGHT_THRESHOLDS[:basic_walls]
          requirement = "Walls must be at least #{user_height}m " \
                        "(equal to user height)"
        when SLIDE_HEIGHT_THRESHOLDS[:basic_walls]..
             SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]
          multiplier = WALL_HEIGHT_CONSTANTS[:enhanced_height_multiplier]
          wall_height = (user_height * multiplier).round(2)
          requirement = "Walls must be at least #{wall_height}m " \
                        "(#{multiplier}× user height)"
        end
        height_desc = "#{user_height}#{metadata[:input_unit]} user height"
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
      when SLIDE_HEIGHT_THRESHOLDS[:no_walls_required]..
           SLIDE_HEIGHT_THRESHOLDS[:basic_walls]
        containing_wall_height >= user_height
      when SLIDE_HEIGHT_THRESHOLDS[:basic_walls]..
           SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]
        containing_wall_height >= (user_height * enhanced_multiplier)
      when SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]..
           SLIDE_HEIGHT_THRESHOLDS[:max_safe_height]
        containing_wall_height >= (user_height * enhanced_multiplier) # Plus permanent roof required
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

    def calculate_required_runout(platform_height)
      # EN 14960:2019 - Minimum runout distance calculation using
      # RUNOUT_CALCULATION_CONSTANTS for safe landing
      return 0 if platform_height.nil? || platform_height <= 0

      # Calculate using constants from RUNOUT_CALCULATION_CONSTANTS
      height_ratio = RUNOUT_CALCULATION_CONSTANTS[:platform_height_ratio]
      minimum_runout = RUNOUT_CALCULATION_CONSTANTS[:minimum_runout_meters]

      [platform_height * height_ratio, minimum_runout].max
    end

    def calculate_required_anchors(area_m2)
      # EN 14960:2019 - Anchor point calculation: ((Area² × area_coefficient) ÷ base_divisor) × safety_factor, ensuring adequate ground restraint for wind loads
      # Formula from original Windows app: ((Area² × area_coefficient) ÷ base_divisor) × safety_factor, rounded up
      return 0 if area_m2.nil? || area_m2 <= 0

      # Formula using constants from ANCHOR_CALCULATION_CONSTANTS
      area_coeff = ANCHOR_CALCULATION_CONSTANTS[:area_coefficient]
      base_div = ANCHOR_CALCULATION_CONSTANTS[:base_divisor]
      safety_mult = ANCHOR_CALCULATION_CONSTANTS[:safety_factor]

      ((area_m2.to_f**2 * area_coeff) / base_div * safety_mult).ceil
    end

    def calculate_user_capacity(length, width, negative_adjustment = 0)
      # EN 14960:2019 - User capacity based on age-appropriate space allocation using USER_SPACE_REQUIREMENTS constants
      return {} if length.nil? || width.nil?

      usable_area = (length * width) - (negative_adjustment || 0)
      return {} if usable_area <= 0

      # Standard capacity calculation using constants from USER_SPACE_REQUIREMENTS
      {
        users_1000mm: (usable_area / USER_SPACE_REQUIREMENTS[:young_children_1000mm]).floor,
        users_1200mm: (usable_area / USER_SPACE_REQUIREMENTS[:children_1200mm]).floor,
        users_1500mm: (usable_area / USER_SPACE_REQUIREMENTS[:adolescents_1500mm]).floor,
        users_1800mm: (usable_area / USER_SPACE_REQUIREMENTS[:adults_1800mm]).floor
      }
    end

    def slide_calculations
      # EN 14960:2019 - Comprehensive slide safety requirements including containing wall heights, runout specifications, and gradient limitations
      {
        containing_wall_heights: {
          under_600mm: "No containing walls required",
          between_600_3000mm: "Containing walls required of user height",
          between_3000_6000mm: "Containing walls required #{WALL_HEIGHT_CONSTANTS[:enhanced_height_multiplier]} times user height",
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
      # EN 14960:2019 & EN 71-3 - Material specifications using MATERIAL_STANDARDS constants
      fabric_standards = MATERIAL_STANDARDS[:fabric]
      thread_standards = MATERIAL_STANDARDS[:thread]
      rope_standards = MATERIAL_STANDARDS[:rope]
      netting_standards = MATERIAL_STANDARDS[:netting]

      {
        fabric: {
          tensile_strength: "#{fabric_standards[:min_tensile_strength]} Newtons minimum",
          tear_strength: "#{fabric_standards[:min_tear_strength]} Newtons minimum",
          fire_retardancy: "Must meet #{fabric_standards[:fire_standard]} requirements"
        },
        thread: {
          material: "Non-rotting yarn required",
          tensile_strength: "#{thread_standards[:min_tensile_strength]} Newtons minimum",
          stitch_type: "Lock stitching required"
        },
        rope: {
          diameter_range: "#{rope_standards[:min_diameter]}mm - #{rope_standards[:max_diameter]}mm",
          material: "Non-monofilament",
          attachment: "Fixed at both ends",
          swing_limitation: "No greater than #{rope_standards[:max_swing_percentage]}% swing to prevent strangulation"
        },
        netting: {
          vertical_mesh_size: "#{netting_standards[:max_vertical_mesh]}mm maximum for >1m height",
          roof_mesh_size: "#{netting_standards[:max_roof_mesh]}mm maximum",
          strength: "Support heaviest intended user"
        }
      }
    end

    def electrical_requirements
      # PAT testing standards and EN 14960:2019 - Electrical safety requirements using EQUIPMENT_SAFETY_LIMITS and GROUNDING_TEST_WEIGHTS
      safety_limits = EQUIPMENT_SAFETY_LIMITS
      test_weights = GROUNDING_TEST_WEIGHTS
      netting_mesh = MATERIAL_STANDARDS[:netting][:max_roof_mesh]

      {
        pat_testing: "Portable Appliance Test required",
        blower_requirements: {
          minimum_pressure: "#{safety_limits[:min_pressure]} KPA operational pressure",
          finger_probe: "#{netting_mesh}mm probe must not contact moving/hot parts",
          return_flap: "Required to reduce deflation time",
          distance: "#{safety_limits[:min_blower_distance]}m minimum from equipment edge"
        },
        grounding_test: {
          "1.0m_height": "#{test_weights[:height_1000mm]}kg test weight",
          "1.2m_height": "#{test_weights[:height_1200mm]}kg test weight",
          "1.5m_height": "#{test_weights[:height_1500mm]}kg test weight",
          "1.8m_height": "#{test_weights[:height_1800mm]}kg test weight"
        }
      }
    end

    # Validation methods for business rules
    def valid_stitch_length?(length_mm)
      # EN 14960:2019 - Stitch length must be within specified range to ensure adequate seam strength while maintaining fabric integrity
      min_length = MATERIAL_STANDARDS[:thread][:stitch_length_min]
      max_length = MATERIAL_STANDARDS[:thread][:stitch_length_max]
      length_mm.present? && length_mm.between?(min_length, max_length)
    end

    def valid_pressure?(pressure_kpa)
      # EN 14960:2019 - Minimum operational pressure required to maintain structural integrity and prevent collapse
      min_pressure = EQUIPMENT_SAFETY_LIMITS[:min_pressure]
      pressure_kpa.present? && pressure_kpa >= min_pressure
    end

    def valid_fall_height?(height_m)
      # EN 14960:2019 - Maximum fall height to minimize injury risk from accidental falls outside the structure
      max_height = EQUIPMENT_SAFETY_LIMITS[:max_fall_height]
      height_m.present? && height_m <= max_height
    end

    def valid_rope_diameter?(diameter_mm)
      # EN 14960:2019 - Rope diameter range prevents finger entrapment while ensuring adequate grip and structural strength
      min_diameter = MATERIAL_STANDARDS[:rope][:min_diameter]
      max_diameter = MATERIAL_STANDARDS[:rope][:max_diameter]
      diameter_mm.present? && diameter_mm.between?(min_diameter, max_diameter)
    end

    def requires_permanent_roof?(user_height)
      # EN 14960:2019 - Permanent roof mandatory for user heights above enhanced walls threshold to prevent users from being thrown clear
      user_height.present? && user_height > SLIDE_HEIGHT_THRESHOLDS[:enhanced_walls]
    end

    def requires_multiple_exits?(user_count)
      # EN 14960:2019 - Multiple exits required above threshold to ensure adequate emergency evacuation capacity and prevent overcrowding
      threshold = EQUIPMENT_SAFETY_LIMITS[:multi_exit_threshold]
      user_count.present? && user_count > threshold
    end

    private

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
