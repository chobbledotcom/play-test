# typed: strict
# frozen_string_literal: true

class ConvertAssessmentOutcomesToEnums < ActiveRecord::Migration[8.1]
  extend T::Sig

  BOOLEAN_OUTCOMES = {
    anchorage_assessments: %i[
      anchor_accessories_pass
      anchor_degree_pass
      anchor_type_pass
      num_high_anchors_pass
      num_low_anchors_pass
      pull_strength_pass
    ],
    ball_pool_assessments: %i[
      age_range_marking_pass
      air_jugglers_compliant_pass
      ball_pool_depth_pass
      ball_pool_entry_pass
      balls_compliant_pass
      fitted_base_pass
      gaps_pass
      max_height_markings_pass
      suitable_matting_pass
    ],
    bungee_assessments: %i[
      baton_compliant_pass
      blower_forward_distance_pass
      cord_diametre_min_pass
      cord_length_max_pass
      harness_width_pass
      lane_width_max_pass
      marking_max_mass_pass
      marking_min_height_pass
      pull_strength_pass
      rear_wall_pass
      running_wall_pass
      side_wall_pass
      two_stage_locking_pass
    ],
    catch_bed_assessments: %i[
      ancillary_compliant_pass
      ancillary_fit_pass
      apron_pass
      arrest_pass
      bed_height_pass
      blower_tube_length_pass
      design_risk_pass
      framework_pass
      grounding_pass
      intended_play_pass
      matting_pass
      max_user_mass_marking_pass
      platform_fall_distance_pass
      trough_pass
    ],
    enclosed_assessments: %i[
      exit_number_pass
      exit_sign_always_visible_pass
    ],
    fan_assessments: %i[
      blower_finger_pass
      blower_tube_length_pass
      blower_visual_pass
    ],
    inflatable_game_assessments: %i[
      age_range_marking_pass
      ancillary_equipment_compliant_pass
      ancillary_equipment_pass
      constant_air_flow_pass
      containing_wall_height_pass
      design_risk_pass
      intended_play_risk_pass
      max_user_mass_pass
    ],
    materials_assessments: %i[
      fabric_strength_pass
      fire_retardant_pass
      thread_pass
    ],
    pat_assessments: %i[
      appliance_plug_check_pass
      earth_ohms_pass
      equipment_class_pass
      fuse_rating_pass
      insulation_mohms_pass
      leakage_ma_pass
      load_test_pass
      rcd_trip_time_ms_pass
      visual_pass
    ],
    play_zone_assessments: %i[
      access_pass
      age_marking_pass
      air_juggler_pass
      ball_pool_depth_pass
      ball_pool_entry_height_pass
      ball_pool_gaps_pass
      balls_pass
      fitted_sheet_pass
      height_marking_pass
      sight_line_pass
      slide_gradient_pass
      slide_platform_height_pass
      suitable_matting_pass
      traffic_flow_pass
    ],
    slide_assessments: %i[
      runout_pass
      slip_sheet_pass
    ],
    structure_assessments: %i[
      air_loss_pass
      entrapment_pass
      evacuation_time_pass
      markings_pass
      seam_integrity_pass
      sharp_edges_pass
      stitch_length_pass
      straight_walls_pass
      unit_pressure_pass
      unit_stable_pass
    ]
  }.freeze

  sig { void }
  def up
    BOOLEAN_OUTCOMES.each do |table, fields|
      fields.each { |field| convert_outcome(table, field) }
    end
  end

  sig { void }
  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  sig { params(table: Symbol, field: Symbol).void }
  def convert_outcome(table, field)
    temporary = :"#{field}_enum"
    add_column table, temporary, :integer
    table_sql = quote_table_name(table)
    field_sql = quote_column_name(field)
    temporary_sql = quote_column_name(temporary)
    execute <<~SQL
      UPDATE #{table_sql}
      SET #{temporary_sql} = CASE
        WHEN #{field_sql} IS NULL THEN NULL
        WHEN #{field_sql} THEN 1
        ELSE 0
      END
    SQL
    remove_column table, field
    rename_column table, temporary, field
  end
end
