# typed: false
# frozen_string_literal: true

require "rails_helper"

STRUCTURE_SAMPLE_DATA = {

  seam_integrity_pass: true,
  air_loss_pass: true,
  straight_walls_pass: true,
  sharp_edges_pass: false,
  unit_stable_pass: true,

  unit_pressure: 2.8,
  critical_fall_off_height: 850,
  trough_depth: 150,
  trough_adjacent_panel_width: 650,
  step_ramp_size: 300,
  platform_height: 1800,

  stitch_length_pass: true,
  stitch_length_comment: "Stitch length comment",
  evacuation_time_pass: false,
  unit_pressure_pass: true,
  critical_fall_off_height_pass: true,
  trough_pass: true,
  step_ramp_size_pass: true,
  platform_height_pass: true,
  entrapment_pass: false,
  markings_pass: true,
  grounding_pass: true,

  unit_pressure_comment: "Unit pressure comment",
  critical_fall_off_height_comment: "Critical fall off height comment",
  step_ramp_size_comment: "Step ramp size comment",
  platform_height_comment: "Platform height verified",
  trough_depth_comment: "Trough depth comment",
  trough_adjacent_panel_width_comment: "Trough adjacent panel width comment",
  trough_comment: "Trough comment"
}.freeze

MATERIALS_SAMPLE_DATA = {

  ropes: 12,

  fabric_strength_pass: true,
  fire_retardant_pass: false,
  thread_pass: true,
  ropes_pass: "pass",
  retention_netting_pass: "fail",
  zips_pass: "pass",
  windows_pass: "pass",
  artwork_pass: "fail",

  ropes_comment: "Rope diameter within spec",
  fire_retardant_comment: "Requires flame retardant treatment",
  thread_comment: "Thread meets temperature requirements",
  retention_netting_comment: "Netting shows signs of wear",
  artwork_comment: "Artwork adhesive failing"
}.freeze

ANCHORAGE_SAMPLE_DATA = {

  num_low_anchors: 6,
  num_high_anchors: 4,

  num_low_anchors_pass: true,
  num_high_anchors_pass: true,
  anchor_accessories_pass: false,
  anchor_degree_pass: true,
  anchor_type_pass: true,
  pull_strength_pass: false,

  num_low_anchors_comment: "All low anchors secure",
  num_high_anchors_comment: "High anchors well positioned",
  anchor_accessories_comment: "Missing safety clips on 2 anchors",
  pull_strength_comment: "Failed pull test on corner anchor"
}.freeze

FAN_SAMPLE_DATA = {

  blower_serial: "FAN-2024-12345",
  fan_size_type: "Centrifugal 1.5HP",

  blower_tube_length: 1.75,
  blower_tube_length_pass: true,

  blower_flap_pass: "pass",
  blower_finger_pass: true,
  blower_visual_pass: false,
  pat_pass: "pass",

  blower_visual_comment: "Minor damage to fan housing"
}.freeze

USER_HEIGHT_SAMPLE_DATA = {

  containing_wall_height: 2.5,
  users_at_1000mm: 15,
  users_at_1200mm: 12,
  users_at_1500mm: 8,
  users_at_1800mm: 5,
  play_area_length: 6.5,
  play_area_width: 5.5,
  negative_adjustment: 0.5,

  containing_wall_height_comment: "Height adequate for tallest users",
  play_area_length_comment: "Length measurement confirmed",
  play_area_width_comment: "Width adequate for capacity",
  negative_adjustment_comment: "Obstruction reduces usable area"
}.freeze

SLIDE_SAMPLE_DATA = {

  slide_platform_height: 3.2,
  slide_wall_height: 1.1,
  runout: 2.8,
  slide_first_metre_height: 0.45,
  slide_beyond_first_metre_height: 0.35,

  clamber_netting_pass: "pass",
  runout_pass: false,
  slip_sheet_pass: true,
  slide_permanent_roof: true,

  slide_platform_height_comment: "Platform height verified",
  runout_comment: "Insufficient runout for platform height",
  clamber_netting_comment: "Netting secure and intact"
}.freeze

ENCLOSED_SAMPLE_DATA = {

  exit_number: 3,

  exit_number_pass: true,
  exit_sign_always_visible_pass: true,

  exit_number_comment: "Three exits well distributed",
  exit_sign_always_visible_comment: "Visibility confirmed from all angles"
}.freeze

BALL_POOL_SAMPLE_DATA = {

  age_range_marking_pass: true,
  max_height_markings_pass: false,
  suitable_matting_pass: true,
  air_jugglers_compliant_pass: true,
  balls_compliant_pass: false,
  gaps_pass: true,
  fitted_base_pass: true,

  ball_pool_depth: 400,
  ball_pool_depth_pass: true,
  ball_pool_entry: 600,
  ball_pool_entry_pass: false,

  age_range_marking_comment: "Age range clearly marked",
  max_height_markings_comment: "Max height marking missing",
  suitable_matting_comment: "Matting adequate",
  air_jugglers_compliant_comment: "Air jugglers meet standard",
  balls_compliant_comment: "Balls show wear",
  gaps_comment: "No gaps found",
  fitted_base_comment: "Base sheet fitted correctly",
  ball_pool_depth_comment: "Depth within limits",
  ball_pool_entry_comment: "Entry height exceeds maximum"
}.freeze

INFLATABLE_GAME_SAMPLE_DATA = {

  game_type: "Inflatable obstacle course with climbing wall",
  max_user_mass_pass: true,
  age_range_marking_pass: false,
  constant_air_flow_pass: true,
  design_risk_pass: true,
  intended_play_risk_pass: false,
  ancillary_equipment_pass: true,
  ancillary_equipment_compliant_pass: true,

  containing_wall_height: 1.5,
  containing_wall_height_pass: true,

  max_user_mass_comment: "Mass marking clearly displayed",
  age_range_marking_comment: "Age range marking faded",
  constant_air_flow_comment: "Continuous airflow confirmed",
  design_risk_comment: "Design meets safety standards",
  intended_play_risk_comment: "Play area needs improvement",
  ancillary_equipment_comment: "Equipment in good condition",
  ancillary_equipment_compliant_comment: "All equipment compliant",
  containing_wall_height_comment: "Wall height adequate"
}.freeze

RSpec.feature "All Assessment Forms Save", type: :feature do
  include_examples "assessment form save", :structure, STRUCTURE_SAMPLE_DATA
  include_examples "assessment form save", :materials, MATERIALS_SAMPLE_DATA
  include_examples "assessment form save", :anchorage, ANCHORAGE_SAMPLE_DATA
  include_examples "assessment form save", :fan, FAN_SAMPLE_DATA
  include_examples "assessment form save", :user_height, USER_HEIGHT_SAMPLE_DATA
  include_examples "assessment form save", :slide, SLIDE_SAMPLE_DATA
  include_examples "assessment form save", :enclosed, ENCLOSED_SAMPLE_DATA
  include_examples "assessment form save", :ball_pool, BALL_POOL_SAMPLE_DATA
  include_examples "assessment form save",
    :inflatable_game, INFLATABLE_GAME_SAMPLE_DATA
end
