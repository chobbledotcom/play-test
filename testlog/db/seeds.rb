# TestLog Seed Data
# British inflatable equipment inspection system
# Run with: rails db:seed

Rails.logger = Logger.new($stdout)
Rails.logger.info "🎪 Starting TestLog seed data creation..."

# Helper methods
def log_creation(type, name)
  Rails.logger.info "  ✅ Created #{type}: #{name}"
end

def british_phone_number
  # Generate realistic UK mobile numbers (07xxx format)
  "07#{rand(100..999)} #{rand(100..999)} #{rand(1000..9999)}"
end

def british_postcode
  # Generate realistic UK postcodes
  prefixes = ["SW", "SE", "NW", "N", "E", "W", "EC", "WC", "B", "M", "L", "G", "EH", "CF", "BS", "OX", "CB"]
  "#{prefixes.sample}#{rand(1..20)} #{rand(1..9)}#{('A'..'Z').to_a.sample}#{('A'..'Z').to_a.sample}"
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
  Rails.logger.info "🧹 Clearing existing data..."
  
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
  
  Rails.logger.info "  ✅ Data cleared"
end

# Phase 1: Inspector Companies
Rails.logger.info "\n📋 Creating Inspector Companies..."

bounce_safe = InspectorCompany.create!(
  name: "Bounce Safe Inspections Ltd",
  rpii_registration_number: "RPII-001",
  email: "info@bouncesafe.co.uk",
  phone: british_phone_number,
  address: british_address,
  city: "Birmingham",
  state: "West Midlands",
  postal_code: british_postcode,
  country: "UK",
  active: true,
  notes: "Premier inflatable inspection service in the Midlands. Established 2015."
)
log_creation("Inspector Company", bounce_safe.name)

kids_play = InspectorCompany.create!(
  name: "Kids Play Safety Services",
  rpii_registration_number: "RPII-002", 
  email: "enquiries@kidsplaysafety.co.uk",
  phone: british_phone_number,
  address: british_address,
  city: "Manchester",
  state: "Greater Manchester",
  postal_code: british_postcode,
  country: "UK",
  active: true,
  notes: "Specialising in soft play and inflatable safety across the North West."
)
log_creation("Inspector Company", kids_play.name)

retired_inspections = InspectorCompany.create!(
  name: "Retired Inspections Co",
  rpii_registration_number: "RPII-003",
  email: "old@retiredinspections.co.uk", 
  phone: british_phone_number,
  address: british_address,
  city: "London",
  state: "Greater London",
  postal_code: british_postcode,
  country: "UK",
  active: false,
  notes: "Company ceased trading in 2023. Records maintained for historical purposes."
)
log_creation("Inspector Company", retired_inspections.name)

# Phase 2: Users
Rails.logger.info "\n👥 Creating Users..."

# Admin user (no company)
admin_user = User.create!(
  email: "admin@testlog.com",
  password: "password123",
  inspection_limit: -1,
  time_display: "date"
)
log_creation("User", "Admin (#{admin_user.email})")

# Bounce Safe users
lead_inspector = User.create!(
  email: "lead@bouncesafe.co.uk",
  password: "password123",
  inspection_company: bounce_safe,
  inspection_limit: -1,
  time_display: "time"
)
log_creation("User", "Lead Inspector (#{lead_inspector.email})")

junior_inspector = User.create!(
  email: "junior@bouncesafe.co.uk",
  password: "password123",
  inspection_company: bounce_safe,
  inspection_limit: 10,
  time_display: "date"
)
log_creation("User", "Junior Inspector (#{junior_inspector.email})")

senior_inspector = User.create!(
  email: "senior@bouncesafe.co.uk",
  password: "password123",
  inspection_company: bounce_safe,
  inspection_limit: 50,
  time_display: "time"
)
log_creation("User", "Senior Inspector (#{senior_inspector.email})")

# Kids Play user
kids_play_inspector = User.create!(
  email: "inspector@kidsplaysafety.co.uk",
  password: "password123",
  inspection_company: kids_play,
  inspection_limit: 20,
  time_display: "date"
)
log_creation("User", "Kids Play Inspector (#{kids_play_inspector.email})")

# Retired company user
retired_user = User.create!(
  email: "old@retiredinspections.co.uk",
  password: "password123",
  inspection_company: retired_inspections,
  inspection_limit: 5,
  time_display: "date"
)
log_creation("User", "Retired Company User (#{retired_user.email})")

# Phase 3: Units (British terminology)
Rails.logger.info "\n🏰 Creating Inflatable Units..."

