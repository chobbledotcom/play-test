# typed: false
# frozen_string_literal: true

class CreateCatchBedAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :catch_bed_assessments, id: false do |t|
      t.string :inspection_id, limit: 12, null: false
      add_pass_fail_fields(t)
      add_measurement_fields(t)
      t.timestamps
    end

    add_index :catch_bed_assessments, :inspection_id,
      unique: true, name: "catch_bed_assessments_pkey"
    add_foreign_key :catch_bed_assessments, :inspections
  end

  private

  def add_pass_fail_fields(t)
    t.text :type_of_unit
    t.boolean :max_user_mass_marking_pass
    t.text :max_user_mass_marking_comment
    t.boolean :arrest_pass
    t.text :arrest_comment
    t.boolean :matting_pass
    t.text :matting_comment
    t.boolean :design_risk_pass
    t.text :design_risk_comment
    t.boolean :intended_play_pass
    t.text :intended_play_comment
    t.boolean :ancillary_fit_pass
    t.text :ancillary_fit_comment
    t.boolean :ancillary_compliant_pass
    t.text :ancillary_compliant_comment
    t.boolean :apron_pass
    t.text :apron_comment
    t.boolean :trough_pass
    t.text :trough_comment
    t.boolean :framework_pass
    t.text :framework_comment
    t.boolean :grounding_pass
    t.text :grounding_comment
  end

  def add_measurement_fields(t)
    t.integer :bed_height
    t.boolean :bed_height_pass
    t.text :bed_height_comment
    t.decimal :platform_fall_distance, precision: 8, scale: 2
    t.boolean :platform_fall_distance_pass
    t.text :platform_fall_distance_comment
    t.decimal :blower_tube_length, precision: 8, scale: 2
    t.boolean :blower_tube_length_pass
    t.text :blower_tube_length_comment
  end
end
