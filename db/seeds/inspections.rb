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
    uses_lock_stitching_pass: passed,
    air_loss_pass: passed,
    straight_walls_pass: passed,
    sharp_edges_pass: passed,
    unit_stable_pass: passed,
    stitch_length_pass: passed,
    blower_tube_length_pass: passed,
    step_ramp_size_pass: passed,
    critical_fall_off_height_pass: passed,
    unit_pressure_pass: passed,
    trough_pass: passed,
    entrapment_pass: passed,
    markings_pass: passed,
    grounding_pass: passed,
    stitch_length: rand(8..12),
    unit_pressure: rand(1.0..3.0).round(1),
    blower_tube_length: rand(2.0..5.0).round(1),
    step_ramp_size: rand(200..400),
    critical_fall_off_height: rand(0.5..2.0).round(1),
    trough_depth: rand(0.1..0.5).round(1),
    trough_adjacent_panel_width: rand(0.3..1.0).round(1),
    evacuation_time: rand(30..90),
    evacuation_time_pass: passed,
    seam_integrity_comment: passed ? "All seams in good condition" : "Minor thread loosening noted",
    uses_lock_stitching_comment: passed ? "Lock stitching intact throughout" : "Some lock stitching showing wear",
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
  risk_assessment: "Comprehensive annual inspection completed at Sutton Park location. Unit demonstrates excellent condition across all safety parameters. Fabric integrity maintained at 100%, all seams secure with proper double stitching. Inflation system performing optimally with consistent pressure throughout structure. Anchoring points show no signs of wear or stress. Safety signage clearly visible and legible. Emergency exits unobstructed and functioning correctly. Risk level: LOW. Unit certified safe for continued public use for next 12 months.",
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
  risk_assessment: "CRITICAL SAFETY FAILURES IDENTIFIED. Unit presents immediate danger to users. Major structural defects found: (1) Large tear in slide section measuring 45cm, exposing internal framework. (2) Blower motor showing signs of electrical damage with exposed wiring. (3) Multiple anchor points have pulled free from base. (4) Significant UV degradation throughout fabric causing brittleness. (5) Emergency exit zips non-functional. Risk level: SEVERE. Unit must be immediately withdrawn from all use. Do not operate under any circumstances until comprehensive repairs completed and unit re-certified.",
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
    width: 9.0,
    length: 9.0,
    height: 4.5,
    has_slide: false,
    is_totally_enclosed: false,
    risk_assessment: (date == 1.year.ago) ?
      "Annual inspection completed. Unit in satisfactory condition with minor wear noted on entry/exit points. All repairs from previous inspection holding well. Blower system maintenance performed. Risk: LOW." :
      "Six-month interim inspection. Unit performing well under heavy commercial use. Slight fading to artwork but purely cosmetic. All safety systems operational. Recommend continued monitoring of high-traffic areas. Risk: LOW."
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
  is_totally_enclosed: false,
  risk_assessment: "Inspection in progress. Initial observations: Unit appears to be in operational condition. Slide surface smooth with no visible tears. Climb access shows normal wear patterns. Full assessment pending completion of all safety checks per EN 14960:2019 guidelines."
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
  is_totally_enclosed: false,
  risk_assessment: "Partial inspection completed. Gladiator pedestals checked for stability - all secure. Foam batons inspected for damage - minor surface wear only. Awaiting full structural assessment and blower system check before final risk determination."
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

  passed_status = rand(0..4) > 0
  risk_text = case unit
  when $soft_play_unit
    if passed_status
      "Enclosed soft play area inspected per EN 14960:2019 requirements. Internal padding intact with no exposed hard surfaces. Entry/exit mechanisms functioning correctly. Ventilation adequate. Fire retardant certification current. Risk level: LOW. Safe for supervised play."
    else
      "SAFETY ALERT: Multiple ventilation panels blocked reducing airflow below minimum requirements. Exit door mechanism jammed in testing. Internal netting has large tears creating entanglement hazards. Risk level: HIGH. Unit requires immediate maintenance before use."
    end
  when $castle_slide_combo
    if passed_status
      "Combination unit thoroughly tested. Castle section shows minimal wear. Slide integration secure with proper transition padding. All climb elements within safe reach distances. Blower maintains consistent pressure across both sections. Risk level: LOW. Unit meets all safety standards."
    else
      "Significant concerns identified: Slide attachment showing stress cracks at junction points. Step heights exceed EN 14960:2019 maximum allowances. Platform barrier height insufficient for slide height. Risk level: HIGH. Repairs required before returning to service."
    end
  when $bungee_run
    if passed_status
      "Bungee run lanes inspected - both tracks clear and level. Harness attachment points load tested to 5kN without issue. Bungee cords show appropriate elasticity. End cushioning adequate. Lane divider secure. Risk level: LOW. Suitable for continued operation with standard supervision."
    else
      "CRITICAL DEFECTS: Left lane bungee cord fraying with exposed core fibres. Harness clips showing metal fatigue. Centre divider partially detached creating trip hazard. End wall cushioning compressed beyond safe limits. Risk level: SEVERE. DO NOT USE until full refurbishment completed."
    end
  else
    passed_status ? "Unit inspected and meets safety requirements. Risk: LOW." : "Safety failures identified. Unit unsafe for use. Risk: HIGH."
  end

  inspection = Inspection.create!(
    user: $test_user,
    unit: unit,
    inspector_company: $test_user.inspection_company,
    inspection_date: rand(1..60).days.ago,
    inspection_location: "#{TestDataHelpers.british_address}, #{TestDataHelpers.british_city}",
    unique_report_number: "#{$test_user.inspection_company.name[0..2].upcase}-2025-#{rand(1000..9999)}",
    complete_date: Time.current,
    passed: passed_status,
    width: width,
    length: length,
    height: height,
    has_slide: has_slide,
    is_totally_enclosed: is_totally_enclosed,
    risk_assessment: risk_text
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
  width: 4.5,
  length: 4.5,
  height: 3.5,
  has_slide: false,
  is_totally_enclosed: false,
  risk_assessment: "Standard castle unit inspection complete. All structural elements sound. Base perimeter stitching intact. Turrets properly inflated and stable. Artwork vibrant with no UV damage. Meets all EN 14960:2019 requirements for units under 4m platform height. Risk level: LOW. Approved for public use."
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
  width: 9.0,
  length: 9.0,
  height: 4.5,
  has_slide: false,
  is_totally_enclosed: false,
  risk_assessment: "Large commercial castle fully inspected. Enhanced anchoring system verified for high-wind conditions. All 16 anchor points tested. Double-skin construction maintains excellent pressure distribution. Safety padding on all potential impact zones. Electrical systems PAT tested and certified. Unit exceeds safety requirements for high-volume commercial use. Risk level: LOW."
)
create_assessments_for_inspection(complete_inspection, $castle_large, passed: true)

complete_inspection.reload

puts "Created #{Inspection.count} inspections with assessments."
