module SafetyStandards
  module UserCapacityCalculator
    extend self

    # EN 14960-1:2019 Section 4.3 (Lines 940-961) - Number of users
    # Note: EN 14960 doesn't specify exact calculation formulas, only factors to consider:
    # - Height of user (Line 946)
    # - Size of playing area (Line 954)
    # - Type of activity (Line 956)
    # The calculation below is industry standard practice, not from EN 14960
    AREA_DIVISOR = {
      1000 => 1.0,   # 1 user per m² for 1.0m height
      1200 => 1.33,  # 0.75 users per m² for 1.2m height
      1500 => 1.66,  # 0.60 users per m² for 1.5m height
      1800 => 2.0    # 0.5 users per m² for 1.8m height
    }.freeze

    def calculate(length, width, max_user_height = nil, negative_adjustment_area = 0)
      return default_result if length.nil? || width.nil?

      total_area = (length * width).round(2)
      negative_adjustment_area = negative_adjustment_area.to_f.abs
      usable_area = [total_area - negative_adjustment_area, 0].max.round(2)

      breakdown = build_breakdown(length, width, total_area, negative_adjustment_area, usable_area)
      capacities = calculate_capacities(usable_area, max_user_height, breakdown)

      CalculatorResponse.new(
        value: capacities,
        value_suffix: "",
        breakdown: breakdown
      )
    end

    private

    def build_breakdown(length, width, total_area, negative_adjustment_area, usable_area)
      breakdown = []
      formatted_length = format_number(length)
      formatted_width = format_number(width)
      formatted_total = format_number(total_area)
      formatted_usable = format_number(usable_area)

      breakdown << [I18n.t("safety_standards.calculators.user_capacity.total_area"), "#{formatted_length}m × #{formatted_width}m = #{formatted_total}m²"]

      if negative_adjustment_area > 0
        formatted_adjustment = format_number(negative_adjustment_area)
        breakdown << [I18n.t("safety_standards.calculators.user_capacity.obstacles_adjustments"), "- #{formatted_adjustment}m²"]
      end

      breakdown << [I18n.t("safety_standards.calculators.user_capacity.usable_area"), "#{formatted_usable}m²"]
      breakdown << [I18n.t("safety_standards.calculators.user_capacity.capacity_calculations"), I18n.t("safety_standards.calculators.user_capacity.based_on_usable")]

      breakdown
    end

    def calculate_capacities(usable_area, max_user_height, breakdown)
      capacities = {}

      AREA_DIVISOR.each do |height_mm, divisor|
        height_m = height_mm / 1000.0
        key = :"users_#{height_mm}mm"

        if max_user_height.nil? || height_m <= max_user_height
          capacity = (usable_area / divisor).floor
          capacities[key] = capacity
          formatted_area = format_number(usable_area)
          formatted_divisor = format_number(divisor)
          calculation = "#{formatted_area} ÷ #{formatted_divisor} = #{capacity} "
          calculation += (capacity == 1) ? "user" : "users"
          breakdown << ["#{format_number(height_m)}m users", calculation]
        else
          capacities[key] = 0
          breakdown << ["#{format_number(height_m)}m users", I18n.t("safety_standards.calculators.user_capacity.not_allowed")]
        end
      end

      capacities
    end

    def default_result
      CalculatorResponse.new(
        value: default_capacity,
        value_suffix: "",
        breakdown: [[I18n.t("safety_standards.errors.invalid_dimensions"), ""]]
      )
    end

    def default_capacity
      {
        users_1000mm: 0,
        users_1200mm: 0,
        users_1500mm: 0,
        users_1800mm: 0
      }
    end

    def format_number(number)
      # Remove trailing zeros after decimal point
      formatted = sprintf("%.1f", number)
      formatted.sub(/\.0$/, "")
    end
  end
end
