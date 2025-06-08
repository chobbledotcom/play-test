class AddDimensionFieldsToUnits < ActiveRecord::Migration[8.0]
  def change
    # Anchorage dimensions
    add_column :units, :num_low_anchors, :integer
    add_column :units, :num_high_anchors, :integer

    # Enclosed dimensions
    add_column :units, :exit_number, :integer

    # Materials dimensions
    add_column :units, :rope_size, :decimal, precision: 8, scale: 2

    # Slide dimensions
    add_column :units, :slide_platform_height, :decimal, precision: 8, scale: 2
    add_column :units, :slide_wall_height, :decimal, precision: 8, scale: 2
    add_column :units, :runout_value, :decimal, precision: 8, scale: 2
    add_column :units, :slide_first_metre_height, :decimal, precision: 8, scale: 2
    add_column :units, :slide_beyond_first_metre_height, :decimal, precision: 8, scale: 2

    # Structure dimensions
    add_column :units, :stitch_length, :decimal, precision: 8, scale: 2
    add_column :units, :evacuation_time, :decimal, precision: 8, scale: 2
    add_column :units, :unit_pressure_value, :decimal, precision: 8, scale: 2
    add_column :units, :blower_tube_length, :decimal, precision: 8, scale: 2
    add_column :units, :step_size_value, :decimal, precision: 8, scale: 2
    add_column :units, :fall_off_height_value, :decimal, precision: 8, scale: 2
    add_column :units, :trough_depth_value, :decimal, precision: 8, scale: 2
    add_column :units, :trough_width_value, :decimal, precision: 8, scale: 2

    # User height dimensions
    add_column :units, :containing_wall_height, :decimal, precision: 8, scale: 2
    add_column :units, :platform_height, :decimal, precision: 8, scale: 2
    add_column :units, :user_height, :decimal, precision: 8, scale: 2
    add_column :units, :users_at_1000mm, :integer
    add_column :units, :users_at_1200mm, :integer
    add_column :units, :users_at_1500mm, :integer
    add_column :units, :users_at_1800mm, :integer
    add_column :units, :play_area_length, :decimal, precision: 8, scale: 2
    add_column :units, :play_area_width, :decimal, precision: 8, scale: 2
    add_column :units, :negative_adjustment, :decimal, precision: 8, scale: 2

    # Boolean flags for slides and user height
    add_column :units, :slide_permanent_roof, :boolean
    add_column :units, :permanent_roof, :boolean

    # Environmental measurement (from inspections)
    add_column :units, :ambient_temperature, :decimal, precision: 5, scale: 2
  end
end
