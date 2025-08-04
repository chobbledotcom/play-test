FactoryBot.define do
  factory :event, class: "ChobbleApp::Event" do
    user
    action { "created" }
    resource_type { "Page" }
    resource_id { "PAGE#{rand(100000)}" }
    details { "Created page" }
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
      metadata { {format: "pdf", filename: "page_PAGE123.pdf"} }
    end
  end
end