# Manufacturers
manufacturers = [
  "Airquee Manufacturing Ltd",
  "Bouncy Castle Network UK", 
  "Jump4Joy Inflatables",
  "Happy Hop Europe",
  "Custom Inflatables UK",
  "Inflatable World Ltd",
  "Party Castle Manufacturers"
]

# Owners
owners = [
  "Funtime Hire Birmingham",
  "Party Plus Rentals",
  "Bounce About Manchester",
  "Kids Party Hire Co",
  "Event Entertainment Ltd",
  "Family Fun Inflatables",
  "Premier Party Hire"
]

# Create units for lead inspector
castle_standard = Unit.create!(
  user: lead_inspector,
  name: "Medieval Castle Bouncer",
  serial: "ACQ-2021-#{rand(1000..9999)}",
  manufacturer: "Airquee Manufacturing Ltd",
  model: "Castle Deluxe 15",
  owner: "Funtime Hire Birmingham",
  description: "15ft x 15ft medieval themed bouncy castle with turrets",
  width: 4.5,
  length: 4.5,
  height: 3.5,
  has_slide: false,
  is_totally_enclosed: false
)
log_creation("Unit", castle_standard.name)

castle_large = Unit.create!(
  user: lead_inspector,
  name: "Giant Party Castle",
  serial: "BCN-2020-#{rand(1000..9999)}",
  manufacturer: "Bouncy Castle Network UK",
  model: "Mega Castle 30",
  owner: "Party Plus Rentals",
  description: "30ft x 30ft large bouncy castle suitable for 20+ children",
  width: 9.0,
  length: 9.0,
  height: 4.5,
  has_slide: false,
  is_totally_enclosed: false
)
log_creation("Unit", castle_large.name)

castle_slide_combo = Unit.create!(
  user: lead_inspector,
  name: "Princess Castle with Slide",
  serial: "J4J-2022-#{rand(1000..9999)}",
  manufacturer: "Jump4Joy Inflatables",
  model: "Princess Combo DLX",
  owner: "Bounce About Manchester",
  description: "Pink princess themed castle with integrated 8ft slide",
  width: 5.5,
  length: 7.0,
  height: 4.0,
  has_slide: true,
  is_totally_enclosed: false
)
log_creation("Unit", castle_slide_combo.name)

soft_play_unit = Unit.create!(
  user: junior_inspector,
  name: "Toddler Soft Play Centre",
  serial: "CIU-2023-#{rand(1000..9999)}",
  manufacturer: "Custom Inflatables UK",
  model: "Soft Play Junior",
  owner: "Kids Party Hire Co",
  description: "Fully enclosed soft play area for under 5s",
  width: 6.0,
  length: 6.0,
  height: 2.5,
  has_slide: false,
  is_totally_enclosed: true
)
log_creation("Unit", soft_play_unit.name)

obstacle_course = Unit.create!(
  user: senior_inspector,
  name: "Assault Course Challenge",
  serial: "IWL-2021-#{rand(1000..9999)}",
  manufacturer: "Inflatable World Ltd",
  model: "Obstacle Pro 40",
  owner: "Event Entertainment Ltd",
  description: "40ft assault course with obstacles, tunnels and slide finish",
  width: 3.0,
  length: 12.0,
  height: 3.5,
  has_slide: true,
  is_totally_enclosed: false
)
log_creation("Unit", obstacle_course.name)

giant_slide = Unit.create!(
  user: lead_inspector,
  name: "Mega Slide Experience",
  serial: "ACQ-2019-#{rand(1000..9999)}",
  manufacturer: "Airquee Manufacturing Ltd",
  model: "Giant Slide 25",
  owner: "Family Fun Inflatables",
  description: "25ft platform height giant inflatable slide",
  width: 5.0,
  length: 15.0,
  height: 7.5,
  has_slide: true,
  is_totally_enclosed: false
)
log_creation("Unit", giant_slide.name)

gladiator_duel = Unit.create!(
  user: kids_play_inspector,
  name: "Gladiator Duel Platform",
  serial: "HHE-2022-#{rand(1000..9999)}",
  manufacturer: "Happy Hop Europe",
  model: "Gladiator Arena",
  owner: "Premier Party Hire",
  description: "Inflatable gladiator duel platform with pedestals",
  width: 6.0,
  length: 6.0,
  height: 1.5,
  has_slide: false,
  is_totally_enclosed: false
)
log_creation("Unit", gladiator_duel.name)

