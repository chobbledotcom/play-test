FactoryBot.define do
  factory :event do
    user
    action { "created" }
    resource_type { "Inspection" }
    resource_id { "INS#{rand(100000)}" }
    details { "Created inspection" }
    changed_data { nil }
    metadata { nil }

    trait :with_changes do
      action { "updated" }
      changed_data { {status: ["draft", "complete"]} }
    end

    trait :system_event do
      resource_type { "System" }
      resource_id { nil }
      action { "login" }
      details { "User logged in" }
    end

    trait :download_event do
      action { "downloaded" }
      metadata { {format: "pdf", filename: "inspection_INS123.pdf"} }
    end
  end
end
