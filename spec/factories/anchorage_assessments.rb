# typed: false

# == Schema Information
#
# Table name: anchorage_assessments
#
#  anchor_accessories_comment :text
#  anchor_accessories_pass    :boolean
#  anchor_degree_comment      :text
#  anchor_degree_pass         :boolean
#  anchor_type_comment        :text
#  anchor_type_pass           :boolean
#  num_high_anchors           :integer
#  num_high_anchors_comment   :text
#  num_high_anchors_pass      :boolean
#  num_low_anchors            :integer
#  num_low_anchors_comment    :text
#  num_low_anchors_pass       :boolean
#  pull_strength_comment      :text
#  pull_strength_pass         :boolean
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  inspection_id              :string(12)       not null, primary key
#
# Indexes
#
#  anchorage_assessments_new_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#

FactoryBot.define do
  factory :anchorage_assessment, class: "Assessments::AnchorageAssessment" do
    association :inspection

    # Anchor counts (defaults to nil for tests to control)
    num_low_anchors { nil }
    num_high_anchors { nil }

    # Pass/fail assessments
    num_low_anchors_pass { nil }
    num_high_anchors_pass { nil }
    anchor_type_pass { nil }
    pull_strength_pass { nil }
    anchor_degree_pass { nil }
    anchor_accessories_pass { nil }

    trait :passed do
      bungee_side_area { 20 }
      num_low_anchors { 6 }
      num_high_anchors { 4 }
      num_low_anchors_pass { "pass" }
      num_high_anchors_pass { "pass" }
      anchor_type_pass { "pass" }
      pull_strength_pass { "pass" }
      anchor_degree_pass { "pass" }
      anchor_accessories_pass { "pass" }
    end

    trait :complete do
      bungee_side_area { 20 }
      num_low_anchors { 6 }
      num_high_anchors { 4 }
      num_low_anchors_pass { "pass" }
      num_high_anchors_pass { "pass" }
      anchor_type_pass { "pass" }
      pull_strength_pass { "pass" }
      anchor_degree_pass { "pass" }
      anchor_accessories_pass { "pass" }
      num_low_anchors_comment { SeedData::OK }
      num_high_anchors_comment { SeedData::OK }
      anchor_type_comment { SeedData::OK }
      pull_strength_comment { SeedData::PASS }
      anchor_degree_comment { SeedData::OK }
      anchor_accessories_comment { SeedData::PASS }
    end

    trait :failed do
      num_low_anchors { 2 }
      num_high_anchors { 1 }
      num_low_anchors_pass { "fail" }
      num_high_anchors_pass { "fail" }
      anchor_type_pass { "fail" }
      pull_strength_pass { "fail" }
      anchor_degree_pass { "pass" }
      anchor_accessories_pass { "pass" }
    end

    trait :critical_failures do
      anchor_type_pass { "fail" }
      pull_strength_pass { "fail" }
    end

    trait :insufficient_anchors do
      num_low_anchors { 1 }
      num_high_anchors { 1 }
      num_low_anchors_pass { "fail" }
      num_high_anchors_pass { "fail" }
    end
  end
end