bungee_run = Unit.create!(
  user: senior_inspector,
  name: "Double Bungee Run",
  serial: "PCM-2023-#{rand(1000..9999)}",
  manufacturer: "Party Castle Manufacturers",
  model: "Bungee Sprint Dual",
  owner: "Funtime Hire Birmingham",
  description: "Two lane inflatable bungee run competition game",
  width: 4.0,
  length: 10.0,
  height: 2.5,
  has_slide: false,
  is_totally_enclosed: false
)
log_creation("Unit", bungee_run.name)

# Phase 4: Inspections with various statuses
Rails.logger.info "\n📋 Creating Inspections..."

# Helper to create full assessment data
def create_assessments_for_inspection(inspection, unit, passed: true)
  # Anchorage Assessment
  AnchorageAssessment.create!(
    inspection: inspection,
    num_low_anchors: rand(6..12),
    num_high_anchors: rand(4..8),
    low_webbing_ok: passed,
    low_karabiner_ok: passed,
    low_rope_ok: passed || rand(0..1) == 1,
    high_webbing_ok: passed,
    high_karabiner_ok: passed,
    high_rope_ok: passed,
    low_comment: passed ? nil : "Some wear visible on anchor points",
    high_comment: nil
  )
  
  # Structure Assessment
  StructureAssessment.create!(
    inspection: inspection,
    ext_stitching_ok: passed,
    ext_material_ok: passed,
    ext_bolts_ok: passed,
    ext_baffles_ok: passed,
    ext_entrance_ok: passed,
    int_stitching_ok: passed,
    int_material_ok: passed,
    int_entrance_ok: passed,
    int_no_rope_ok: passed,
    int_baffles_ok: passed,
    seam_length: rand(8..12),
    seam_condition_ok: passed,
    seam_comment: passed ? "All seams in good condition" : "Minor thread loosening noted",
    seal_tape_ok: passed,
    base_drain_ok: passed,
    pressure: rand(1.0..3.0).round(1),
    underside_ok: passed,
    bed_patch_ok: passed,
    evacuation_time: rand(30..120),
    passes: passed
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
    serial_1: "FAN-#{rand(1000..9999)}",
    blower_guard_ok_1: passed,
    outlet_sealed_1: passed,
    cable_ok_1: passed,
    pat_test_date_1: passed ? Date.current - rand(30..300).days : nil,
    passes_1: passed,
    serial_2: rand(0..1) == 1 ? "FAN-#{rand(1000..9999)}" : nil,
    blower_guard_ok_2: rand(0..1) == 1 ? passed : nil,
    outlet_sealed_2: rand(0..1) == 1 ? passed : nil,
    cable_ok_2: rand(0..1) == 1 ? passed : nil,
    pat_test_date_2: rand(0..1) == 1 ? Date.current - rand(30..300).days : nil,
    passes_2: rand(0..1) == 1 ? passed : nil
  )
  
  # User Height Assessment
  UserHeightAssessment.create!(
    inspection: inspection,
    height_below_60: rand(0..4),
    height_60_90: rand(2..6),
    height_90_120: rand(4..8),
    height_120_150: rand(3..6),
    height_above_150: rand(0..3),
    passes: passed
  )
  
  # Slide Assessment (if unit has slide)
  if unit.has_slide
    SlideAssessment.create!(
      inspection: inspection,
      platform_height: rand(2.0..6.0).round(1),
      platform_netting_ok: passed,
      entrance_width: rand(0.6..1.0).round(1),
      entrance_height: rand(0.8..1.2).round(1),
      slide_bed_ok: passed,
      wall_height_left: rand(0.8..1.5).round(1),
      wall_height_right: rand(0.8..1.5).round(1),
      wall_height_angle: rand(40..60),
      runout_length: rand(1.5..3.0).round(1),
      landing_ok: passed,
      slide_bed_comment: passed ? "Slide surface in excellent condition" : "Minor scuffing on slide bed",
      passes: passed
    )
  end
  
  # Enclosed Assessment (if unit is totally enclosed)
  if unit.is_totally_enclosed
    EnclosedAssessment.create!(
      inspection: inspection,
      exit_easily_found: passed,
      exit_unobstructed: passed,
      exit_height_ok: passed,
      exit_width_ok: passed,
      exit_number: rand(1..3),
      passes: passed
    )
  end
end

