class AddDimensionsToInspections < ActiveRecord::Migration[8.0]
  def change
    # Add ALL unit dimensions to inspections to preserve historical data
    # Basic dimensions
    add_column :inspections, :width, :decimal, precision: 8, scale: 2
    add_column :inspections, :length, :decimal, precision: 8, scale: 2
    add_column :inspections, :height, :decimal, precision: 8, scale: 2

    # Anchorage dimensions
    add_column :inspections, :num_low_anchors, :integer
    add_column :inspections, :num_high_anchors, :integer

    # Enclosed dimensions
    add_column :inspections, :exit_number, :integer

    # Materials dimensions
    add_column :inspections, :rope_size, :decimal, precision: 8, scale: 2

    # Slide dimensions
    add_column :inspections, :slide_platform_height, :decimal, precision: 8, scale: 2
    add_column :inspections, :slide_wall_height, :decimal, precision: 8, scale: 2
    add_column :inspections, :runout_value, :decimal, precision: 8, scale: 2
    add_column :inspections, :slide_first_metre_height, :decimal, precision: 8, scale: 2
    add_column :inspections, :slide_beyond_first_metre_height, :decimal, precision: 8, scale: 2

    # Structure dimensions
    add_column :inspections, :stitch_length, :decimal, precision: 8, scale: 2
    add_column :inspections, :evacuation_time, :decimal, precision: 8, scale: 2
    add_column :inspections, :unit_pressure_value, :decimal, precision: 8, scale: 2
    add_column :inspections, :blower_tube_length, :decimal, precision: 8, scale: 2
    add_column :inspections, :step_size_value, :decimal, precision: 8, scale: 2
    add_column :inspections, :fall_off_height_value, :decimal, precision: 8, scale: 2
    add_column :inspections, :trough_depth_value, :decimal, precision: 8, scale: 2
    add_column :inspections, :trough_width_value, :decimal, precision: 8, scale: 2

    # User height dimensions
    add_column :inspections, :containing_wall_height, :decimal, precision: 8, scale: 2
    add_column :inspections, :platform_height, :decimal, precision: 8, scale: 2
    add_column :inspections, :user_height, :decimal, precision: 8, scale: 2
    add_column :inspections, :users_at_1000mm, :integer
    add_column :inspections, :users_at_1200mm, :integer
    add_column :inspections, :users_at_1500mm, :integer
    add_column :inspections, :users_at_1800mm, :integer
    add_column :inspections, :play_area_length, :decimal, precision: 8, scale: 2
    add_column :inspections, :play_area_width, :decimal, precision: 8, scale: 2
    add_column :inspections, :negative_adjustment, :decimal, precision: 8, scale: 2

    # Boolean flags for slides and user height
    add_column :inspections, :slide_permanent_roof, :boolean
    add_column :inspections, :permanent_roof, :boolean

    # Note: ambient_temperature already exists in inspections table
  end
end
