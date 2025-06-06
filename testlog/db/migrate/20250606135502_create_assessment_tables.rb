class CreateAssessmentTables < ActiveRecord::Migration[8.0]
  def change
    # User Height Assessment
    create_table :user_height_assessments do |t|
      t.string :inspection_id, null: false, limit: 12
      t.decimal :containing_wall_height, precision: 8, scale: 2
      t.decimal :platform_height, precision: 8, scale: 2
      t.decimal :user_height, precision: 8, scale: 2
      t.integer :users_at_1000mm
      t.integer :users_at_1200mm
      t.integer :users_at_1500mm
      t.integer :users_at_1800mm
      t.decimal :play_area_length, precision: 8, scale: 2
      t.decimal :play_area_width, precision: 8, scale: 2
      t.decimal :negative_adjustment, precision: 8, scale: 2
      t.boolean :permanent_roof
      t.text :user_height_comment
      t.timestamps
    end

    # Structure Assessment
    create_table :structure_assessments do |t|
      t.string :inspection_id, null: false, limit: 12
      # Critical checks
      t.boolean :seam_integrity_pass
      t.boolean :lock_stitch_pass
      t.boolean :air_loss_pass
      t.boolean :straight_walls_pass
      t.boolean :sharp_edges_pass
      t.boolean :unit_stable_pass
      # Measurements
      t.decimal :stitch_length, precision: 8, scale: 2
      t.decimal :evacuation_time, precision: 8, scale: 2
      t.decimal :unit_pressure_value, precision: 8, scale: 2
      t.decimal :blower_tube_length, precision: 8, scale: 2
      t.decimal :step_size_value, precision: 8, scale: 2
      t.decimal :fall_off_height_value, precision: 8, scale: 2
      t.decimal :trough_depth_value, precision: 8, scale: 2
      t.decimal :trough_width_value, precision: 8, scale: 2
      # Additional checks
      t.boolean :stitch_length_pass
      t.boolean :blower_tube_length_pass
      t.boolean :evacuation_time_pass
      t.boolean :step_size_pass
      t.boolean :fall_off_height_pass
      t.boolean :unit_pressure_pass
      t.boolean :trough_pass
      t.boolean :entrapment_pass
      t.boolean :markings_pass
      t.boolean :grounding_pass
      t.timestamps
    end

    # Slide Assessment
    create_table :slide_assessments do |t|
      t.string :inspection_id, null: false, limit: 12
      t.decimal :slide_platform_height, precision: 8, scale: 2
      t.decimal :slide_wall_height, precision: 8, scale: 2
      t.decimal :runout_value, precision: 8, scale: 2
      t.decimal :slide_first_metre_height, precision: 8, scale: 2
      t.decimal :slide_beyond_first_metre_height, precision: 8, scale: 2
      t.boolean :clamber_netting_pass
      t.boolean :runout_pass
      t.boolean :slip_sheet_pass
      t.boolean :slide_permanent_roof
      t.text :slide_platform_height_comment
      t.timestamps
    end

    # Materials Assessment
    create_table :materials_assessments do |t|
      t.string :inspection_id, null: false, limit: 12
      t.decimal :rope_size, precision: 8, scale: 2
      t.boolean :rope_size_pass
      t.boolean :clamber_pass
      t.boolean :retention_netting_pass
      t.boolean :zips_pass
      t.boolean :windows_pass
      t.boolean :artwork_pass
      t.boolean :thread_pass
      t.boolean :fabric_pass
      t.boolean :fire_retardant_pass
      t.timestamps
    end

    # Fan Assessment
    create_table :fan_assessments do |t|
      t.string :inspection_id, null: false, limit: 12
      t.string :blower_type
      t.decimal :blower_power_rating, precision: 8, scale: 2
      t.integer :blower_voltage
      t.decimal :blower_current_rating, precision: 8, scale: 2
      t.decimal :electrical_cord_length, precision: 8, scale: 2
      t.string :cord_gauge
      t.boolean :gfi_protection
      t.string :weatherproof_rating
      t.boolean :grounding_verified
      t.string :intake_screen_condition
      t.decimal :air_flow_cfm, precision: 8, scale: 2
      t.decimal :operating_pressure, precision: 8, scale: 2
      t.decimal :noise_level_db, precision: 8, scale: 2
      t.string :vibration_level
      t.string :fan_housing_condition
      t.string :motor_condition
      t.string :electrical_connections
      t.string :cord_condition
      t.string :plug_condition
      t.string :safety_switches
      t.string :thermal_protection
      t.string :manufacturer_label
      t.string :ul_listing
      t.string :maintenance_schedule
      t.timestamps
    end

    # Enclosed Assessment
    create_table :enclosed_assessments do |t|
      t.string :inspection_id, null: false, limit: 12
      t.string :enclosure_type
      t.decimal :ceiling_height, precision: 8, scale: 2
      t.decimal :floor_area_sqm, precision: 8, scale: 2
      t.integer :occupancy_limit
      t.string :ventilation_type
      t.decimal :air_changes_per_hour, precision: 8, scale: 2
      t.integer :emergency_exits
      t.decimal :exit_width_cm, precision: 8, scale: 2
      t.string :exit_visibility
      t.string :emergency_lighting
      t.string :fire_extinguisher
      t.string :first_aid_kit
      t.string :supervision_visibility
      t.string :internal_obstacles
      t.string :ceiling_attachments
      t.string :wall_attachments
      t.string :structural_integrity
      t.string :material_flame_rating
      t.string :seam_construction
      t.string :transparency_panels
      t.decimal :interior_temperature, precision: 8, scale: 2
      t.decimal :humidity_level, precision: 8, scale: 2
      t.string :air_quality
      t.decimal :noise_level_interior, precision: 8, scale: 2
      t.string :cleaning_schedule
      t.string :sanitization_protocol
      t.string :maintenance_access
      t.string :equipment_storage
      t.timestamps
    end

    # Anchorage Assessment
    create_table :anchorage_assessments do |t|
      t.string :inspection_id, null: false, limit: 12
      t.integer :num_low_anchors
      t.integer :num_high_anchors
      t.boolean :num_anchors_pass
      t.boolean :anchor_accessories_pass
      t.boolean :anchor_degree_pass
      t.boolean :anchor_type_pass
      t.boolean :pull_strength_pass
      t.timestamps
    end

    # Add foreign key constraints
    add_foreign_key :user_height_assessments, :inspections, primary_key: :id
    add_foreign_key :structure_assessments, :inspections, primary_key: :id
    add_foreign_key :slide_assessments, :inspections, primary_key: :id
    add_foreign_key :materials_assessments, :inspections, primary_key: :id
    add_foreign_key :fan_assessments, :inspections, primary_key: :id
    add_foreign_key :enclosed_assessments, :inspections, primary_key: :id
    add_foreign_key :anchorage_assessments, :inspections, primary_key: :id

    # Add indexes for foreign keys
    add_index :user_height_assessments, :inspection_id
    add_index :structure_assessments, :inspection_id
    add_index :slide_assessments, :inspection_id
    add_index :materials_assessments, :inspection_id
    add_index :fan_assessments, :inspection_id
    add_index :enclosed_assessments, :inspection_id
    add_index :anchorage_assessments, :inspection_id
  end
end
