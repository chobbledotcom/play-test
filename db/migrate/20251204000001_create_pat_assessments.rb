# typed: false
# frozen_string_literal: true

class CreatePatAssessments < ActiveRecord::Migration[8.0]
  def change
    create_table :pat_assessments, id: false do |t|
      t.string :inspection_id, limit: 12, null: false
      add_equipment_fields(t)
      add_visual_fields(t)
      add_electrical_fields(t)
      add_functional_fields(t)
      t.timestamps
    end

    add_index :pat_assessments, :inspection_id,
      unique: true, name: "pat_assessments_pkey"
    add_foreign_key :pat_assessments, :inspections
  end

  private

  def add_equipment_fields(t)
    t.integer :equipment_class
    t.boolean :equipment_class_pass
    t.text :equipment_class_comment
    t.integer :equipment_power
    t.text :equipment_power_comment
  end

  def add_visual_fields(t)
    t.boolean :visual_pass
    t.text :visual_comment
    t.boolean :appliance_plug_check_pass
    t.text :appliance_plug_check_comment
  end

  def add_electrical_fields(t)
    t.integer :fuse_rating
    t.boolean :fuse_rating_pass
    t.text :fuse_rating_comment
    t.decimal :earth_ohms, precision: 8, scale: 2
    t.boolean :earth_ohms_pass
    t.text :earth_ohms_comment
    t.integer :insulation_mohms
    t.boolean :insulation_mohms_pass
    t.text :insulation_mohms_comment
    t.decimal :leakage_ma, precision: 8, scale: 2
    t.boolean :leakage_ma_pass
    t.text :leakage_ma_comment
  end

  def add_functional_fields(t)
    t.boolean :load_test_pass
    t.text :load_test_comment
    t.decimal :rcd_trip_time_ms, precision: 8, scale: 2
    t.boolean :rcd_trip_time_ms_pass
    t.text :rcd_trip_time_ms_comment
  end
end
