FactoryBot.define do
  factory :structure_assessment, class: "Assessments::StructureAssessment" do
    association :inspection

    # Critical safety checks (defaults to nil for tests to control)
    seam_integrity_pass { nil }
    lock_stitch_pass { nil }
    air_loss_pass { nil }
    straight_walls_pass { nil }
    sharp_edges_pass { nil }
    unit_stable_pass { nil }

    # Measurements
    stitch_length { nil }
    evacuation_time { nil }
    unit_pressure_value { nil }
    blower_tube_length { nil }
    step_size_value { nil }
    fall_off_height_value { nil }
    trough_depth_value { nil }
    trough_width_value { nil }

    # Measurement pass/fail checks
    stitch_length_pass { nil }
    evacuation_time_pass { nil }
    unit_pressure_pass { nil }
    blower_tube_length_pass { nil }
    step_size_pass { nil }
    fall_off_height_pass { nil }
    trough_pass { nil }
    entrapment_pass { nil }
    markings_pass { nil }
    grounding_pass { nil }

    trait :passed do
      seam_integrity_pass { true }
      lock_stitch_pass { true }
      air_loss_pass { true }
      straight_walls_pass { true }
      sharp_edges_pass { true }
      unit_stable_pass { true }
      stitch_length { 15.0 }
      evacuation_time { 30.0 }
      unit_pressure_value { 2.5 }
      blower_tube_length { 1.5 }
      step_size_value { 0.2 }
      fall_off_height_value { 0.6 }
      trough_depth_value { 0.3 }
      trough_width_value { 0.8 }
      stitch_length_pass { true }
      evacuation_time_pass { true }
      unit_pressure_pass { true }
      blower_tube_length_pass { true }
      step_size_pass { true }
      fall_off_height_pass { true }
      trough_pass { true }
      entrapment_pass { true }
      markings_pass { true }
      grounding_pass { true }
    end

    trait :complete do
      seam_integrity_pass { true }
      lock_stitch_pass { true }
      air_loss_pass { true }
      straight_walls_pass { true }
      sharp_edges_pass { true }
      unit_stable_pass { true }
      stitch_length { 15.0 }
      evacuation_time { 30.0 }
      unit_pressure_value { 2.5 }
      blower_tube_length { 1.5 }
      step_size_value { 0.2 }
      fall_off_height_value { 0.6 }
      trough_depth_value { 0.3 }
      trough_width_value { 0.8 }
      stitch_length_pass { true }
      evacuation_time_pass { true }
      unit_pressure_pass { true }
      blower_tube_length_pass { true }
      step_size_pass { true }
      fall_off_height_pass { true }
      trough_pass { true }
      entrapment_pass { true }
      markings_pass { true }
      grounding_pass { true }
      seam_integrity_comment { "Seams in good condition" }
      lock_stitch_comment { "Stitching secure" }
      stitch_length_comment { "Stitch length within specification" }
      air_loss_comment { "No significant air loss detected" }
      straight_walls_comment { "Walls straight and properly tensioned" }
      sharp_edges_comment { "No sharp edges found" }
      blower_tube_length_comment { "Tube length appropriate" }
      unit_stable_comment { "Unit stable during operation" }
      evacuation_time_comment { "Evacuation time acceptable" }
      step_size_comment { "Step size within safety limits" }
      fall_off_height_comment { "Fall-off height appropriate" }
      trough_comment { "Trough dimensions adequate" }
      entrapment_comment { "No entrapment hazards identified" }
      markings_comment { "Markings clear and visible" }
      grounding_comment { "Electrical grounding verified" }
    end

    trait :failed do
      seam_integrity_pass { false }
      lock_stitch_pass { false }
      air_loss_pass { false }
      stitch_length { 10.0 }
      stitch_length_pass { false }
      unit_pressure_value { 1.0 }
      unit_pressure_pass { false }
      evacuation_time { 90.0 }
      evacuation_time_pass { false }
      trough_pass { false }
      entrapment_pass { false }
    end
  end
end
