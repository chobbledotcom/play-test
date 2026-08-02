# typed: false
# frozen_string_literal: true

class CreatePlayZoneAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :play_zone_assessments, id: false do |t|
      t.string :inspection_id, limit: 12, null: false
      add_pass_fail_fields(t)
      add_measurement_fields(t)
      t.timestamps
    end

    add_index :play_zone_assessments, :inspection_id,
      unique: true, name: "play_zone_assessments_pkey"
    add_foreign_key :play_zone_assessments, :inspections
  end

  private

  def add_pass_fail_fields(t)
    t.boolean :age_marking_pass
    t.text :age_marking_comment
    t.boolean :height_marking_pass
    t.text :height_marking_comment
    t.boolean :sight_line_pass
    t.text :sight_line_comment
    t.boolean :access_pass
    t.text :access_comment
    t.boolean :suitable_matting_pass
    t.text :suitable_matting_comment
    t.boolean :traffic_flow_pass
    t.text :traffic_flow_comment
    t.boolean :air_juggler_pass
    t.text :air_juggler_comment
    t.boolean :balls_pass
    t.text :balls_comment
    t.boolean :ball_pool_gaps_pass
    t.text :ball_pool_gaps_comment
    t.boolean :fitted_sheet_pass
    t.text :fitted_sheet_comment
  end

  def add_measurement_fields(t)
    t.integer :ball_pool_depth
    t.boolean :ball_pool_depth_pass
    t.text :ball_pool_depth_comment
    t.integer :ball_pool_entry_height
    t.boolean :ball_pool_entry_height_pass
    t.text :ball_pool_entry_height_comment
    t.integer :slide_gradient
    t.boolean :slide_gradient_pass
    t.text :slide_gradient_comment
    t.decimal :slide_platform_height, precision: 8, scale: 2
    t.boolean :slide_platform_height_pass
    t.text :slide_platform_height_comment
  end
end
