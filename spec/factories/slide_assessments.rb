FactoryBot.define do
  factory :slide_assessment, class: "Assessments::SlideAssessment" do
    association :inspection

    # Minimal defaults to allow tests to control values
    slide_platform_height { nil }
    slide_wall_height { nil }
    runout { nil }
    slide_first_metre_height { nil }
    slide_beyond_first_metre_height { nil }
    clamber_netting_pass { nil }
    runout_pass { nil }
    slip_sheet_pass { nil }

    trait :complete do
      slide_platform_height { 2.0 }
      slide_wall_height { 1.8 }
      runout { 3.0 }
      slide_first_metre_height { 0.5 }
      slide_beyond_first_metre_height { 0.3 }
      slide_permanent_roof { false }
      clamber_netting_pass { :pass }
      runout_pass { true }
      slip_sheet_pass { true }
      slide_platform_height_comment { "Platform height appropriate for age group" }
      slide_wall_height_comment { "Wall height meets safety requirements" }
      slide_first_metre_height_comment { "First metre height compliant" }
      slide_beyond_first_metre_height_comment { "Height beyond first metre appropriate" }
      slide_permanent_roof_comment { "Roof structure evaluated" }
      clamber_netting_comment { "Netting in good condition" }
      runout_comment { "Runout distance adequate" }
      slip_sheet_comment { "Slip sheet properly installed" }
    end

    trait :failed do
      clamber_netting_pass { :fail }
      runout_pass { false }
    end

    trait :incomplete do
      slide_platform_height { nil }
      runout { nil }
    end
  end
end
