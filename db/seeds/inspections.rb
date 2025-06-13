puts "Creating inspections and assessments..."

def create_assessments_for_inspection(inspection, unit, passed: true)
  create_anchorage_assessment(inspection, passed)
  create_structure_assessment(inspection, passed)
  create_materials_assessment(inspection, passed)
  create_fan_assessment(inspection, passed)
  create_user_height_assessment(inspection, unit, passed)
  create_slide_assessment(inspection, passed) if inspection.has_slide
  create_enclosed_assessment(inspection, passed) if inspection.is_totally_enclosed
end

def create_anchorage_assessment(inspection, passed)
  inspection.anchorage_assessment.update!(
    num_low_anchors: rand(6..12),
    num_high_anchors: rand(4..8),
    num_anchors_pass: passed,
    anchor_accessories_pass: passed,
    anchor_degree_pass: passed,
    anchor_type_pass: passed,
    pull_strength_pass: passed,
    anchor_type_comment: passed ? nil : "Some wear visible on anchor points"
  )
end

def create_structure_assessment(inspection, passed)
  inspection.structure_assessment.update!(
    seam_integrity_pass: passed,
    lock_stitch_pass: passed,
    air_loss_pass: passed,
    straight_walls_pass: passed,
    sharp_edges_pass: passed,
    unit_stable_pass: passed,
    stitch_length_pass: passed,
    blower_tube_length_pass: passed,
    step_size_pass: passed,
    fall_off_height_pass: passed,
    unit_pressure_pass: passed,
    trough_pass: passed,
    entrapment_pass: passed,
    markings_pass: passed,
    grounding_pass: passed,
    stitch_length: rand(8..12),
    unit_pressure_value: rand(1.0..3.0).round(1),
    blower_tube_length: rand(2.0..5.0).round(1),
    step_size_value: rand(200..400),
    fall_off_height_value: rand(0.5..2.0).round(1),
    trough_depth_value: rand(0.1..0.5).round(1),
    trough_width_value: rand(0.3..1.0).round(1),
    seam_integrity_comment: passed ? "All seams in good condition" : "Minor thread loosening noted",
    lock_stitch_comment: passed ? "Lock stitching intact throughout" : "Some lock stitching showing wear",
    stitch_length_comment: "Measured at regular intervals"
  )
end

def create_materials_assessment(inspection, passed)
  inspection.materials_assessment.update!(
    ropes: rand(18..45),
    ropes_pass: passed,
    clamber_netting_pass: passed,
    retention_netting_pass: passed,
    zips_pass: passed,
    windows_pass: passed,
    artwork_pass: passed,
    thread_pass: passed,
    fabric_strength_pass: passed,
    fire_retardant_pass: passed,
    ropes_comment: passed ? nil : "Rope shows signs of wear",
    fabric_strength_comment: passed ? "Fabric in good condition" : "Minor surface wear noted"
  )
end

def create_fan_assessment(inspection, passed)
  inspection.fan_assessment.update!(
    blower_flap_pass: passed,
    blower_finger_pass: passed,
    blower_visual_pass: passed,
    pat_pass: passed,
    blower_serial: "FAN-#{rand(1000..9999)}",
    fan_size_type: passed ? "Fan operating correctly at optimal pressure" : "Fan requires servicing",
    blower_flap_comment: passed ? "Flap mechanism functioning correctly" : "Flap sticking occasionally",
    blower_finger_comment: passed ? "Guard secure, no finger trap hazards" : "Guard needs tightening",
    blower_visual_comment: passed ? "Visual inspection satisfactory" : "Some wear visible on housing",
    pat_comment: passed ? "PAT test valid until #{(Date.current + 6.months).strftime("%B %Y")}" : "PAT test overdue"
  )
end

