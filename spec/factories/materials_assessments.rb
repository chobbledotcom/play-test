FactoryBot.define do
  factory :materials_assessment, class: "Assessments::MaterialsAssessment" do
    association :inspection

    # Material specifications (defaults to nil for tests to control)
    ropes { nil }
    ropes_pass { nil }

    # Critical material checks
    fabric_strength_pass { nil }
    fire_retardant_pass { nil }
    thread_pass { nil }

    # Additional material checks
    clamber_netting_pass { nil }
    retention_netting_pass { nil }
    zips_pass { nil }
    windows_pass { nil }
    artwork_pass { nil }

    trait :passed do
      ropes { 25.0 }
      ropes_pass { true }
      fabric_strength_pass { true }
      fire_retardant_pass { true }
      thread_pass { true }
      clamber_netting_pass { true }
      retention_netting_pass { true }
      zips_pass { true }
      windows_pass { true }
      artwork_pass { true }
    end

    trait :complete do
      ropes { 25.0 }
      ropes_pass { true }
      fabric_strength_pass { true }
      fire_retardant_pass { true }
      thread_pass { true }
      clamber_netting_pass { true }
      retention_netting_pass { true }
      zips_pass { true }
      windows_pass { true }
      artwork_pass { true }
      ropes_comment { "Rope diameter meets safety standards" }
      fabric_strength_comment { "Fabric in good condition" }
      fire_retardant_comment { "Fire retardant treatment effective" }
      thread_comment { "Thread quality appropriate" }
    end

    trait :failed do
      ropes { 10.0 }  # Below minimum
      ropes_pass { false }
      fabric_strength_pass { false }
      fire_retardant_pass { false }
      thread_pass { false }
      clamber_netting_pass { false }
      retention_netting_pass { false }
    end

    trait :critical_failures do
      fabric_strength_pass { false }
      fire_retardant_pass { false }
      thread_pass { false }
    end
  end
end