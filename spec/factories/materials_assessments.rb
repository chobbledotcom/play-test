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
    retention_netting_pass { nil }
    zips_pass { nil }
    windows_pass { nil }
    artwork_pass { nil }

    trait :passed do
      ropes { 25.0 }
      ropes_pass { :pass }
      fabric_strength_pass { true }
      fire_retardant_pass { true }
      thread_pass { true }
      retention_netting_pass { :pass }
      zips_pass { :pass }
      windows_pass { :pass }
      artwork_pass { :pass }
    end

    trait :complete do
      ropes { 25.0 }
      ropes_pass { :pass }
      fabric_strength_pass { true }
      fire_retardant_pass { true }
      thread_pass { true }
      retention_netting_pass { :pass }
      zips_pass { :pass }
      windows_pass { :pass }
      artwork_pass { :pass }
      ropes_comment { "Rope diameter meets safety standards" }
      fabric_strength_comment { "Fabric in good condition" }
      fire_retardant_comment { "Fire retardant treatment effective" }
      thread_comment { "Thread quality appropriate" }
    end

    trait :failed do
      ropes { 10.0 }  # Below minimum
      ropes_pass { :fail }
      fabric_strength_pass { false }
      fire_retardant_pass { false }
      thread_pass { false }
      retention_netting_pass { :fail }
    end

    trait :critical_failures do
      fabric_strength_pass { false }
      fire_retardant_pass { false }
      thread_pass { false }
    end

    trait :ropes_na do
      ropes_pass { :na }
    end
  end
end
