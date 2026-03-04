# typed: false
# frozen_string_literal: true

class CreateBallPoolAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :ball_pool_assessments, id: false do |t|
      t.string :inspection_id, limit: 12, null: false
      add_pass_fail_fields(t)
      add_measurement_fields(t)
      t.timestamps
    end

    add_index :ball_pool_assessments, :inspection_id,
      unique: true, name: "ball_pool_assessments_pkey"
    add_foreign_key :ball_pool_assessments, :inspections
  end

  private

  def add_pass_fail_fields(t)
    t.boolean :age_range_marking_pass
    t.text :age_range_marking_comment
    t.boolean :max_height_markings_pass
    t.text :max_height_markings_comment
    t.boolean :suitable_matting_pass
    t.text :suitable_matting_comment
    t.boolean :air_jugglers_compliant_pass
    t.text :air_jugglers_compliant_comment
    t.boolean :balls_compliant_pass
    t.text :balls_compliant_comment
    t.boolean :gaps_pass
    t.text :gaps_comment
    t.boolean :fitted_base_pass
    t.text :fitted_base_comment
  end

  def add_measurement_fields(t)
    t.integer :ball_pool_depth
    t.boolean :ball_pool_depth_pass
    t.text :ball_pool_depth_comment
    t.integer :ball_pool_entry
    t.boolean :ball_pool_entry_pass
    t.text :ball_pool_entry_comment
  end
end
