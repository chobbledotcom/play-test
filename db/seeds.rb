# TestLog Seed Data
# British inflatable equipment inspection system
# Run with: rails db:seed

# Helper methods

def british_phone_number
  # Generate realistic UK mobile numbers (07xxx format)
  "07#{rand(100..999)} #{rand(100..999)} #{rand(1000..9999)}"
end

def british_postcode
  # Generate realistic UK postcodes
  prefixes = ["SW", "SE", "NW", "N", "E", "W", "EC", "WC", "B", "M", "L", "G", "EH", "CF", "BS", "OX", "CB"]
  "#{prefixes.sample}#{rand(1..20)} #{rand(1..9)}#{("A".."Z").to_a.sample}#{("A".."Z").to_a.sample}"
end

def british_address
  streets = ["High Street", "Church Lane", "Victoria Road", "King's Road", "Queen Street",
    "Park Avenue", "Station Road", "London Road", "Market Square", "The Green"]
  numbers = (1..200).to_a
  "#{numbers.sample} #{streets.sample}"
end

def british_city
  ["London", "Birmingham", "Manchester", "Leeds", "Liverpool", "Newcastle", "Bristol",
    "Sheffield", "Nottingham", "Leicester", "Oxford", "Cambridge", "Brighton", "Southampton",
    "Edinburgh", "Glasgow", "Cardiff", "Belfast"].sample
end

# Clear existing data in development
if Rails.env.development?
  # Delete in correct order to respect foreign keys
  UserHeightAssessment.destroy_all
  StructureAssessment.destroy_all
  SlideAssessment.destroy_all
  MaterialsAssessment.destroy_all
  FanAssessment.destroy_all
  EnclosedAssessment.destroy_all
  AnchorageAssessment.destroy_all
  Inspection.destroy_all
  Unit.destroy_all
  User.destroy_all
  InspectorCompany.destroy_all

  # Clean up Active Storage
  ActiveStorage::Attachment.all.each { |attachment| attachment.purge }
  ActiveStorage::Blob.all.each { |blob| blob.purge }
end

# Phase 1: Inspector Companies
stefan_testing = InspectorCompany.create!(
  name: "Stefan's Testing Co",
  rpii_registration_number: "RPII-001",
  email: "info@play-test.co.uk",
  phone: british_phone_number,
  address: british_address,
  city: "Birmingham",
  state: "West Midlands",
  postal_code: british_postcode,
  country: "UK",
  active: true,
  notes: "Premier inflatable inspection service in the Midlands. Established 2015."
)

steph_test = InspectorCompany.create!(
  name: "Steph Test",
  rpii_registration_number: "RPII-002",
  email: "enquiries@play-test.co.uk",
  phone: british_phone_number,
  address: british_address,
  city: "Manchester",
  state: "Greater Manchester",
  postal_code: british_postcode,
  country: "UK",
  active: true,
  notes: "Specialising in soft play and inflatable safety across the North West."
)

steve_inflatable = InspectorCompany.create!(
  name: "Steve Inflatable Testing",
  rpii_registration_number: "RPII-003",
  email: "old@play-test.co.uk",
  phone: british_phone_number,
  address: british_address,
  city: "London",
  state: "Greater London",
  postal_code: british_postcode,
  country: "UK",
  active: false,
  notes: "Company ceased trading in 2023. Records maintained for historical purposes."
)

# Phase 2: Users
# Admin user (no company)
User.create!(
  email: "admin@play-test.co.uk",
  password: "password123",
  inspection_limit: -1,
  time_display: "date"
)

# Test user with access to all data
test_user = User.create!(
  email: "test@play-test.co.uk",
  password: "password123",
  inspection_company: stefan_testing,
  inspection_limit: -1,
  time_display: "time"
)

# Stefan's Testing users
lead_inspector = User.create!(
  email: "lead@play-test.co.uk",
  password: "password123",
  inspection_company: stefan_testing,
  inspection_limit: -1,
  time_display: "time"
)

User.create!(
  email: "junior@play-test.co.uk",
  password: "password123",
  inspection_company: stefan_testing,
  inspection_limit: 10,
  time_display: "date"
)

User.create!(
  email: "senior@play-test.co.uk",
  password: "password123",
  inspection_company: stefan_testing,
  inspection_limit: 50,
  time_display: "time"
)

