require_relative "seed_data"

puts "Creating inspections and assessments..."

def create_assessments_for_inspection(inspection, unit, passed: true)
  inspection.each_applicable_assessment do |assessment_key, _, _|
    method_name = :"create_#{assessment_key}"

    if assessment_key == :user_height_assessment
      send(method_name, inspection, unit, passed)
    else
      send(method_name, inspection, passed)
    end
  end
end

def create_anchorage_assessment(inspection, passed)
  inspection.anchorage_assessment.update!(
    SeedData.anchorage_fields(passed: passed)
  )
end

def create_structure_assessment(inspection, passed)
  inspection.structure_assessment.update!(
    SeedData.structure_fields(passed: passed)
  )
end

def create_materials_assessment(inspection, passed)
  inspection.materials_assessment.update!(
    SeedData.materials_fields(passed: passed)
  )
end

def create_fan_assessment(inspection, passed)
  inspection.fan_assessment.update!(
    SeedData.fan_fields(passed: passed)
  )
end

def create_user_height_assessment(inspection, unit, passed)
  inspection.user_height_assessment.update!(
    SeedData.user_height_fields(passed: passed)
  )
end

def create_slide_assessment(inspection, passed)
  inspection.slide_assessment.update!(
    SeedData.slide_fields(passed: passed)
  )
end

def create_enclosed_assessment(inspection, passed)
  inspection.enclosed_assessment.update!(
    SeedData.enclosed_fields(passed: passed)
  )
end

recent_inspection = Inspection.create!(
  SeedData.inspection_fields.merge(
    user: $test_user,
    unit: $castle_standard,
    inspector_company: $stefan_testing,
    inspection_date: 3.days.ago,
    complete_date: Time.current,
    passed: true
  )
)
create_assessments_for_inspection(recent_inspection, $castle_standard, passed: true)

failed_inspection = Inspection.create!(
  SeedData.inspection_fields.merge(
    user: $test_user,
    unit: $obstacle_course,
    inspector_company: $stefan_testing,
    inspection_date: 1.week.ago,
    complete_date: Time.current,
    passed: false,
    risk_assessment: "Safety failures identified. Unit unsafe for use. Risk level: HIGH.",
    width: 3.0,
    length: 12.0,
    height: 3.5,
    has_slide: true
  )
)
create_assessments_for_inspection(failed_inspection, $obstacle_course, passed: false)

[6.months.ago, 1.year.ago].each do |date|
  historical = Inspection.create!(
    SeedData.inspection_fields.merge(
      user: $test_user,
      unit: $castle_large,
      inspector_company: $stefan_testing,
      inspection_date: date,
      complete_date: Time.current,
      passed: true,
      width: 9.0,
      length: 9.0,
      height: 4.5
    )
  )
  create_assessments_for_inspection(historical, $castle_large, passed: true)
end

Inspection.create!(
  SeedData.inspection_fields.merge(
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
    risk_assessment: "Inspection in progress"
  )
)

in_progress = Inspection.create!(
  SeedData.inspection_fields.merge(
    user: $steph_test_inspector,
    unit: $gladiator_duel,
    inspector_company: $steph_test,
    complete_date: nil,
    width: 6.0,
    length: 6.0,
    height: 1.5,
    risk_assessment: "Inspection in progress"
  )
)

Assessments::AnchorageAssessment.create!(
  SeedData.anchorage_fields(passed: true).merge(
    inspection: in_progress,
    num_low_anchors: 8,
    num_high_anchors: 0
  )
)

[$soft_play_unit, $castle_slide_combo, $bungee_run].each do |unit|
  dimensions = case unit
  when $soft_play_unit
    {width: 6.0, length: 6.0, height: 2.5, has_slide: false, is_totally_enclosed: true}
  when $castle_slide_combo
    {width: 5.5, length: 7.0, height: 4.0, has_slide: true, is_totally_enclosed: false}
  when $bungee_run
    {width: 4.0, length: 10.0, height: 2.5, has_slide: false, is_totally_enclosed: false}
  end

  passed_status = rand(0..4) > 0

  inspection = Inspection.create!(
    SeedData.inspection_fields.merge(
      user: $test_user,
      unit: unit,
      inspector_company: $test_user.inspection_company,
      inspection_date: rand(1..60).days.ago,
      complete_date: Time.current,
      passed: passed_status,
      risk_assessment: passed_status ? "Unit inspected and meets all safety requirements. Risk level: LOW." : "Safety failures identified. Unit unsafe for use. Risk level: HIGH.",
      **dimensions
    )
  )
  create_assessments_for_inspection(inspection, unit, passed: inspection.passed)
end

lead_inspection = Inspection.create!(
  SeedData.inspection_fields.merge(
    user: $lead_inspector,
    unit: $castle_standard,
    inspector_company: $stefan_testing,
    inspection_date: 2.months.ago,
    complete_date: Time.current,
    passed: true,
    width: 4.5,
    length: 4.5,
    height: 3.5,
    has_slide: false,
    is_totally_enclosed: false
  )
)
create_assessments_for_inspection(lead_inspection, $castle_standard, passed: true)

complete_inspection = Inspection.create!(
  SeedData.inspection_fields.merge(
    user: $test_user,
    unit: $castle_large,
    inspector_company: $stefan_testing,
    inspection_date: 1.month.ago,
    complete_date: Time.current,
    passed: true,
    width: 9.0,
    length: 9.0,
    height: 4.5,
    has_slide: false,
    is_totally_enclosed: false
  )
)
create_assessments_for_inspection(complete_inspection, $castle_large, passed: true)

complete_inspection.reload

puts "Created #{Inspection.count} inspections with assessments."