def create_user_height_assessment(inspection, unit, passed)
  inspection.user_height_assessment.update!(
    containing_wall_height: rand(1.0..2.0).round(1),
    platform_height: rand(0.5..1.5).round(1),
    tallest_user_height: rand(1.2..1.8).round(1),
    users_at_1000mm: rand(0..5),
    users_at_1200mm: rand(2..8),
    users_at_1500mm: rand(4..10),
    users_at_1800mm: rand(2..6),
    play_area_length: rand(3.0..10.0).round(1),
    play_area_width: rand(3.0..8.0).round(1),
    negative_adjustment: rand(0..2.0).round(1),
    permanent_roof: false,
    tallest_user_height_comment: passed ? "Capacity within safe limits based on EN 14960:2019" : "Review user capacity - exceeds recommended limits",
    containing_wall_height_comment: "Measured from base to top of wall",
    platform_height_comment: "Platform height acceptable for age group",
    play_area_length_comment: "Effective play area after deducting obstacles",
    play_area_width_comment: "Width measured at narrowest point"
  )
end

def create_slide_assessment(inspection, passed)
  inspection.slide_assessment.update!(
    slide_platform_height: rand(2.0..6.0).round(1),
    slide_wall_height: rand(1.0..2.0).round(1),
    runout: rand(1.5..3.0).round(1),
    slide_first_metre_height: rand(0.3..0.8).round(1),
    slide_beyond_first_metre_height: rand(0.8..1.5).round(1),
    clamber_netting_pass: passed,
    runout_pass: passed,
    slip_sheet_pass: passed,
    slide_permanent_roof: false,
    slide_platform_height_comment: passed ? "Platform height compliant with EN 14960:2019" : "Platform height exceeds recommended limits",
    slide_wall_height_comment: "Wall height measured from slide bed",
    runout_comment: passed ? "Runout area clear and adequate" : "Runout area needs extending",
    clamber_netting_comment: passed ? "Netting secure with no gaps" : "Some gaps in netting need attention",
    slip_sheet_comment: passed ? "Slip sheet in good condition" : "Slip sheet showing wear"
  )
end

def create_enclosed_assessment(inspection, passed)
  inspection.enclosed_assessment.update!(
    exit_number: rand(1..3),
    exit_number_pass: passed,
    exit_sign_always_visible_pass: passed,
    exit_sign_visible_pass: passed,
    exit_number_comment: passed ? "Number of exits compliant with unit size" : "Additional exit required",
    exit_sign_always_visible_comment: passed ? "Exit signs visible from all points" : "Exit signs obscured from some angles",
    exit_sign_visible_comment: passed ? "All exits clearly marked with illuminated signage" : "Exit signage needs improvement - not clearly visible"
  )
end

recent_inspection = Inspection.create!(
  user: $test_user,
  unit: $castle_standard,
  inspector_company: $stefan_testing,
  inspection_date: 3.days.ago,
  inspection_location: "Sutton Park, Birmingham",
  unique_report_number: "STC-2025-#{rand(1000..9999)}",
  complete_date: Time.current,
  passed: true,
  comments: "Annual inspection completed. Unit in excellent condition.",
  recommendations: "Continue regular maintenance schedule.",
  general_notes: "Client very happy with service. Park location had good access.",
  width: 4.5,
  length: 4.5,
  height: 3.5,
  has_slide: false,
  is_totally_enclosed: false
)
create_assessments_for_inspection(recent_inspection, $castle_standard, passed: true)

failed_inspection = Inspection.create!(
  user: $test_user,
  unit: $obstacle_course,
  inspector_company: $stefan_testing,
  inspection_date: 1.week.ago,
  inspection_location: "Victoria Park, Manchester",
  unique_report_number: "STC-2025-#{rand(1000..9999)}",
  complete_date: Time.current,
  passed: false,
  comments: "Several issues identified requiring immediate attention.",
  recommendations: "1. Replace worn anchor straps\n2. Repair seam separation\n3. Reinspect within 30 days",
  general_notes: "Unit owner notified of failures. Removed from service pending repairs.",
  width: 3.0,
  length: 12.0,
  height: 3.5,
  has_slide: true,
  is_totally_enclosed: false
)
create_assessments_for_inspection(failed_inspection, $obstacle_course, passed: false)

[6.months.ago, 1.year.ago].each do |date|
  historical = Inspection.create!(
    user: $test_user,
    unit: $castle_large,
    inspector_company: $stefan_testing,
    inspection_date: date,
    inspection_location: "NEC Birmingham",
    unique_report_number: "STC-#{date.year}-#{rand(1000..9999)}",
    complete_date: Time.current,
    passed: true,
    comments: "Routine #{(date == 1.year.ago) ? "annual" : "six-month"} inspection.",
    width: 9.0,
    length: 9.0,
    height: 4.5,
    has_slide: false,
    is_totally_enclosed: false,
    inspector_signature: "#{$test_user.email.split("@").first.titleize} (Digital Signature)",
    signature_timestamp: date
  )
  create_assessments_for_inspection(historical, $castle_large, passed: true)
