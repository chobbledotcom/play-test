class AddMissingCommentFields < ActiveRecord::Migration[8.0]
  def change
    # Add missing comment fields to anchorage_assessments (5 fields missing)
    add_column :anchorage_assessments, :num_anchors_comment, :text
    add_column :anchorage_assessments, :anchor_accessories_comment, :text
    add_column :anchorage_assessments, :anchor_degree_comment, :text
    add_column :anchorage_assessments, :anchor_type_comment, :text
    add_column :anchorage_assessments, :pull_strength_comment, :text

    # Add missing comment fields to materials_assessments (9 fields missing)
    add_column :materials_assessments, :rope_size_comment, :text
    add_column :materials_assessments, :clamber_comment, :text
    add_column :materials_assessments, :retention_netting_comment, :text
    add_column :materials_assessments, :zips_comment, :text
    add_column :materials_assessments, :windows_comment, :text
    add_column :materials_assessments, :artwork_comment, :text
    add_column :materials_assessments, :thread_comment, :text
    add_column :materials_assessments, :fabric_comment, :text
    add_column :materials_assessments, :fire_retardant_comment, :text

    # Add missing comment fields to slide_assessments (7 fields missing)
    add_column :slide_assessments, :slide_wall_height_comment, :text
    add_column :slide_assessments, :slide_first_metre_height_comment, :text
    add_column :slide_assessments, :slide_beyond_first_metre_height_comment, :text
    add_column :slide_assessments, :slide_permanent_roof_comment, :text
    add_column :slide_assessments, :clamber_netting_comment, :text
    add_column :slide_assessments, :runout_comment, :text
    add_column :slide_assessments, :slip_sheet_comment, :text

    # Add missing comment fields to user_height_assessments (5 fields missing)
    add_column :user_height_assessments, :containing_wall_height_comment, :text
    add_column :user_height_assessments, :platform_height_comment, :text
    add_column :user_height_assessments, :play_area_length_comment, :text
    add_column :user_height_assessments, :play_area_width_comment, :text
    add_column :user_height_assessments, :negative_adjustment_comment, :text
    add_column :user_height_assessments, :permanent_roof_comment, :text

    # Add missing comment fields to structure_assessments (major set missing)
    add_column :structure_assessments, :seam_integrity_comment, :text
    add_column :structure_assessments, :lock_stitch_comment, :text
    add_column :structure_assessments, :stitch_length_comment, :text
    add_column :structure_assessments, :air_loss_comment, :text
    add_column :structure_assessments, :straight_walls_comment, :text
    add_column :structure_assessments, :sharp_edges_comment, :text
    add_column :structure_assessments, :blower_tube_length_comment, :text
    add_column :structure_assessments, :unit_stable_comment, :text
    add_column :structure_assessments, :evacuation_time_comment, :text
    add_column :structure_assessments, :step_size_comment, :text
    add_column :structure_assessments, :fall_off_height_comment, :text
    add_column :structure_assessments, :unit_pressure_comment, :text
    add_column :structure_assessments, :trough_comment, :text
    add_column :structure_assessments, :entrapment_comment, :text
    add_column :structure_assessments, :markings_comment, :text
    add_column :structure_assessments, :grounding_comment, :text
  end
end
