# typed: false

# == Schema Information
#
# Table name: events
#
#  id            :integer          not null, primary key
#  action        :string           not null
#  changed_data  :json
#  details       :text
#  metadata      :json
#  resource_type :string           not null
#  created_at    :datetime         not null
#  resource_id   :string(12)
#  user_id       :string(12)       not null
#
# Indexes
#
#  index_events_on_action                         (action)
#  index_events_on_created_at                     (created_at)
#  index_events_on_resource_type_and_resource_id  (resource_type,resource_id)
#  index_events_on_user_id                        (user_id)
#  index_events_on_user_id_and_created_at         (user_id,created_at)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#

FactoryBot.define do
  factory :event do
    user
    action { "created" }
    resource_type { "Inspection" }
    resource_id { "INS#{SecureRandom.hex(8).upcase}" }
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