# Steph Test user
steph_test_inspector = User.create!(
  email: "inspector@play-test.co.uk",
  password: "password123",
  inspection_company: steph_test,
  inspection_limit: 20,
  time_display: "date"
)

# Retired company user
User.create!(
  email: "old@play-test.co.uk",
  password: "password123",
  inspection_company: steve_inflatable,
  inspection_limit: 5,
  time_display: "date"
)

# Phase 3: Units (British terminology)
# Manufacturers

# Owners

# Create units for test user (all units will be linked to test user)
castle_standard = Unit.create!(
  user: test_user,
  name: "Medieval Castle Bouncer",
  serial: "ACQ-2021-#{rand(1000..9999)}",
  manufacturer: "Airquee Manufacturing Ltd",
  model: "Castle Deluxe 15",
  owner: "Stef's Castles",
  description: "15ft x 15ft medieval themed bouncy castle with turrets",
  width: 4.5,
  length: 4.5,
  height: 3.5,
  has_slide: false,
  is_totally_enclosed: false
)

castle_large = Unit.create!(
  user: test_user,
  name: "Giant Party Castle",
  serial: "BCN-2020-#{rand(1000..9999)}",
  manufacturer: "Bouncy Castle Boys",
  model: "Mega Castle 30",
  owner: "Estephan Events",
  description: "30ft x 30ft large bouncy castle suitable for 20+ children",
  width: 9.0,
  length: 9.0,
  height: 4.5,
  has_slide: false,
  is_totally_enclosed: false
)

castle_slide_combo = Unit.create!(
  user: test_user,
  name: "Princess Castle with Slide",
  serial: "J4J-2022-#{rand(1000..9999)}",
  manufacturer: "Jump4Joy Inflatables",
  model: "Princess Combo DLX",
  owner: "Stefan's Fun Factory",
  description: "Pink princess themed castle with integrated 8ft slide",
  width: 5.5,
  length: 7.0,
  height: 4.0,
  has_slide: true,
  is_totally_enclosed: false
)

soft_play_unit = Unit.create!(
  user: test_user,
  name: "Toddler Soft Play Centre",
  serial: "CIU-2023-#{rand(1000..9999)}",
  manufacturer: "Custom Inflatables UK",
  model: "Soft Play Junior",
  owner: "Steff's Soft Play",
  description: "Fully enclosed soft play area for under 5s",
  width: 6.0,
  length: 6.0,
  height: 2.5,
  has_slide: false,
  is_totally_enclosed: true
)

obstacle_course = Unit.create!(
  user: test_user,
  name: "Assault Course Challenge",
  serial: "IWL-2021-#{rand(1000..9999)}",
  manufacturer: "Inflatable World Ltd",
  model: "Obstacle Pro 40",
  owner: "Stephan's Adventure Co",
  description: "40ft assault course with obstacles, tunnels and slide finish",
  width: 3.0,
  length: 12.0,
  height: 3.5,
  has_slide: true,
  is_totally_enclosed: false
)

giant_slide = Unit.create!(
  user: test_user,
  name: "Mega Slide Experience",
  serial: "ACQ-2019-#{rand(1000..9999)}",
  manufacturer: "Airquee Manufacturing Ltd",
  model: "Giant Slide 25",
  owner: "Stefan Family Inflatables",
  description: "25ft platform height giant inflatable slide",
  width: 5.0,
  length: 15.0,
  height: 7.5,
  has_slide: true,
  is_totally_enclosed: false
)

gladiator_duel = Unit.create!(
  user: test_user,
  name: "Gladiator Duel Platform",
  serial: "HHE-2022-#{rand(1000..9999)}",
  manufacturer: "Happy Hop Europe",
  model: "Gladiator Arena",
  owner: "Stefano's Party Hire",
  description: "Inflatable gladiator duel platform with pedestals",
  width: 6.0,
  length: 6.0,
  height: 1.5,
  has_slide: false,
  is_totally_enclosed: false
)

bungee_run = Unit.create!(
  user: test_user,
  name: "Double Bungee Run",
  serial: "PCM-2023-#{rand(1000..9999)}",
  manufacturer: "Party Castle Manufacturers",
  model: "Bungee Sprint Dual",
  owner: "Stef's Fun Factory",
  description: "Two lane inflatable bungee run competition game",
  width: 4.0,
  length: 10.0,
  height: 2.5,
  has_slide: false,
  is_totally_enclosed: false
)

