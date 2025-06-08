FactoryBot.define do
  factory :unit do
    association :user
    sequence(:name) { |n| "Test Unit #{n}" }
    sequence(:serial) { |n| "TEST#{n.to_s.rjust(3, "0")}" }
    description { "Test Bounce House" }
    manufacturer { "Test Manufacturer" }
    has_slide { false }
    owner { "Test Owner" }
    width { 10.0 }
    length { 10.0 }
    height { 3.0 }
    model { "Test Model" }
    manufacture_date { 1.year.ago }
    notes { "Test notes" }

    trait :with_slide do
      has_slide { true }
      description { "Test Unit with Slide" }
      width { 3.0 }
      length { 8.0 }
      height { 2.0 }
    end

    trait :totally_enclosed do
      is_totally_enclosed { true }
      description { "Test Totally Enclosed Unit" }
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
