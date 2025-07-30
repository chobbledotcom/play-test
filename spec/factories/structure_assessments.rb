FactoryBot.define do
  factory :structure_assessment, class: "Assessments::StructureAssessment" do
    association :inspection

    # Helper to set all critical safety checks
    transient do
      critical_checks_pass { nil }
      measurement_checks_pass { nil }
      additional_checks_pass { nil }
    end

    # Set critical safety checks based on transient attribute
    after(:build) do |assessment, evaluator|
      if evaluator.critical_checks_pass == true
        %w[seam_integrity_pass air_loss_pass
          straight_walls_pass sharp_edges_pass unit_stable_pass].each do |check|
          assessment.send("#{check}=", true)
        end
      elsif evaluator.critical_checks_pass == false
        %w[seam_integrity_pass air_loss_pass].each do |check|
          assessment.send("#{check}=", false)
        end
      end

      if evaluator.measurement_checks_pass == true
        %w[
          stitch_length_pass evacuation_time_pass unit_pressure_pass
          blower_tube_length_pass step_ramp_size_pass platform_height_pass
          critical_fall_off_height_pass
        ].each do |check|
          assessment.send("#{check}=", true)
        end
      elsif evaluator.measurement_checks_pass == false
        %w[
          stitch_length_pass unit_pressure_pass evacuation_time_pass
        ].each do |check|
          assessment.send("#{check}=", false)
        end
      end

      if evaluator.additional_checks_pass == true
        %w[
          trough_pass entrapment_pass markings_pass grounding_pass
        ].each do |check|
          assessment.send("#{check}=", true)
        end
      elsif evaluator.additional_checks_pass == false
        %w[trough_pass entrapment_pass].each do |check|
          assessment.send("#{check}=", false)
        end
      end
    end

    trait :passed do
      # Critical safety checks
      seam_integrity_pass { true }
      air_loss_pass { true }
      straight_walls_pass { true }
      sharp_edges_pass { true }
      unit_stable_pass { true }

      # Measurements with passing values
      unit_pressure { 2.5 }
      blower_tube_length { 1.5 }
      step_ramp_size { 200 }
      platform_height { 1000 }
      critical_fall_off_height { 600 }
      trough_depth { 300 }
      trough_adjacent_panel_width { 800 }

      # Measurement pass/fail checks
      stitch_length_pass { true }
      evacuation_time_pass { true }
      unit_pressure_pass { true }
      blower_tube_length_pass { true }
      step_ramp_size_pass { true }
      platform_height_pass { true }
      critical_fall_off_height_pass { true }

      # Additional checks
      trough_pass { true }
      entrapment_pass { true }
      markings_pass { true }
      grounding_pass { true }
    end

    trait :complete do
      passed

      # Additional complete-only fields
      trough_adjacent_panel_width { 800 }
      step_ramp_size { 300 }
      step_ramp_size_pass { true }

      # Comments for documentation
      seam_integrity_comment { "Seams in good condition" }
      stitch_length_comment { "Stitch length within specification" }
      air_loss_comment { "No significant air loss detected" }
      straight_walls_comment { "Walls straight and properly tensioned" }
      sharp_edges_comment { "No sharp edges found" }
      blower_tube_length_comment { "Tube length appropriate" }
      unit_stable_comment { "Unit stable during operation" }
      step_ramp_size_comment { "Step size within safety limits" }
      platform_height_comment { "Platform height meets standards" }
      critical_fall_off_height_comment { "Fall-off height appropriate" }
      trough_comment { "Trough dimensions adequate" }
      entrapment_comment { "No entrapment hazards identified" }
      markings_comment { "Markings clear and visible" }
      grounding_comment { "Electrical grounding verified" }
    end

    trait :failed do
      critical_checks_pass { false }
      measurement_checks_pass { false }
      additional_checks_pass { false }

      # Failing measurement values
      unit_pressure { 1.0 }
    end
  end
end