end

Inspection.create!(
  user: $test_user,
  unit: $giant_slide,
  inspector_company: $stefan_testing,
  inspection_date: Date.current,
  inspection_location: nil,
  complete_date: nil,
  width: 5.0,
  length: 15.0,
  height: 7.5,
  has_slide: true,
  is_totally_enclosed: false
)

in_progress = Inspection.create!(
  user: $steph_test_inspector,
  unit: $gladiator_duel,
  inspector_company: $steph_test,
  inspection_date: Date.current,
  inspection_location: "Heaton Park, Manchester",
  unique_report_number: "ST-2025-#{rand(1000..9999)}",
  complete_date: nil,
  width: 6.0,
  length: 6.0,
  height: 1.5,
  has_slide: false,
  is_totally_enclosed: false
)

Assessments::AnchorageAssessment.create!(
  inspection: in_progress,
  num_low_anchors: 8,
  num_high_anchors: 0,
  num_anchors_pass: true,
  anchor_accessories_pass: true,
  anchor_degree_pass: true
)

[$soft_play_unit, $castle_slide_combo, $bungee_run].each do |unit|
  case unit
  when $soft_play_unit
    width, length, height = 6.0, 6.0, 2.5
    has_slide = false
    is_totally_enclosed = true
  when $castle_slide_combo
    width, length, height = 5.5, 7.0, 4.0
    has_slide = true
    is_totally_enclosed = false
  when $bungee_run
    width, length, height = 4.0, 10.0, 2.5
    has_slide = false
    is_totally_enclosed = false
  end
  
  inspection = Inspection.create!(
    user: $test_user,
    unit: unit,
    inspector_company: $test_user.inspection_company,
    inspection_date: rand(1..60).days.ago,
    inspection_location: "#{TestDataHelpers.british_address}, #{TestDataHelpers.british_city}",
    unique_report_number: "#{$test_user.inspection_company.name[0..2].upcase}-2025-#{rand(1000..9999)}",
    complete_date: Time.current,
    passed: rand(0..4) > 0,
    comments: "Regular inspection completed as scheduled.",
    width: width,
    length: length,
    height: height,
    has_slide: has_slide,
    is_totally_enclosed: is_totally_enclosed
  )
  create_assessments_for_inspection(inspection, unit, passed: inspection.passed)
end

lead_inspection = Inspection.create!(
  user: $lead_inspector,
  unit: $castle_standard,
  inspector_company: $stefan_testing,
  inspection_date: 2.months.ago,
  inspection_location: "Cannon Hill Park, Birmingham",
  unique_report_number: "STC-2024-#{rand(1000..9999)}",
  complete_date: Time.current,
  passed: true,
  comments: "Six-month inspection completed.",
  width: 4.5,
  length: 4.5,
  height: 3.5,
  has_slide: false,
  is_totally_enclosed: false
)
create_assessments_for_inspection(lead_inspection, $castle_standard, passed: true)

complete_inspection = Inspection.create!(
  user: $test_user,
  unit: $castle_large,
  inspector_company: $stefan_testing,
  inspection_date: 1.month.ago,
  inspection_location: "Alexander Stadium, Birmingham",
  unique_report_number: "STC-2025-#{rand(1000..9999)}",
  complete_date: Time.current,
  passed: true,
  comments: "Annual safety inspection completed. All checks passed.",
  recommendations: "No issues found. Continue standard maintenance.",
  general_notes: "Unit used for major event. Excellent condition maintained.",
  width: 9.0,
  length: 9.0,
  height: 4.5,
  has_slide: false,
  is_totally_enclosed: false,
  inspector_signature: "Test User (Digital Signature)",
  signature_timestamp: 1.month.ago
)
create_assessments_for_inspection(complete_inspection, $castle_large, passed: true)

complete_inspection.reload

puts "Created #{Inspection.count} inspections with assessments."