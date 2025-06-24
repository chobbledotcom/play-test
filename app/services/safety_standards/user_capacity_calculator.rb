module SafetyStandards
  module UserCapacityCalculator
    extend self

    # User capacity calculation constants based on EN 14960:2019
    # Divisor for area to calculate number of users per height category
    AREA_DIVISOR = {
      1000 => 1.0,   # 1 user per m² for 1.0m height
      1200 => 1.33,  # 0.75 users per m² for 1.2m height
      1500 => 1.66,  # 0.60 users per m² for 1.5m height
      1800 => 2.0    # 0.5 users per m² for 1.8m height
    }.freeze

    def calculate(length, width, max_user_height = nil)
      return default_capacity if length.nil? || width.nil?

      area = length * width
      capacity = {}

      # Calculate capacity for each height category up to the maximum allowed
      AREA_DIVISOR.each do |height_mm, divisor|
        height_m = height_mm / 1000.0

        # Only calculate if no max height or height is within limit
        capacity[:"users_#{height_mm}mm"] = if max_user_height.nil? || height_m <= max_user_height
          (area / divisor).floor
        else
          0
        end
      end

      capacity
    end

    private

    def default_capacity
      {
        users_1000mm: 0,
        users_1200mm: 0,
        users_1500mm: 0,
        users_1800mm: 0
      }
    end
  end
end
