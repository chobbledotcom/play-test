FactoryBot.define do
  factory :inspection do
    association :user
    association :unit, factory: :unit

    # Always use the user's inspection company
    inspector_company { user.inspection_company }

    inspection_location { "Test Location" }
    passed { true }
    inspection_date { Date.current }
    comments { "Test inspection comments" }
    sequence(:unique_report_number) { |n| "RPII-#{Date.current.strftime("%Y%m%d")}-#{n.to_s.rjust(4, "0")}" }
    status { "draft" }

    trait :passed do
      passed { true }
    end

    trait :failed do
      passed { false }
    end

    trait :complete do
      status { "complete" }
    end

    trait :completed do
      status { "complete" }
    end

    trait :draft do
      status { "draft" }
    end

    trait :overdue do
      inspection_date { Date.current - 1.year - 1.month }
    end

    trait :future_inspection do
      inspection_date { Date.current + 1.week }
    end

    trait :with_unicode_data do
      inspection_location { "Meeting Room 🏢 3F" }
      comments { "❗️Tested with special 🔌 adapter. Result: ✅" }
      association :unit, factory: [:unit, :with_unicode_serial]
    end

    trait :sql_injection_test do
      inspection_location { "Location'); UPDATE users SET admin=true; --" }
    end

    trait :max_length_comments do
      comments { "A" * 65535 }
    end
  end
end