# Phase 4: Inspections with various statuses

# Helper to create full assessment data with correct field names
def create_assessments_for_inspection(inspection, unit, passed: true)
  # Anchorage Assessment
  AnchorageAssessment.create!(
    inspection: inspection,
    num_low_anchors: rand(6..12),
    num_high_anchors: rand(4..8),
    num_anchors_pass: passed,
    anchor_accessories_pass: passed,
    anchor_degree_pass: passed,
    anchor_type_pass: passed,
    pull_strength_pass: passed,
    anchor_type_comment: passed ? nil : "Some wear visible on anchor points"
  )

  # Structure Assessment
  StructureAssessment.create!(
    inspection: inspection,
    # Critical safety checks (all required for complete assessment)
    seam_integrity_pass: passed,
    lock_stitch_pass: passed,
    air_loss_pass: passed,
    straight_walls_pass: passed,
    sharp_edges_pass: passed,
    unit_stable_pass: passed,
    # Additional checks (all required for complete assessment)
    stitch_length_pass: passed,
    blower_tube_length_pass: passed,
    step_size_pass: passed,
    fall_off_height_pass: passed,
    unit_pressure_pass: passed,
    trough_pass: passed,
    entrapment_pass: passed,
    markings_pass: passed,
    grounding_pass: passed,
    # Required measurements
    stitch_length: rand(8..12),
    unit_pressure_value: rand(1.0..3.0).round(1),
    blower_tube_length: rand(2.0..5.0).round(1),
    step_size_value: rand(200..400),
    fall_off_height_value: rand(0.5..2.0).round(1),
    trough_depth_value: rand(0.1..0.5).round(1),
    trough_width_value: rand(0.3..1.0).round(1),
    # Comments
    seam_integrity_comment: passed ? "All seams in good condition" : "Minor thread loosening noted",
    lock_stitch_comment: passed ? "Lock stitching intact throughout" : "Some lock stitching showing wear",
    stitch_length_comment: "Measured at regular intervals"
  )

  # Materials Assessment
  MaterialsAssessment.create!(
    inspection: inspection,
    rope_size: rand(18..45),
    rope_size_pass: passed,
    clamber_pass: passed,
    retention_netting_pass: passed,
    zips_pass: passed,
    windows_pass: passed,
    artwork_pass: passed,
    thread_pass: passed,
    fabric_pass: passed,
    fire_retardant_pass: passed,
    rope_size_comment: passed ? nil : "Rope shows signs of wear",
    fabric_comment: passed ? "Fabric in good condition" : "Minor surface wear noted"
  )

  # Fan Assessment
  FanAssessment.create!(
    inspection: inspection,
    # All safety checks must be assessed
    blower_flap_pass: passed,
    blower_finger_pass: passed,
    blower_visual_pass: passed,
    pat_pass: passed,
    # Required specifications
    blower_serial: "FAN-#{rand(1000..9999)}",
    fan_size_comment: passed ? "Fan operating correctly at optimal pressure" : "Fan requires servicing",
    # Additional comments
    blower_flap_comment: passed ? "Flap mechanism functioning correctly" : "Flap sticking occasionally",
    blower_finger_comment: passed ? "Guard secure, no finger trap hazards" : "Guard needs tightening",
    blower_visual_comment: passed ? "Visual inspection satisfactory" : "Some wear visible on housing",
    pat_comment: passed ? "PAT test valid until #{(Date.current + 6.months).strftime("%B %Y")}" : "PAT test overdue"
  )

  # User Height Assessment
  UserHeightAssessment.create!(
    inspection: inspection,
    # Required height measurements
    containing_wall_height: rand(1.0..2.0).round(1),
    platform_height: rand(0.5..1.5).round(1),
    tallest_user_height: rand(1.2..1.8).round(1),
    # User capacity counts (all required for complete assessment)
    users_at_1000mm: rand(0..5),
    users_at_1200mm: rand(2..8),
    users_at_1500mm: rand(4..10),
    users_at_1800mm: rand(2..6),
    # Play area dimensions (required)
    play_area_length: unit.length * 0.8,
    play_area_width: unit.width * 0.8,
    negative_adjustment: rand(0..2.0).round(1),
    permanent_roof: false,
    # Required comment
    tallest_user_height_comment: passed ? "Capacity within safe limits based on EN 14960:2019" : "Review user capacity - exceeds recommended limits",
    # Additional comments for realism
    containing_wall_height_comment: "Measured from base to top of wall",
    platform_height_comment: "Platform height acceptable for age group",
    play_area_length_comment: "Effective play area after deducting obstacles",
    play_area_width_comment: "Width measured at narrowest point"
  )

  # Slide Assessment (if unit has slide)
  if unit.has_slide
    SlideAssessment.create!(
      inspection: inspection,
      # Required measurements for complete assessment
      slide_platform_height: rand(2.0..6.0).round(1),
      slide_wall_height: rand(1.0..2.0).round(1),
      runout_value: rand(1.5..3.0).round(1),
      slide_first_metre_height: rand(0.3..0.8).round(1),
      slide_beyond_first_metre_height: rand(0.8..1.5).round(1),
      # Safety assessments (all required)
      clamber_netting_pass: passed,
      runout_pass: passed,
      slip_sheet_pass: passed,
      slide_permanent_roof: false,
      # Required comment
      slide_platform_height_comment: passed ? "Platform height compliant with EN 14960:2019" : "Platform height exceeds recommended limits",
      # Additional realistic comments
      slide_wall_height_comment: "Wall height measured from slide bed",
      runout_comment: passed ? "Runout area clear and adequate" : "Runout area needs extending",
      clamber_netting_comment: passed ? "Netting secure with no gaps" : "Some gaps in netting need attention",
      slip_sheet_comment: passed ? "Slip sheet in good condition" : "Slip sheet showing wear"
    )
  end

  # Enclosed Assessment (if unit is totally enclosed)
  if unit.is_totally_enclosed
    EnclosedAssessment.create!(
      inspection: inspection,
      # Required fields for complete assessment
      exit_number: rand(1..3),
      exit_number_pass: passed,
      exit_visible_pass: passed,
      # Comments
      exit_number_comment: passed ? "Number of exits compliant with unit size" : "Additional exit required",
      exit_visible_comment: passed ? "All exits clearly marked with illuminated signage" : "Exit signage needs improvement - not clearly visible"
    )
  end
