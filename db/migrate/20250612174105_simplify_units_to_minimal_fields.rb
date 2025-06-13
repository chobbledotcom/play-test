class SimplifyUnitsToMinimalFields < ActiveRecord::Migration[8.0]
  def change
    # Remove all unnecessary columns from units table
    # Keeping only: id, name, manufacturer, model, serial, description, owner,
    # user_id, notes, manufacture_date, is_seed, created_at, updated_at

    # First, remove the unique index that includes serial_number
    remove_index :units, name: "index_units_on_manufacturer_and_serial_number" if index_exists?(:units, [:manufacturer, :serial_number], name: "index_units_on_manufacturer_and_serial_number")

    # Remove dimensional fields
    remove_column :units, :width, :decimal, precision: 8, scale: 2
    remove_column :units, :length, :decimal, precision: 8, scale: 2
    remove_column :units, :height, :decimal, precision: 8, scale: 2

    # Remove dimensional comment fields
    remove_column :units, :width_comment, :string, limit: 1000
    remove_column :units, :length_comment, :string, limit: 1000
    remove_column :units, :height_comment, :string, limit: 1000

    # Remove anchor fields
    remove_column :units, :num_low_anchors, :integer
    remove_column :units, :num_high_anchors, :integer
    remove_column :units, :num_low_anchors_comment, :string, limit: 1000
    remove_column :units, :num_high_anchors_comment, :string, limit: 1000

    # Remove enclosed/exit fields
    remove_column :units, :exit_number, :integer
    remove_column :units, :exit_number_comment, :string, limit: 1000

    # Remove material fields
    remove_column :units, :rope_size, :decimal, precision: 8, scale: 2
    remove_column :units, :rope_size_comment, :string, limit: 1000

    # Remove slide fields
    remove_column :units, :slide_platform_height, :decimal, precision: 8, scale: 2
    remove_column :units, :slide_wall_height, :decimal, precision: 8, scale: 2
    remove_column :units, :runout, :decimal, precision: 8, scale: 2
    remove_column :units, :slide_first_metre_height, :decimal, precision: 8, scale: 2
    remove_column :units, :slide_beyond_first_metre_height, :decimal, precision: 8, scale: 2
    remove_column :units, :slide_permanent_roof, :boolean
    remove_column :units, :slide_platform_height_comment, :string, limit: 1000
    remove_column :units, :slide_wall_height_comment, :string, limit: 1000
    remove_column :units, :runout_comment, :string, limit: 1000
    remove_column :units, :slide_first_metre_height_comment, :string, limit: 1000
    remove_column :units, :slide_beyond_first_metre_height_comment, :string, limit: 1000
    remove_column :units, :slide_permanent_roof_comment, :string, limit: 1000

    # Remove structure fields
    remove_column :units, :stitch_length, :decimal, precision: 8, scale: 2
    remove_column :units, :evacuation_time, :decimal, precision: 8, scale: 2
    remove_column :units, :unit_pressure_value, :decimal, precision: 8, scale: 2
    remove_column :units, :blower_tube_length, :decimal, precision: 8, scale: 2
    remove_column :units, :step_size_value, :decimal, precision: 8, scale: 2
    remove_column :units, :fall_off_height_value, :decimal, precision: 8, scale: 2
    remove_column :units, :trough_depth_value, :decimal, precision: 8, scale: 2
    remove_column :units, :trough_width_value, :decimal, precision: 8, scale: 2
    remove_column :units, :step_ramp_size, :decimal
    remove_column :units, :critical_fall_off_height, :decimal
    remove_column :units, :unit_pressure, :decimal
    remove_column :units, :trough_depth, :decimal
    remove_column :units, :trough_adjacent_panel_width, :decimal

    # Remove user height fields
    remove_column :units, :containing_wall_height, :decimal, precision: 8, scale: 2
    remove_column :units, :platform_height, :decimal, precision: 8, scale: 2
    remove_column :units, :tallest_user_height, :decimal, precision: 8, scale: 2
    remove_column :units, :users_at_1000mm, :integer
    remove_column :units, :users_at_1200mm, :integer
    remove_column :units, :users_at_1500mm, :integer
    remove_column :units, :users_at_1800mm, :integer
    remove_column :units, :play_area_length, :decimal, precision: 8, scale: 2
    remove_column :units, :play_area_width, :decimal, precision: 8, scale: 2
    remove_column :units, :negative_adjustment, :decimal, precision: 8, scale: 2
    remove_column :units, :permanent_roof, :boolean
    remove_column :units, :containing_wall_height_comment, :string, limit: 1000
    remove_column :units, :platform_height_comment, :string, limit: 1000
    remove_column :units, :permanent_roof_comment, :string, limit: 1000
    remove_column :units, :play_area_length_comment, :string, limit: 1000
    remove_column :units, :play_area_width_comment, :string, limit: 1000
    remove_column :units, :negative_adjustment_comment, :string, limit: 1000

    # Remove other fields (keeping notes, manufacture_date, and is_seed)
    remove_column :units, :condition, :string
    remove_column :units, :is_totally_enclosed, :boolean, default: false
    remove_column :units, :has_slide, :boolean, default: false, null: false
    remove_column :units, :risk_assessment, :text

    # Remove the duplicate serial_number field (keeping serial)
    remove_column :units, :serial_number, :string

    # Remove indexes that reference removed columns (none for serial since we're keeping it)

    # The unique index on manufacturer and serial_number was already removed at the beginning
    add_index :units, [:manufacturer, :serial], unique: true, name: "index_units_on_manufacturer_and_serial"

    # The index on is_seed can stay since we're keeping that field
  end
end
