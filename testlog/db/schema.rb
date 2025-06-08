# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_06_09_121001) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "record_id"
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "anchorage_assessments", force: :cascade do |t|
    t.string "inspection_id", limit: 12, null: false
    t.integer "num_low_anchors"
    t.integer "num_high_anchors"
    t.boolean "num_anchors_pass"
    t.boolean "anchor_accessories_pass"
    t.boolean "anchor_degree_pass"
    t.boolean "anchor_type_pass"
    t.boolean "pull_strength_pass"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "num_anchors_comment"
    t.text "anchor_accessories_comment"
    t.text "anchor_degree_comment"
    t.text "anchor_type_comment"
    t.text "pull_strength_comment"
    t.index ["inspection_id"], name: "index_anchorage_assessments_on_inspection_id"
  end

  create_table "enclosed_assessments", force: :cascade do |t|
    t.string "inspection_id", limit: 12, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "exit_number"
    t.boolean "exit_number_pass"
    t.text "exit_number_comment"
    t.boolean "exit_visible_pass"
    t.text "exit_visible_comment"
    t.index ["inspection_id"], name: "index_enclosed_assessments_on_inspection_id"
  end

  create_table "fan_assessments", force: :cascade do |t|
    t.string "inspection_id", limit: 12, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "fan_size_comment"
    t.boolean "blower_flap_pass"
    t.text "blower_flap_comment"
    t.boolean "blower_finger_pass"
    t.text "blower_finger_comment"
    t.boolean "pat_pass"
    t.text "pat_comment"
    t.boolean "blower_visual_pass"
    t.text "blower_visual_comment"
    t.string "blower_serial"
    t.index ["inspection_id"], name: "index_fan_assessments_on_inspection_id"
  end

  create_table "inspections", id: { type: :string, limit: 12 }, force: :cascade do |t|
    t.datetime "inspection_date"
    t.boolean "passed"
    t.text "comments"
    t.string "user_id", limit: 12, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "pdf_last_accessed_at"
    t.string "unit_id"
    t.string "inspection_location"
    t.string "unique_report_number"
    t.string "status", default: "draft"
    t.datetime "finalized_at"
    t.string "finalized_by_id", limit: 12
    t.text "general_notes"
    t.text "recommendations"
    t.string "inspector_signature"
    t.datetime "signature_timestamp"
    t.string "inspector_company_id"
    t.decimal "width", precision: 8, scale: 2
    t.decimal "length", precision: 8, scale: 2
    t.decimal "height", precision: 8, scale: 2
    t.integer "num_low_anchors"
    t.integer "num_high_anchors"
    t.integer "exit_number"
    t.decimal "rope_size", precision: 8, scale: 2
    t.decimal "slide_platform_height", precision: 8, scale: 2
    t.decimal "slide_wall_height", precision: 8, scale: 2
    t.decimal "runout_value", precision: 8, scale: 2
    t.decimal "slide_first_metre_height", precision: 8, scale: 2
    t.decimal "slide_beyond_first_metre_height", precision: 8, scale: 2
    t.decimal "stitch_length", precision: 8, scale: 2
    t.decimal "evacuation_time", precision: 8, scale: 2
    t.decimal "unit_pressure_value", precision: 8, scale: 2
    t.decimal "blower_tube_length", precision: 8, scale: 2
    t.decimal "step_size_value", precision: 8, scale: 2
    t.decimal "fall_off_height_value", precision: 8, scale: 2
    t.decimal "trough_depth_value", precision: 8, scale: 2
    t.decimal "trough_width_value", precision: 8, scale: 2
    t.decimal "containing_wall_height", precision: 8, scale: 2
    t.decimal "platform_height", precision: 8, scale: 2
    t.decimal "user_height", precision: 8, scale: 2
    t.integer "users_at_1000mm"
    t.integer "users_at_1200mm"
    t.integer "users_at_1500mm"
    t.integer "users_at_1800mm"
    t.decimal "play_area_length", precision: 8, scale: 2
    t.decimal "play_area_width", precision: 8, scale: 2
    t.decimal "negative_adjustment", precision: 8, scale: 2
    t.boolean "slide_permanent_roof"
    t.boolean "permanent_roof"
    t.boolean "has_slide", default: false, null: false
    t.boolean "is_totally_enclosed", default: false, null: false
    t.string "width_comment", limit: 1000
    t.string "length_comment", limit: 1000
    t.string "height_comment", limit: 1000
    t.string "num_low_anchors_comment", limit: 1000
    t.string "num_high_anchors_comment", limit: 1000
    t.string "rope_size_comment", limit: 1000
    t.string "slide_platform_height_comment", limit: 1000
    t.string "slide_wall_height_comment", limit: 1000
    t.string "runout_value_comment", limit: 1000
    t.string "slide_first_metre_height_comment", limit: 1000
    t.string "slide_beyond_first_metre_height_comment", limit: 1000
    t.string "slide_permanent_roof_comment", limit: 1000
    t.string "containing_wall_height_comment", limit: 1000
    t.string "platform_height_comment", limit: 1000
    t.string "permanent_roof_comment", limit: 1000
    t.string "play_area_length_comment", limit: 1000
    t.string "play_area_width_comment", limit: 1000
    t.string "negative_adjustment_comment", limit: 1000
    t.string "exit_number_comment", limit: 1000
    t.index ["finalized_by_id"], name: "index_inspections_on_finalized_by_id"
    t.index ["inspector_company_id"], name: "index_inspections_on_inspector_company_id"
    t.index ["status"], name: "index_inspections_on_status"
    t.index ["unit_id"], name: "index_inspections_on_unit_id"
    t.index ["user_id", "unique_report_number"], name: "index_inspections_on_user_and_report_number", unique: true
    t.index ["user_id"], name: "index_inspections_on_user_id"
  end

  create_table "inspector_companies", id: { type: :string, limit: 12 }, force: :cascade do |t|
    t.string "name", null: false
    t.string "rpii_registration_number", null: false
    t.string "email"
    t.string "phone", null: false
    t.text "address", null: false
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "country", default: "UK"
    t.boolean "active", default: true
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_inspector_companies_on_active"
    t.index ["rpii_registration_number"], name: "index_inspector_companies_on_rpii_registration_number", unique: true
  end

  create_table "materials_assessments", force: :cascade do |t|
    t.string "inspection_id", limit: 12, null: false
    t.decimal "rope_size", precision: 8, scale: 2
    t.boolean "rope_size_pass"
    t.boolean "clamber_pass"
    t.boolean "retention_netting_pass"
    t.boolean "zips_pass"
    t.boolean "windows_pass"
    t.boolean "artwork_pass"
    t.boolean "thread_pass"
    t.boolean "fabric_pass"
    t.boolean "fire_retardant_pass"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "rope_size_comment"
    t.text "clamber_comment"
    t.text "retention_netting_comment"
    t.text "zips_comment"
    t.text "windows_comment"
    t.text "artwork_comment"
    t.text "thread_comment"
    t.text "fabric_comment"
    t.text "fire_retardant_comment"
    t.string "marking_comment", limit: 1000
    t.string "instructions_comment", limit: 1000
    t.string "inflated_stability_comment", limit: 1000
    t.string "protrusions_comment", limit: 1000
    t.string "critical_defects_comment", limit: 1000
    t.index ["inspection_id"], name: "index_materials_assessments_on_inspection_id"
  end

  create_table "slide_assessments", force: :cascade do |t|
    t.string "inspection_id", limit: 12, null: false
    t.decimal "slide_platform_height", precision: 8, scale: 2
    t.decimal "slide_wall_height", precision: 8, scale: 2
    t.decimal "runout_value", precision: 8, scale: 2
    t.decimal "slide_first_metre_height", precision: 8, scale: 2
    t.decimal "slide_beyond_first_metre_height", precision: 8, scale: 2
    t.boolean "clamber_netting_pass"
    t.boolean "runout_pass"
    t.boolean "slip_sheet_pass"
    t.boolean "slide_permanent_roof"
    t.text "slide_platform_height_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "slide_wall_height_comment"
    t.text "slide_first_metre_height_comment"
    t.text "slide_beyond_first_metre_height_comment"
    t.text "slide_permanent_roof_comment"
    t.text "clamber_netting_comment"
    t.text "runout_comment"
    t.text "slip_sheet_comment"
    t.index ["inspection_id"], name: "index_slide_assessments_on_inspection_id"
  end

  create_table "structure_assessments", force: :cascade do |t|
    t.string "inspection_id", limit: 12, null: false
    t.boolean "seam_integrity_pass"
    t.boolean "lock_stitch_pass"
    t.boolean "air_loss_pass"
    t.boolean "straight_walls_pass"
    t.boolean "sharp_edges_pass"
    t.boolean "unit_stable_pass"
    t.decimal "stitch_length", precision: 8, scale: 2
    t.decimal "evacuation_time", precision: 8, scale: 2
    t.decimal "unit_pressure_value", precision: 8, scale: 2
    t.decimal "blower_tube_length", precision: 8, scale: 2
    t.decimal "step_size_value", precision: 8, scale: 2
    t.decimal "fall_off_height_value", precision: 8, scale: 2
    t.decimal "trough_depth_value", precision: 8, scale: 2
    t.decimal "trough_width_value", precision: 8, scale: 2
    t.boolean "stitch_length_pass"
    t.boolean "blower_tube_length_pass"
    t.boolean "evacuation_time_pass"
    t.boolean "step_size_pass"
    t.boolean "fall_off_height_pass"
    t.boolean "unit_pressure_pass"
    t.boolean "trough_pass"
    t.boolean "entrapment_pass"
    t.boolean "markings_pass"
    t.boolean "grounding_pass"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "seam_integrity_comment"
    t.text "lock_stitch_comment"
    t.text "stitch_length_comment"
    t.text "air_loss_comment"
    t.text "straight_walls_comment"
    t.text "sharp_edges_comment"
    t.text "blower_tube_length_comment"
    t.text "unit_stable_comment"
    t.text "evacuation_time_comment"
    t.text "step_size_comment"
    t.text "fall_off_height_comment"
    t.text "unit_pressure_comment"
    t.text "trough_comment"
    t.text "entrapment_comment"
    t.text "markings_comment"
    t.text "grounding_comment"
    t.string "trough_depth_comment", limit: 1000
    t.string "trough_width_comment", limit: 1000
    t.string "tubes_present_comment", limit: 1000
    t.string "netting_comment", limit: 1000
    t.string "ventilation_comment", limit: 1000
    t.string "step_heights_comment", limit: 1000
    t.string "opening_dimension_comment", limit: 1000
    t.string "entrances_comment", limit: 1000
    t.string "fabric_integrity_comment", limit: 1000
    t.index ["inspection_id"], name: "index_structure_assessments_on_inspection_id"
  end

  create_table "units", id: { type: :string, limit: 12 }, force: :cascade do |t|
    t.string "name"
    t.string "serial"
    t.string "user_id", limit: 12, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "manufacturer"
    t.string "description"
    t.string "owner"
    t.string "serial_number"
    t.decimal "width", precision: 8, scale: 2
    t.decimal "length", precision: 8, scale: 2
    t.decimal "height", precision: 8, scale: 2
    t.text "notes"
    t.string "model"
    t.date "manufacture_date"
    t.string "condition"
    t.integer "num_low_anchors"
    t.integer "num_high_anchors"
    t.integer "exit_number"
    t.decimal "rope_size", precision: 8, scale: 2
    t.decimal "slide_platform_height", precision: 8, scale: 2
    t.decimal "slide_wall_height", precision: 8, scale: 2
    t.decimal "runout_value", precision: 8, scale: 2
    t.decimal "slide_first_metre_height", precision: 8, scale: 2
    t.decimal "slide_beyond_first_metre_height", precision: 8, scale: 2
    t.decimal "stitch_length", precision: 8, scale: 2
    t.decimal "evacuation_time", precision: 8, scale: 2
    t.decimal "unit_pressure_value", precision: 8, scale: 2
    t.decimal "blower_tube_length", precision: 8, scale: 2
    t.decimal "step_size_value", precision: 8, scale: 2
    t.decimal "fall_off_height_value", precision: 8, scale: 2
    t.decimal "trough_depth_value", precision: 8, scale: 2
    t.decimal "trough_width_value", precision: 8, scale: 2
    t.decimal "containing_wall_height", precision: 8, scale: 2
    t.decimal "platform_height", precision: 8, scale: 2
    t.decimal "user_height", precision: 8, scale: 2
    t.integer "users_at_1000mm"
    t.integer "users_at_1200mm"
    t.integer "users_at_1500mm"
    t.integer "users_at_1800mm"
    t.decimal "play_area_length", precision: 8, scale: 2
    t.decimal "play_area_width", precision: 8, scale: 2
    t.decimal "negative_adjustment", precision: 8, scale: 2
    t.boolean "slide_permanent_roof"
    t.boolean "permanent_roof"
    t.decimal "ambient_temperature", precision: 5, scale: 2
    t.boolean "is_totally_enclosed", default: false
    t.boolean "has_slide", default: false, null: false
    t.string "width_comment", limit: 1000
    t.string "length_comment", limit: 1000
    t.string "height_comment", limit: 1000
    t.string "num_low_anchors_comment", limit: 1000
    t.string "num_high_anchors_comment", limit: 1000
    t.string "rope_size_comment", limit: 1000
    t.string "slide_platform_height_comment", limit: 1000
    t.string "slide_wall_height_comment", limit: 1000
    t.string "runout_value_comment", limit: 1000
    t.string "slide_first_metre_height_comment", limit: 1000
    t.string "slide_beyond_first_metre_height_comment", limit: 1000
    t.string "slide_permanent_roof_comment", limit: 1000
    t.string "containing_wall_height_comment", limit: 1000
    t.string "platform_height_comment", limit: 1000
    t.string "permanent_roof_comment", limit: 1000
    t.string "play_area_length_comment", limit: 1000
    t.string "play_area_width_comment", limit: 1000
    t.string "negative_adjustment_comment", limit: 1000
    t.string "exit_number_comment", limit: 1000
    t.index ["manufacturer", "serial_number"], name: "index_units_on_manufacturer_and_serial_number", unique: true
    t.index ["serial"], name: "index_units_on_serial"
    t.index ["user_id"], name: "index_units_on_user_id"
  end

  create_table "user_height_assessments", force: :cascade do |t|
    t.string "inspection_id", limit: 12, null: false
    t.decimal "containing_wall_height", precision: 8, scale: 2
    t.decimal "platform_height", precision: 8, scale: 2
    t.decimal "user_height", precision: 8, scale: 2
    t.integer "users_at_1000mm"
    t.integer "users_at_1200mm"
    t.integer "users_at_1500mm"
    t.integer "users_at_1800mm"
    t.decimal "play_area_length", precision: 8, scale: 2
    t.decimal "play_area_width", precision: 8, scale: 2
    t.decimal "negative_adjustment", precision: 8, scale: 2
    t.boolean "permanent_roof"
    t.text "user_height_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "containing_wall_height_comment"
    t.text "platform_height_comment"
    t.text "play_area_length_comment"
    t.text "play_area_width_comment"
    t.text "negative_adjustment_comment"
    t.text "permanent_roof_comment"
    t.index ["inspection_id"], name: "index_user_height_assessments_on_inspection_id"
  end

  create_table "users", id: { type: :string, limit: 12 }, force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "inspection_limit", default: 10, null: false
    t.datetime "last_active_at"
    t.string "time_display", default: "date"
    t.string "inspection_company_id"
    t.index ["email"], name: "index_users_on_email"
    t.index ["inspection_company_id"], name: "index_users_on_inspection_company_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "anchorage_assessments", "inspections"
  add_foreign_key "enclosed_assessments", "inspections"
  add_foreign_key "fan_assessments", "inspections"
  add_foreign_key "inspections", "inspector_companies"
  add_foreign_key "inspections", "units"
  add_foreign_key "inspections", "users"
  add_foreign_key "inspections", "users", column: "finalized_by_id"
  add_foreign_key "materials_assessments", "inspections"
  add_foreign_key "slide_assessments", "inspections"
  add_foreign_key "structure_assessments", "inspections"
  add_foreign_key "units", "users"
  add_foreign_key "user_height_assessments", "inspections"
end
