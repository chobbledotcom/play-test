FactoryBot.define do
  factory :fan_assessment, class: "Assessments::FanAssessment" do
    association :inspection

    # Default to nil for tests to control values
    fan_size_type { nil }
    blower_flap_pass { nil }
    blower_flap_comment { nil }
    blower_finger_pass { nil }
    blower_finger_comment { nil }
    pat_pass { nil }
    pat_comment { nil }
    blower_visual_pass { nil }
    blower_visual_comment { nil }
    blower_serial { nil }

    trait :passed do
      fan_size_type { "Standard 2HP blower" }
      blower_flap_pass { :pass }
      blower_flap_comment { "Flap opens and closes properly" }
      blower_finger_pass { true }
      blower_finger_comment { "Finger guards in place and secure" }
      pat_pass { :pass }
      pat_comment { "PAT test completed successfully" }
      blower_visual_pass { true }
      blower_visual_comment { "Visual inspection shows good condition" }
      blower_serial { "BL123456" }
    end

    trait :complete do
      fan_size_type { "Standard 2HP blower" }
      blower_serial_pass { true }
      blower_serial_comment { "Serial number verified" }
      blower_flap_pass { :pass }
      blower_flap_comment { "Flap opens and closes properly" }
      blower_finger_pass { true }
      blower_finger_comment { "Finger guards in place and secure" }
      pat_pass { :pass }
      pat_comment { "PAT test completed successfully" }
      blower_visual_pass { true }
      blower_visual_comment { "Visual inspection shows good condition" }
      blower_serial { "BL123456" }
    end

    trait :failed do
      fan_size_type { "2HP blower - safety issues identified" }
      blower_flap_pass { :fail }
      blower_finger_pass { false }
      pat_pass { :fail }
      blower_visual_pass { false }
      blower_flap_comment { "Flap does not open properly" }
      blower_finger_comment { "Finger guards damaged" }
      pat_comment { "PAT test failed" }
      blower_visual_comment { "Visible damage to housing" }
      blower_serial { "BL789012" }
    end

    trait :pat_failure do
      pat_pass { :fail }
      pat_comment { "Electrical safety test failed - attention required" }
    end
  end
end
