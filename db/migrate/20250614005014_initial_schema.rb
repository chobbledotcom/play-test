class InitialSchema < ActiveRecord::Migration[8.0]
  def change
    # Active Storage Tables
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

    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table "active_storage_variant_records", force: :cascade do |t|
      t.bigint "blob_id", null: false
      t.string "variation_digest", null: false
      t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
    end
    # rubocop:enable Rails/CreateTableWithTimestamps

    # Users
    create_table "users", id: {type: :string, limit: 8}, force: :cascade do |t|
      t.string "email"
      t.string "password_digest"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.datetime "last_active_at"
      t.string "inspection_company_id"
      t.string "default_inspection_location"
      t.string "theme", default: "light"
      t.string "rpii_inspector_number"
      t.date "active_until"
      t.string "name"
      t.string "phone"
      t.text "address"
      t.string "country"
      t.string "postal_code"
      t.datetime "rpii_verified_date"
      t.index ["email"], name: "index_users_on_email"
      t.index ["inspection_company_id"], name: "index_users_on_inspection_company_id"
    end

    # Inspector Companies
    create_table "inspector_companies", id: {type: :string, limit: 8}, force: :cascade do |t|
      t.boolean "active", default: true
      t.string "name", null: false
      t.string "email"
      t.string "phone", null: false
      t.text "address", null: false
      t.string "city"
      t.string "postal_code"
      t.string "country", default: "UK"
      t.text "notes"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["active"], name: "index_inspector_companies_on_active"
    end

    # Units
    create_table "units", id: {type: :string, limit: 8}, force: :cascade do |t|
      t.string "name"
      t.string "user_id", limit: 8, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "is_seed", default: false, null: false
      t.string "manufacturer"
      t.string "description"
      t.string "owner"
      t.text "notes"
      t.string "model"
      t.date "manufacture_date"
      t.string "serial"
      t.index ["is_seed"], name: "index_units_on_is_seed"
      t.index ["manufacturer", "serial"], name: "index_units_on_manufacturer_and_serial", unique: true
      t.index ["user_id"], name: "index_units_on_user_id"
    end

    # Inspections
    create_table "inspections", id: {type: :string, limit: 8}, force: :cascade do |t|
      t.datetime "inspection_date"
      t.boolean "passed"
      t.string "unit_id", limit: 8
      t.string "user_id", limit: 8, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "is_seed", default: false, null: false
      t.datetime "pdf_last_accessed_at"
      t.string "inspection_location"
      t.string "unique_report_number"
      t.string "inspector_company_id", limit: 8
      t.decimal "width", precision: 8, scale: 2
      t.decimal "length", precision: 8, scale: 2
      t.decimal "height", precision: 8, scale: 2
      t.boolean "has_slide", default: false, null: false
      t.boolean "is_totally_enclosed", default: false, null: false
      t.string "width_comment", limit: 1000
      t.string "length_comment", limit: 1000
      t.string "height_comment", limit: 1000
      t.text "risk_assessment"
      t.datetime "complete_date"
      t.index ["inspector_company_id"], name: "index_inspections_on_inspector_company_id"
      t.index ["is_seed"], name: "index_inspections_on_is_seed"
      t.index ["unit_id"], name: "index_inspections_on_unit_id"
      t.index ["user_id", "unique_report_number"], name: "index_inspections_on_user_and_report_number", unique: true
      t.index ["user_id"], name: "index_inspections_on_user_id"
    end

    # Assessment Tables
    create_table "anchorage_assessments", id: false, force: :cascade do |t|
      t.string "inspection_id", limit: 12, null: false
      t.integer "num_low_anchors"
      t.integer "num_high_anchors"
      t.boolean "anchor_accessories_pass"
      t.boolean "anchor_degree_pass"
      t.boolean "anchor_type_pass"
      t.boolean "pull_strength_pass"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "anchor_accessories_comment"
      t.text "anchor_degree_comment"
      t.text "anchor_type_comment"
      t.text "pull_strength_comment"
      t.text "num_low_anchors_comment"
      t.text "num_high_anchors_comment"
      t.boolean "num_low_anchors_pass"
      t.boolean "num_high_anchors_pass"
      t.index ["inspection_id"], name: "anchorage_assessments_new_pkey", unique: true
    end

    create_table "enclosed_assessments", id: false, force: :cascade do |t|
      t.string "inspection_id", limit: 12, null: false
      t.integer "exit_number"
      t.boolean "exit_number_pass"
      t.text "exit_number_comment"
      t.boolean "exit_sign_always_visible_pass"
      t.text "exit_sign_always_visible_comment"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["inspection_id"], name: "enclosed_assessments_new_pkey", unique: true
    end

    create_table "fan_assessments", id: false, force: :cascade do |t|
      t.string "inspection_id", limit: 12, null: false
      t.text "fan_size_type"
      t.integer "blower_flap_pass", limit: 1
      t.text "blower_flap_comment"
      t.boolean "blower_finger_pass"
      t.text "blower_finger_comment"
      t.boolean "pat_pass"
      t.text "pat_comment"
      t.boolean "blower_visual_pass"
      t.text "blower_visual_comment"
      t.string "blower_serial"
      t.boolean "blower_serial_pass"
      t.text "blower_serial_comment"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["inspection_id"], name: "fan_assessments_new_pkey", unique: true
    end

    create_table "materials_assessments", id: false, force: :cascade do |t|
      t.string "inspection_id", limit: 12, null: false
      t.integer "ropes"
      t.integer "ropes_pass", limit: 1
      t.integer "retention_netting_pass", limit: 1
      t.integer "zips_pass", limit: 1
      t.integer "windows_pass", limit: 1
      t.integer "artwork_pass", limit: 1
      t.boolean "thread_pass"
      t.boolean "fabric_strength_pass"
      t.boolean "fire_retardant_pass"
      t.text "ropes_comment"
      t.text "retention_netting_comment"
      t.text "zips_comment"
      t.text "windows_comment"
      t.text "artwork_comment"
      t.text "thread_comment"
      t.text "fabric_strength_comment"
      t.text "fire_retardant_comment"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["inspection_id"], name: "materials_assessments_new_pkey", unique: true
    end

    create_table "slide_assessments", id: false, force: :cascade do |t|
      t.string "inspection_id", limit: 12, null: false
      t.decimal "slide_platform_height", precision: 8, scale: 2
      t.decimal "slide_wall_height", precision: 8, scale: 2
      t.decimal "runout", precision: 8, scale: 2
      t.decimal "slide_first_metre_height", precision: 8, scale: 2
      t.decimal "slide_beyond_first_metre_height", precision: 8, scale: 2
      t.integer "clamber_netting_pass", limit: 1
      t.boolean "runout_pass"
      t.boolean "slip_sheet_pass"
      t.boolean "slide_permanent_roof"
      t.text "slide_platform_height_comment"
      t.text "slide_wall_height_comment"
      t.text "slide_first_metre_height_comment"
      t.text "slide_beyond_first_metre_height_comment"
      t.text "slide_permanent_roof_comment"
      t.text "clamber_netting_comment"
      t.text "runout_comment"
      t.text "slip_sheet_comment"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["inspection_id"], name: "slide_assessments_new_pkey", unique: true
    end

    create_table "structure_assessments", id: false, force: :cascade do |t|
      t.string "inspection_id", limit: 12, null: false
      t.boolean "seam_integrity_pass"
      t.boolean "air_loss_pass"
      t.boolean "straight_walls_pass"
      t.boolean "sharp_edges_pass"
      t.boolean "unit_stable_pass"
      t.decimal "unit_pressure", precision: 8, scale: 2
      t.integer "critical_fall_off_height"
      t.integer "trough_depth"
      t.boolean "stitch_length_pass"
      t.boolean "evacuation_time_pass"
      t.boolean "critical_fall_off_height_pass"
      t.boolean "unit_pressure_pass"
      t.boolean "trough_pass"
      t.boolean "entrapment_pass"
      t.boolean "markings_pass"
      t.boolean "grounding_pass"
      t.text "seam_integrity_comment"
      t.text "stitch_length_comment"
      t.text "air_loss_comment"
      t.text "straight_walls_comment"
      t.text "sharp_edges_comment"
      t.text "unit_stable_comment"
      t.text "evacuation_time_comment"
      t.text "critical_fall_off_height_comment"
      t.text "unit_pressure_comment"
      t.text "trough_comment"
      t.text "entrapment_comment"
      t.text "markings_comment"
      t.text "grounding_comment"
      t.string "trough_depth_comment", limit: 1000
      t.integer "trough_adjacent_panel_width"
      t.text "trough_adjacent_panel_width_comment"
      t.integer "step_ramp_size"
      t.boolean "step_ramp_size_pass"
      t.text "step_ramp_size_comment"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "platform_height"
      t.boolean "platform_height_pass"
      t.text "platform_height_comment"
      t.index ["inspection_id"], name: "structure_assessments_new_pkey", unique: true
    end

    create_table "user_height_assessments", id: false, force: :cascade do |t|
      t.string "inspection_id", limit: 12, null: false
      t.decimal "containing_wall_height", precision: 8, scale: 2
      t.text "containing_wall_height_comment"
      t.decimal "play_area_length", precision: 8, scale: 2
      t.text "play_area_length_comment"
      t.decimal "play_area_width", precision: 8, scale: 2
      t.text "play_area_width_comment"
      t.decimal "negative_adjustment", precision: 8, scale: 2
      t.text "negative_adjustment_comment"
      t.integer "users_at_1000mm"
      t.integer "users_at_1200mm"
      t.integer "users_at_1500mm"
      t.integer "users_at_1800mm"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "custom_user_height_comment"
      t.index ["inspection_id"], name: "user_height_assessments_new_pkey", unique: true
    end

    # Foreign Keys
    add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
    add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
    add_foreign_key "anchorage_assessments", "inspections"
    add_foreign_key "enclosed_assessments", "inspections"
    add_foreign_key "fan_assessments", "inspections"
    add_foreign_key "inspections", "inspector_companies"
    add_foreign_key "inspections", "units"
    add_foreign_key "inspections", "users"
    add_foreign_key "materials_assessments", "inspections"
    add_foreign_key "slide_assessments", "inspections"
    add_foreign_key "structure_assessments", "inspections"
    add_foreign_key "units", "users"
    add_foreign_key "user_height_assessments", "inspections"
  end
end
