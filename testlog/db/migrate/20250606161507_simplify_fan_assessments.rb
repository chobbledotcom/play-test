class SimplifyFanAssessments < ActiveRecord::Migration[8.0]
  def change
    # Remove all the hallucinated complex fields
    remove_columns :fan_assessments,
      :blower_type, :blower_power_rating, :blower_voltage, :blower_current_rating,
      :electrical_cord_length, :cord_gauge, :gfi_protection, :weatherproof_rating,
      :grounding_verified, :intake_screen_condition, :air_flow_cfm, :operating_pressure,
      :noise_level_db, :vibration_level, :fan_housing_condition, :motor_condition,
      :electrical_connections, :cord_condition, :plug_condition, :safety_switches,
      :thermal_protection, :manufacturer_label, :ul_listing, :maintenance_schedule

    # Add the original 10 simple fields from the C# app
    add_column :fan_assessments, :fan_size_comment, :text
    add_column :fan_assessments, :blower_flap_pass, :boolean
    add_column :fan_assessments, :blower_flap_comment, :text
    add_column :fan_assessments, :blower_finger_pass, :boolean
    add_column :fan_assessments, :blower_finger_comment, :text
    add_column :fan_assessments, :pat_pass, :boolean
    add_column :fan_assessments, :pat_comment, :text
    add_column :fan_assessments, :blower_visual_pass, :boolean
    add_column :fan_assessments, :blower_visual_comment, :text
    add_column :fan_assessments, :blower_serial, :string
  end
end
