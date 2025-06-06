FactoryBot.define do
  factory :inspection do
    association :user
    association :unit, factory: :unit
    association :inspector_company, factory: :inspector_company

    inspector { "Test Inspector" }
    location { "Test Location" }
    passed { true }
    inspection_date { Date.current }
    reinspection_date { Date.current + 1.year }
    comments { "Test inspection comments" }
    place_inspected { "Test Place" }
    inspection_company_name { "Test Inspection Company" }
    rpii_registration_number { "RPII123" }
    sequence(:unique_report_number) { |n| "RPII-#{Date.current.strftime("%Y%m%d")}-#{n.to_s.rjust(4, "0")}" }
    status { "draft" }

    trait :passed do
      passed { true }
    end

    trait :failed do
      passed { false }
    end

    trait :in_progress do
      status { "in_progress" }
    end

    trait :completed do
      status { "completed" }
    end

    trait :finalized do
      status { "finalized" }
      finalized_at { Time.current }
    end

    trait :overdue do
      reinspection_date { Date.current - 1.month }
    end

    trait :future_inspection do
      inspection_date { Date.current + 1.week }
      reinspection_date { Date.current + 1.year + 1.week }
    end

    trait :with_unicode_data do
      inspector { "Jörgen Müller 👨‍🔧" }
      location { "Meeting Room 🏢 3F" }
      comments { "❗️Tested with special 🔌 adapter. Result: ✅" }
      association :unit, factory: [:unit, :with_unicode_serial]
    end

    trait :sql_injection_test do
      inspector { "Robert'); DROP TABLE inspections; --" }
      location { "Location'); UPDATE users SET admin=true; --" }
    end

    trait :max_length_comments do
      comments { "A" * 65535 }
    end
  end
end
