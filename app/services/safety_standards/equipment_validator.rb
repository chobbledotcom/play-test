module SafetyStandards
  module EquipmentValidator
    extend self

    # Equipment safety limits (EN 14960:2019)
    EQUIPMENT_SAFETY_LIMITS = {
      max_fall_height: 0.6,            # meters (600mm)
      min_pressure: 1.0,               # KPA operational pressure
      max_evacuation_time: 30,         # seconds
      min_blower_distance: 1.2,        # meters from equipment edge
      multi_exit_threshold: 15,        # users requiring multiple exits
      max_inclination_degrees: 10      # degrees maximum for runouts
    }.freeze

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

    def requires_multiple_exits?(user_count)
      # EN 14960:2019 - Multiple exits required above threshold
      threshold = EQUIPMENT_SAFETY_LIMITS[:multi_exit_threshold]
      user_count.present? && user_count > threshold
    end
  end
end
