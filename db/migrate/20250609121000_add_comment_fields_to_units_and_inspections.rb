class AddCommentFieldsToUnitsAndInspections < ActiveRecord::Migration[8.0]
  def change
    # Add comment fields to units table
    add_column :units, :width_comment, :string, limit: 1000
    add_column :units, :length_comment, :string, limit: 1000
    add_column :units, :height_comment, :string, limit: 1000
    add_column :units, :num_low_anchors_comment, :string, limit: 1000
    add_column :units, :num_high_anchors_comment, :string, limit: 1000
    add_column :units, :rope_size_comment, :string, limit: 1000
    add_column :units, :slide_platform_height_comment, :string, limit: 1000
    add_column :units, :slide_wall_height_comment, :string, limit: 1000
    add_column :units, :runout_value_comment, :string, limit: 1000
    add_column :units, :slide_first_metre_height_comment, :string, limit: 1000
    add_column :units, :slide_beyond_first_metre_height_comment, :string, limit: 1000
    add_column :units, :slide_permanent_roof_comment, :string, limit: 1000
    add_column :units, :containing_wall_height_comment, :string, limit: 1000
    add_column :units, :platform_height_comment, :string, limit: 1000
    add_column :units, :permanent_roof_comment, :string, limit: 1000
    add_column :units, :play_area_length_comment, :string, limit: 1000
    add_column :units, :play_area_width_comment, :string, limit: 1000
    add_column :units, :negative_adjustment_comment, :string, limit: 1000
    add_column :units, :exit_number_comment, :string, limit: 1000

    # Add comment fields to inspections table
    add_column :inspections, :width_comment, :string, limit: 1000
    add_column :inspections, :length_comment, :string, limit: 1000
    add_column :inspections, :height_comment, :string, limit: 1000
    add_column :inspections, :num_low_anchors_comment, :string, limit: 1000
    add_column :inspections, :num_high_anchors_comment, :string, limit: 1000
    add_column :inspections, :rope_size_comment, :string, limit: 1000
    add_column :inspections, :slide_platform_height_comment, :string, limit: 1000
    add_column :inspections, :slide_wall_height_comment, :string, limit: 1000
    add_column :inspections, :runout_value_comment, :string, limit: 1000
    add_column :inspections, :slide_first_metre_height_comment, :string, limit: 1000
    add_column :inspections, :slide_beyond_first_metre_height_comment, :string, limit: 1000
    add_column :inspections, :slide_permanent_roof_comment, :string, limit: 1000
    add_column :inspections, :containing_wall_height_comment, :string, limit: 1000
    add_column :inspections, :platform_height_comment, :string, limit: 1000
    add_column :inspections, :permanent_roof_comment, :string, limit: 1000
    add_column :inspections, :play_area_length_comment, :string, limit: 1000
    add_column :inspections, :play_area_width_comment, :string, limit: 1000
    add_column :inspections, :negative_adjustment_comment, :string, limit: 1000
    add_column :inspections, :exit_number_comment, :string, limit: 1000

    # Add missing comment fields to structure_assessments
    add_column :structure_assessments, :trough_depth_comment, :string, limit: 1000
    add_column :structure_assessments, :trough_width_comment, :string, limit: 1000
    add_column :structure_assessments, :tubes_present_comment, :string, limit: 1000
    add_column :structure_assessments, :netting_comment, :string, limit: 1000
    add_column :structure_assessments, :ventilation_comment, :string, limit: 1000
    add_column :structure_assessments, :step_heights_comment, :string, limit: 1000
    add_column :structure_assessments, :opening_dimension_comment, :string, limit: 1000
    add_column :structure_assessments, :entrances_comment, :string, limit: 1000
    add_column :structure_assessments, :fabric_integrity_comment, :string, limit: 1000

    # Add missing comment fields to materials_assessments
    add_column :materials_assessments, :marking_comment, :string, limit: 1000
    add_column :materials_assessments, :instructions_comment, :string, limit: 1000
    add_column :materials_assessments, :inflated_stability_comment, :string, limit: 1000
    add_column :materials_assessments, :protrusions_comment, :string, limit: 1000
    add_column :materials_assessments, :critical_defects_comment, :string, limit: 1000
  end
end
