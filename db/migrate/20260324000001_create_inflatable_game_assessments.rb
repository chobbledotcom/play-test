# typed: false
# frozen_string_literal: true

class CreateInflatableGameAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :inflatable_game_assessments, id: false do |t|
      t.string :inspection_id, limit: 12, null: false
      add_pass_fail_fields(t)
      add_measurement_fields(t)
      t.timestamps
    end

    add_index :inflatable_game_assessments, :inspection_id,
      unique: true, name: "inflatable_game_assessments_pkey"
    add_foreign_key :inflatable_game_assessments, :inspections
  end

  private

  def add_pass_fail_fields(t)
    t.text :game_type
    t.boolean :max_user_mass_pass
    t.text :max_user_mass_comment
    t.boolean :age_range_marking_pass
    t.text :age_range_marking_comment
    t.boolean :constant_air_flow_pass
    t.text :constant_air_flow_comment
    t.boolean :design_risk_pass
    t.text :design_risk_comment
    t.boolean :intended_play_risk_pass
    t.text :intended_play_risk_comment
    t.boolean :ancillary_equipment_pass
    t.text :ancillary_equipment_comment
    t.boolean :ancillary_equipment_compliant_pass
    t.text :ancillary_equipment_compliant_comment
  end

  def add_measurement_fields(t)
    t.decimal :containing_wall_height, precision: 8, scale: 2
    t.boolean :containing_wall_height_pass
    t.text :containing_wall_height_comment
  end
end
