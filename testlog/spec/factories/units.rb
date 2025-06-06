FactoryBot.define do
  factory :unit do
    association :user
    sequence(:name) { |n| "Test Unit #{n}" }
    sequence(:serial) { |n| "TEST#{n.to_s.rjust(3, "0")}" }
    description { "Test Bounce House" }
    manufacturer { "Test Manufacturer" }
    unit_type { "bounce_house" }
    owner { "Test Owner" }
    width { 10.0 }
    length { 10.0 }
    height { 3.0 }
    model { "Test Model" }
    manufacture_date { 1.year.ago }
    notes { "Test notes" }

    trait :slide do
      unit_type { "slide" }
      description { "Test Slide" }
      width { 3.0 }
      length { 8.0 }
      height { 2.0 }
    end

    trait :combo_unit do
      unit_type { "combo_unit" }
      description { "Test Combo Unit" }
      width { 6.0 }
      length { 5.0 }
      height { 4.0 }
    end

    trait :totally_enclosed do
      unit_type { "totally_enclosed" }
      description { "Test Totally Enclosed Unit" }
    end

    trait :obstacle_course do
      unit_type { "obstacle_course" }
      description { "Test Obstacle Course" }
      width { 10.0 }
      length { 3.0 }
      height { 2.5 }
    end

    trait :large do
      width { 10.0 }
      length { 8.0 }
      height { 5.0 }
    end

    trait :small do
      width { 2.0 }
      length { 2.0 }
      height { 1.5 }
    end

    trait :with_unicode_serial do
      sequence(:serial) { |n| "ÜNICØDÉ-😎-#{n}" }
    end
  end
end
