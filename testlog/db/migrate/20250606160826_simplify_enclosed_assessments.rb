class SimplifyEnclosedAssessments < ActiveRecord::Migration[8.0]
  def change
    # Remove all the hallucinated complex fields
    remove_columns :enclosed_assessments,
      :enclosure_type, :ceiling_height, :floor_area_sqm, :occupancy_limit,
      :ventilation_type, :air_changes_per_hour, :emergency_exits, :exit_width_cm,
      :exit_visibility, :emergency_lighting, :fire_extinguisher, :first_aid_kit,
      :supervision_visibility, :internal_obstacles, :ceiling_attachments,
      :wall_attachments, :structural_integrity, :material_flame_rating,
      :seam_construction, :transparency_panels, :interior_temperature,
      :humidity_level, :air_quality, :noise_level_interior, :cleaning_schedule,
      :sanitization_protocol, :maintenance_access, :equipment_storage

    # Add the original 5 simple fields from the C# app
    add_column :enclosed_assessments, :exit_number, :integer
    add_column :enclosed_assessments, :exit_number_pass, :boolean
    add_column :enclosed_assessments, :exit_number_comment, :text
    add_column :enclosed_assessments, :exit_visible_pass, :boolean
    add_column :enclosed_assessments, :exit_visible_comment, :text
  end
end