end

# Recent completed inspection (test user)
recent_inspection = Inspection.create!(
  user: test_user,
  unit: castle_standard,
  inspector_company: stefan_testing,
  inspection_date: 3.days.ago,
  inspection_location: "Sutton Park, Birmingham",
  unique_report_number: "STC-2025-#{rand(1000..9999)}",
  complete_date: Time.current,
  passed: true,
  comments: "Annual inspection completed. Unit in excellent condition.",
  recommendations: "Continue regular maintenance schedule.",
  general_notes: "Client very happy with service. Park location had good access.",
  width: castle_standard.width,
  length: castle_standard.length,
  height: castle_standard.height,
  has_slide: castle_standard.has_slide,
  is_totally_enclosed: castle_standard.is_totally_enclosed
)
create_assessments_for_inspection(recent_inspection, castle_standard, passed: true)

# Failed inspection (test user)
failed_inspection = Inspection.create!(
  user: test_user,
  unit: obstacle_course,
  inspector_company: stefan_testing,
  inspection_date: 1.week.ago,
  inspection_location: "Victoria Park, Manchester",
  unique_report_number: "STC-2025-#{rand(1000..9999)}",
  complete_date: Time.current,
  passed: false,
  comments: "Several issues identified requiring immediate attention.",
  recommendations: "1. Replace worn anchor straps\n2. Repair seam separation\n3. Reinspect within 30 days",
  general_notes: "Unit owner notified of failures. Removed from service pending repairs.",
  width: obstacle_course.width,
  length: obstacle_course.length,
  height: obstacle_course.height,
  has_slide: obstacle_course.has_slide,
  is_totally_enclosed: obstacle_course.is_totally_enclosed
)
create_assessments_for_inspection(failed_inspection, obstacle_course, passed: false)

# Historical inspections (test user)
[6.months.ago, 1.year.ago].each do |date|
  historical = Inspection.create!(
    user: test_user,
    unit: castle_large,
    inspector_company: stefan_testing,
    inspection_date: date,
    inspection_location: "NEC Birmingham",
    unique_report_number: "STC-#{date.year}-#{rand(1000..9999)}",
    complete_date: Time.current,
    passed: true,
    comments: "Routine #{(date == 1.year.ago) ? "annual" : "six-month"} inspection.",
    width: castle_large.width,
    length: castle_large.length,
    height: castle_large.height,
    has_slide: castle_large.has_slide,
    is_totally_enclosed: castle_large.is_totally_enclosed,
    inspector_signature: "#{test_user.email.split("@").first.titleize} (Digital Signature)",
    signature_timestamp: date
  )
  create_assessments_for_inspection(historical, castle_large, passed: true)