# Recent completed inspection
recent_inspection = Inspection.create!(
  user: lead_inspector,
  unit: castle_standard,
  inspector_company: bounce_safe,
  inspection_date: 3.days.ago,
  inspection_location: "Sutton Park, Birmingham",
  unique_report_number: "BSI-2025-#{rand(1000..9999)}",
  status: "completed",
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
log_creation("Inspection", "Recent passed inspection for #{castle_standard.name}")

# Failed inspection
failed_inspection = Inspection.create!(
  user: junior_inspector,
  unit: obstacle_course,
  inspector_company: bounce_safe,
  inspection_date: 1.week.ago,
  inspection_location: "Victoria Park, Manchester",
  unique_report_number: "BSI-2025-#{rand(1000..9999)}",
  status: "completed",
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
log_creation("Inspection", "Failed inspection for #{obstacle_course.name}")

# Historical inspections
[6.months.ago, 1.year.ago].each do |date|
  historical = Inspection.create!(
    user: senior_inspector,
    unit: castle_large,
    inspector_company: bounce_safe,
    inspection_date: date,
    inspection_location: "NEC Birmingham",
    unique_report_number: "BSI-#{date.year}-#{rand(1000..9999)}",
    status: "finalized",
    passed: true,
    comments: "Routine #{date == 1.year.ago ? 'annual' : 'six-month'} inspection.",
    width: castle_large.width,
    length: castle_large.length,
    height: castle_large.height,
    has_slide: castle_large.has_slide,
    is_totally_enclosed: castle_large.is_totally_enclosed,
    inspector_signature: "#{senior_inspector.email.split('@').first.titleize} (Digital Signature)",
    signature_timestamp: date
  )
  create_assessments_for_inspection(historical, castle_large, passed: true)
  log_creation("Inspection", "Historical inspection from #{date.strftime('%B %Y')}")
end

# Draft inspections
draft_inspection = Inspection.create!(
  user: lead_inspector,
  unit: giant_slide,
  inspector_company: bounce_safe,
  inspection_date: Date.current,
  inspection_location: nil,
  status: "draft",
  width: giant_slide.width,
  length: giant_slide.length,
  height: giant_slide.height,
  has_slide: giant_slide.has_slide,
  is_totally_enclosed: giant_slide.is_totally_enclosed
)
log_creation("Inspection", "Draft inspection for #{giant_slide.name}")

# In progress inspection
in_progress = Inspection.create!(
  user: kids_play_inspector,
  unit: gladiator_duel,
  inspector_company: kids_play,
  inspection_date: Date.current,
  inspection_location: "Heaton Park, Manchester",
  status: "in_progress",
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
  low_webbing_ok: true,
  low_karabiner_ok: true,
  low_rope_ok: true
)
log_creation("Inspection", "In-progress inspection for #{gladiator_duel.name}")

# Create more varied inspections
[soft_play_unit, castle_slide_combo, bungee_run].each do |unit|
  inspection = Inspection.create!(
    user: unit.user,
    unit: unit,
    inspector_company: unit.user.inspection_company,
    inspection_date: rand(1..60).days.ago,
    inspection_location: "#{british_address}, #{british_city}",
    unique_report_number: "#{unit.user.inspection_company.name[0..2].upcase}-2025-#{rand(1000..9999)}",
    status: ["completed", "finalized"].sample,
    passed: rand(0..4) > 0, # 80% pass rate
    comments: "Regular inspection completed as scheduled.",
    width: unit.width,
    length: unit.length,
    height: unit.height,
    has_slide: unit.has_slide,
    is_totally_enclosed: unit.is_totally_enclosed
  )
  create_assessments_for_inspection(inspection, unit, passed: inspection.passed)
  log_creation("Inspection", "Inspection for #{unit.name}")
end

Rails.logger.info "\n📊 Seed Data Summary:"
Rails.logger.info "  Inspector Companies: #{InspectorCompany.count}"
Rails.logger.info "  Users: #{User.count}"
Rails.logger.info "  Units: #{Unit.count}"
Rails.logger.info "  Inspections: #{Inspection.count}"
Rails.logger.info "    - Draft: #{Inspection.where(status: 'draft').count}"
Rails.logger.info "    - In Progress: #{Inspection.where(status: 'in_progress').count}"
Rails.logger.info "    - Completed: #{Inspection.where(status: 'completed').count}"
Rails.logger.info "    - Finalized: #{Inspection.where(status: 'finalized').count}"
Rails.logger.info "    - Passed: #{Inspection.where(passed: true).count}"
Rails.logger.info "    - Failed: #{Inspection.where(passed: false).count}"

Rails.logger.info "\n🎉 Seed data creation complete!"
Rails.logger.info "\n📝 Test Credentials:"
Rails.logger.info "  Admin: admin@testlog.com / password123"
Rails.logger.info "  Lead Inspector: lead@bouncesafe.co.uk / password123"
Rails.logger.info "  Other users: password123"