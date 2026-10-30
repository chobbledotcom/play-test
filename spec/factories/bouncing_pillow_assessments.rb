# typed: false

FactoryBot.define do
  factory :bouncing_pillow_assessment,
    class: "Assessments::BouncingPillowAssessment" do
    association :inspection

    trait :complete do
      security_of_seams_pass { "pass" }
      air_loss_points_pass { "pass" }
      foundation_pass { "pass" }
      gradient_average_pass { "pass" }
      fabric_fr_pass { "pass" }
      fabric_strength_pass { "pass" }
      internal_pressure_pass { "pass" }
      grounding_pass { "pass" }
      deflation_evacuation_time_pass { "pass" }
      artwork_pass { "pass" }
      identification_pass { "pass" }
      slope_pass { "pass" }
      clear_area_pass { "pass" }
      headroom_pass { "pass" }
      hard_objects_pass { "pass" }
      depth_of_impact_attenuation_pass { "pass" }
      signage_pass { "pass" }
      number_of_users_pass { "pass" }
      fencing_distance_pass { "pass" }
      fencing_height_pass { "pass" }
      fencing_strength_pass { "pass" }
      fencing_visibility_pass { "pass" }
      fencing_entrapment_pass { "pass" }
      fencing_gateways_pass { "pass" }
      gradient_average { 12.6 }
      internal_pressure { 0.43 }
      deflation_evacuation_time { 18 }
      slope { 4.5 }
      clear_area { 2.1 }
      depth_of_impact_attenuation { 11 }
      number_of_users { 22 }
      fencing_distance { 2.3 }
      fencing_height { 0.9 }
      fencing_gateways { 2 }
    end

    trait :passed do
      complete
    end
  end
end