end

# Draft inspections (test user)
Inspection.create!(
  user: test_user,
  unit: giant_slide,
  inspector_company: stefan_testing,
  inspection_date: Date.current,
  inspection_location: nil,
  complete_date: nil,
  width: giant_slide.width,
  length: giant_slide.length,
  height: giant_slide.height,
  has_slide: giant_slide.has_slide,
  is_totally_enclosed: giant_slide.is_totally_enclosed
)

# In progress inspection (different inspector)
in_progress = Inspection.create!(
  user: steph_test_inspector,
  unit: gladiator_duel,
  inspector_company: steph_test,
  inspection_date: Date.current,
  inspection_location: "Heaton Park, Manchester",
  unique_report_number: "ST-2025-#{rand(1000..9999)}",
  complete_date: nil,
  width: gladiator_duel.width,
  length: gladiator_duel.length,
  height: gladiator_duel.height,
  has_slide: gladiator_duel.has_slide,
  is_totally_enclosed: gladiator_duel.is_totally_enclosed
)
# Only create some assessments for in-progress
AnchorageAssessment.create!(
  inspection: in_progress,
  num_low_anchors: 8,
  num_high_anchors: 0,
  num_anchors_pass: true,
  anchor_accessories_pass: true,
  anchor_degree_pass: true
)

# Create more varied inspections for test user
[soft_play_unit, castle_slide_combo, bungee_run].each do |unit|
  inspection = Inspection.create!(
    user: test_user,
    unit: unit,
    inspector_company: test_user.inspection_company,
    inspection_date: rand(1..60).days.ago,
    inspection_location: "#{british_address}, #{british_city}",
    unique_report_number: "#{test_user.inspection_company.name[0..2].upcase}-2025-#{rand(1000..9999)}",
    complete_date: Time.current,
    passed: rand(0..4) > 0, # 80% pass rate
    comments: "Regular inspection completed as scheduled.",
    width: unit.width,
    length: unit.length,
    height: unit.height,
    has_slide: unit.has_slide,
    is_totally_enclosed: unit.is_totally_enclosed
  )
  create_assessments_for_inspection(inspection, unit, passed: inspection.passed)
end

# Create a few inspections for other users to show variety
lead_inspection = Inspection.create!(
  user: lead_inspector,
  unit: castle_standard,
  inspector_company: stefan_testing,
  inspection_date: 2.months.ago,
  inspection_location: "Cannon Hill Park, Birmingham",
  unique_report_number: "STC-2024-#{rand(1000..9999)}",
  complete_date: Time.current,
  passed: true,
  comments: "Six-month inspection completed.",
  width: castle_standard.width,
  length: castle_standard.length,
  height: castle_standard.height,
  has_slide: castle_standard.has_slide,
  is_totally_enclosed: castle_standard.is_totally_enclosed
)
create_assessments_for_inspection(lead_inspection, castle_standard, passed: true)

# Create a complete inspection with all assessments
complete_inspection = Inspection.create!(
  user: test_user,
  unit: castle_large,
  inspector_company: stefan_testing,
  inspection_date: 1.month.ago,
  inspection_location: "Alexander Stadium, Birmingham",
  unique_report_number: "STC-2025-#{rand(1000..9999)}",
  complete_date: Time.current,
  passed: true,
  comments: "Monthly safety inspection completed. All checks passed.",
  recommendations: "No issues found. Continue standard maintenance.",
  general_notes: "Unit used for major event. Excellent condition maintained.",
  width: castle_large.width,
  length: castle_large.length,
  height: castle_large.height,
  has_slide: castle_large.has_slide,
  is_totally_enclosed: castle_large.is_totally_enclosed,
  inspector_signature: "Test User (Digital Signature)",
  signature_timestamp: 1.month.ago
)
create_assessments_for_inspection(complete_inspection, castle_large, passed: true)

# Reload to ensure all associations are loaded
complete_inspection.reload
