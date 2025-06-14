require "rails_helper"

# Define sample data for each assessment type
# These constants could be moved to each assessment model if preferred

STRUCTURE_SAMPLE_DATA = {
  # Critical safety checks
  seam_integrity_pass: true,
  uses_lock_stitching_pass: false,
  air_loss_pass: true,
  straight_walls_pass: true,
  sharp_edges_pass: false,
  unit_stable_pass: true,

  # Measurements
  stitch_length: 15.5,
  evacuation_time: 45,
  unit_pressure: 2.8,
  blower_tube_length: 1.75,
  critical_fall_off_height: 0.85,
  trough_depth: 0.15,
  trough_adjacent_panel_width: 0.65,
  step_ramp_size: 0.3,

  # Pass/fail checks
  stitch_length_pass: true,
  evacuation_time_pass: false,
  unit_pressure_pass: true,
  blower_tube_length_pass: true,
  critical_fall_off_height_pass: true,
  trough_pass: true,
  trough_depth_pass: false,
  trough_adjacent_panel_width_pass: true,
  step_ramp_size_pass: true,
  entrapment_pass: false,
  markings_pass: true,
  grounding_pass: true,

  # Comments - only for fields that actually support them in the form
  unit_pressure_comment: "Unit pressure comment",
  critical_fall_off_height_comment: "Critical fall off height comment",
  step_ramp_size_comment: "Step ramp size comment",
  trough_depth_comment: "Trough depth comment",
  trough_adjacent_panel_width_comment: "Trough adjacent panel width comment",
  trough_comment: "Trough comment"
}.freeze

MATERIALS_SAMPLE_DATA = {
  # Measurements
  ropes: 12.5,

  # Material checks - using actual field names from the model
  fabric_strength_pass: true,
  fire_retardant_pass: false,
  thread_pass: true,
  ropes_pass: true,
  clamber_netting_pass: true,
  retention_netting_pass: false,
  zips_pass: true,
  windows_pass: true,
  artwork_pass: false,

  # Comments
  ropes_comment: "Rope diameter within spec",
  fire_retardant_comment: "Requires flame retardant treatment",
  thread_comment: "Thread meets temperature requirements",
  retention_netting_comment: "Netting shows signs of wear",
  artwork_comment: "Artwork adhesive failing"
}.freeze

ANCHORAGE_SAMPLE_DATA = {
  # Counts
  num_low_anchors: 6,
  num_high_anchors: 4,

  # Pass/fail checks
  num_low_anchors_pass: true,
  num_high_anchors_pass: true,
  anchor_accessories_pass: false,
  anchor_degree_pass: true,
  anchor_type_pass: true,
  pull_strength_pass: false,

  # Comments
  num_low_anchors_comment: "All low anchors secure",
  num_high_anchors_comment: "High anchors well positioned",
  anchor_accessories_comment: "Missing safety clips on 2 anchors",
  pull_strength_comment: "Failed pull test on corner anchor"
}.freeze

FAN_SAMPLE_DATA = {
  # Text fields
  blower_serial: "FAN-2024-12345",
  fan_size_type: "Centrifugal 1.5HP",

  # Pass/fail checks
  blower_flap_pass: true,
  blower_finger_pass: true,
  blower_visual_pass: false,
  pat_pass: true,
  blower_serial_pass: true,

  # Comments
  blower_serial_comment: "Serial verified against manufacturer database",
  blower_visual_comment: "Minor damage to fan housing"
}.freeze

USER_HEIGHT_SAMPLE_DATA = {
  # Measurements
  containing_wall_height: 2.5,
  platform_height: 1.8,
  tallest_user_height: 1.95,
  users_at_1000mm: 15,
  users_at_1200mm: 12,
  users_at_1500mm: 8,
  users_at_1800mm: 5,
  play_area_length: 6.5,
  play_area_width: 5.5,
  negative_adjustment: 0.5,

  # Comments
  containing_wall_height_comment: "Height adequate for tallest users",
  platform_height_comment: "Platform height verified",
  tallest_user_height_comment: "Maximum user height checked",
  play_area_length_comment: "Length measurement confirmed",
  play_area_width_comment: "Width adequate for capacity",
  negative_adjustment_comment: "Obstruction reduces usable area"
}.freeze

SLIDE_SAMPLE_DATA = {
  # Measurements
  slide_platform_height: 3.2,
  slide_wall_height: 1.1,
  runout: 2.8,
  slide_first_metre_height: 0.45,
  slide_beyond_first_metre_height: 0.35,

  # Pass/fail checks
  clamber_netting_pass: true,
  runout_pass: false,
  slip_sheet_pass: true,
  slide_permanent_roof: true,

  # Comments
  slide_platform_height_comment: "Platform height verified",
  runout_comment: "Insufficient runout for platform height",
  clamber_netting_comment: "Netting secure and intact"
}.freeze

ENCLOSED_SAMPLE_DATA = {
  # Measurements
  exit_number: 3,

  # Pass/fail checks
  exit_number_pass: true,
  exit_sign_always_visible_pass: true,

  # Comments
  exit_number_comment: "Three exits well distributed",
  exit_sign_always_visible_comment: "Visibility confirmed from all angles"
}.freeze

RSpec.feature "All Assessment Forms Save", type: :feature do
  # Test each assessment type
  include_examples "assessment form save", :structure, STRUCTURE_SAMPLE_DATA
  include_examples "assessment form save", :materials, MATERIALS_SAMPLE_DATA
  include_examples "assessment form save", :anchorage, ANCHORAGE_SAMPLE_DATA
  include_examples "assessment form save", :fan, FAN_SAMPLE_DATA
  include_examples "assessment form save", :user_height, USER_HEIGHT_SAMPLE_DATA
  include_examples "assessment form save", :slide, SLIDE_SAMPLE_DATA
  include_examples "assessment form save", :enclosed, ENCLOSED_SAMPLE_DATA
end
