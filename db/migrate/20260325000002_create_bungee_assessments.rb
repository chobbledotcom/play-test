# typed: false

class CreateBungeeAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :bungee_assessments,
      id: false do |t|
      t.string :inspection_id, null: false, primary_key: true
      add_pass_fail_checks(t)
      add_measurement_fields(t)
      add_wall_dimension_fields(t)
      t.timestamps
    end

    add_foreign_key :bungee_assessments,
      :inspections,
      column: :inspection_id
  end

  private

  def add_pass_fail_checks(t)
    %i[
      blower_forward_distance
      marking_max_mass
      marking_min_height
      pull_strength
      cord_length_max
      cord_diametre_min
      two_stage_locking
      baton_compliant
      lane_width_max
      rear_wall
      side_wall
      running_wall
    ].each do |field|
      t.boolean :"#{field}_pass"
      t.string :"#{field}_comment", limit: 1000
    end
  end

  def add_measurement_fields(t)
    t.integer :harness_width
    t.boolean :harness_width_pass
    t.string :harness_width_comment, limit: 1000
    t.integer :num_of_cords
  end

  def add_wall_dimension_fields(t)
    %i[
      rear_wall_thickness
      rear_wall_height
      side_wall_length
      side_wall_height
      running_wall_width
      running_wall_height
    ].each do |field|
      t.decimal field, precision: 8, scale: 2
      t.string :"#{field}_comment", limit: 1000
    end
  end
end
