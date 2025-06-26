module SafetyStandard
  extend self

  # Height category constants based on EN 14960:2019
  HEIGHT_CATEGORIES = {
    1000 => {label: "1.0m (Young children)", max_users: :calculate_by_area},
    1200 => {label: "1.2m (Children)", max_users: :calculate_by_area},
    1500 => {label: "1.5m (Adolescents)", max_users: :calculate_by_area},
    1800 => {label: "1.8m (Adults)", max_users: :calculate_by_area}
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
      platform_height: 2.0,
      user_height: 1.5
    },
    user_capacity: {
      type: "user_capacity",
      length: 10.0,
      width: 8.0,
      max_user_height: 1.5
    }
  }.freeze

  # API Example Responses
  API_EXAMPLE_RESPONSES = {
    anchors: {
      passed: true,
      status: "Calculation completed successfully",
      result: {
        value: 8,
        value_suffix: "",
        breakdown: [
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
        value: 1.25,
        value_suffix: "m",
        breakdown: [
          ["50% calculation", "2.5m × 0.5 = 1.25m"],
          ["Minimum requirement", "0.3m (300mm)"],
          ["Base runout", "Maximum of 1.25m and 0.3m = 1.25m"]
        ]
      }
    },
    wall_height: {
      passed: true,
      status: "Calculation completed successfully",
      result: {
        value: 1.5,
        value_suffix: "m",
        breakdown: [
          ["Height range", "0.6m - 3.0m"],
          ["Calculation", "1.5m (user height)"]
        ]
      }
    },
    user_capacity: {
      passed: true,
      status: "Calculation completed successfully",
      result: {
        length: 10.0,
        width: 8.0,
        area: 80.0,
        max_user_height: 1.5,
        capacities: {
          users_1000mm: 80,
          users_1200mm: 60,
          users_1500mm: 48,
          users_1800mm: 0
        }
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
          description: I18n.t("safety_standards.calculators.anchor.description"),
          method_name: :calculate_required_anchors,
          module_name: SafetyStandards::AnchorCalculator,
          example_input: 25.0,
          input_unit: "m²",
          output_unit: "anchors",
          formula_text: "((Area × 114.0 × 1.5) ÷ 1600.0)",
          standard_reference: "EN 14960:2019"
        },
        slide_runout: {
          title: "Slide Runout Requirements",
          description: "Minimum runout distance for safe slide deceleration.",
          method_name: :calculate_required_runout,
          module_name: SafetyStandards::SlideCalculator,
          example_input: 2.5,
          input_unit: "m",
          output_unit: "m",
          formula_text: "50% of platform height, minimum 300mm",
          standard_reference: "EN 14960:2019"
        },
        wall_height: {
          title: "Wall Height Requirements",
          description: "Containing wall heights must scale with user height based on platform height thresholds.",
          method_name: :meets_height_requirements?,
          module_name: SafetyStandards::SlideCalculator,
          example_input: {platform_height: 2.0, user_height: 1.5},
          input_unit: "m",
          output_unit: "requirement text",
          formula_text: "Tiered requirements based on platform height thresholds",
          standard_reference: "EN 14960:2019"
        },
        user_capacity: {
          title: "User Capacity Calculation",
          description: I18n.t("safety_standards.calculators.user_capacity.description"),
          method_name: :calculate,
          module_name: SafetyStandards::UserCapacityCalculator,
          example_input: {length: 10.0, width: 8.0},
          input_unit: "m",
          output_unit: "users",
          formula_text: "Area ÷ space_per_user (varies by height: 1-2 m² per user)",
          standard_reference: "EN 14960:2019"
        }
      }
    end

    def get_method_source(method_name, module_name)
      method_obj = module_name.method(method_name)
      source_location = method_obj.source_location

      return "Source code not available" unless source_location

      file_path, line_number = source_location
      return "Source file not found" unless File.exist?(file_path)

      lines = File.readlines(file_path)

      # Get constants from the module file first
      constants_section = ""
      module_constants = get_module_constants(module_name, method_name)

      if module_constants.any?
        constants_section = "# Related Constants:\n"
        module_constants.each do |constant_name|
          constants_section += extract_constant_definition(lines, constant_name)
        end
        constants_section += "\n# Method Implementation:\n"
      end

      method_lines = extract_method_lines(lines, line_number - 1, method_name)
      constants_section + method_lines.join("")
    end

    def get_module_constants(module_name, method_name)
      # Get all constants defined in the module
      module_name.constants.select do |const_name|
        # Only include constants that are hashes (our configuration constants)
        module_name.const_get(const_name).is_a?(Hash)
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
        # Create dimensions that result in the example area (assuming square for simplicity)
        side_length = Math.sqrt(area).round(1)
        height = 3.0 # Standard height
        result = SafetyStandards::AnchorCalculator.calculate(
          length: side_length,
          width: side_length,
          height: height
        ).value
        input_unit = metadata[:input_unit]
        area_input = "#{area}#{input_unit} area"
        output_unit = metadata[:output_unit]
        "For #{area_input}: #{result} #{output_unit} required"
      when :slide_runout
        platform_height = metadata[:example_input]
        result = SafetyStandards::SlideCalculator.calculate_required_runout(platform_height).value
        input_unit = metadata[:input_unit]
        platform_desc = "#{platform_height}#{input_unit} platform"
        output_unit = metadata[:output_unit]
        "For #{platform_desc}: #{result}#{output_unit} runout required"
      when :wall_height
        example = metadata[:example_input]
        platform_height = example[:platform_height]
        user_height = example[:user_height]
        thresholds = SafetyStandards::SlideCalculator::SLIDE_HEIGHT_THRESHOLDS
        case platform_height
        when 0..thresholds[:no_walls_required]
          requirement = "No containing walls required"
        when (thresholds[:no_walls_required]..thresholds[:basic_walls])
          height_desc = "(equal to user height)"
          requirement = "Walls must be at least #{user_height}m #{height_desc}"
        when (thresholds[:basic_walls]..thresholds[:enhanced_walls])
          multiplier = SafetyStandards::SlideCalculator::WALL_HEIGHT_CONSTANTS[:enhanced_height_multiplier]
          wall_height = (user_height * multiplier).round(2)
          height_desc = "(#{multiplier}× user height)"
          requirement = "Walls must be at least #{wall_height}m #{height_desc}"
        end
        input_unit = metadata[:input_unit]
        "For platform height #{platform_height}#{input_unit}, user height #{user_height}#{input_unit}: #{requirement}"
      when :user_capacity
        example = metadata[:example_input]
        length = example[:length]
        width = example[:width]
        capacity = SafetyStandards::UserCapacityCalculator.calculate(length, width)
        area = length * width
        "For #{area}m² area (#{length}m × #{width}m): " \
          "1.0m users: #{capacity[:users_1000mm]}, " \
          "1.2m users: #{capacity[:users_1200mm]}, " \
          "1.5m users: #{capacity[:users_1500mm]}, " \
          "1.8m users: #{capacity[:users_1800mm]}"
      else
        "Example not available for #{calculation_type}"
      end
    end

    def slide_calculations
      # EN 14960:2019 - Comprehensive slide safety requirements
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
