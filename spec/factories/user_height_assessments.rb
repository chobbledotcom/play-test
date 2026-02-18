# typed: false
# frozen_string_literal: true

# == Schema Information
#
# Table name: user_height_assessments
#
#  containing_wall_height         :decimal(8, 2)
#  containing_wall_height_comment :text
#  custom_user_height_comment     :text
#  negative_adjustment            :decimal(8, 2)
#  negative_adjustment_comment    :text
#  play_area_length               :decimal(8, 2)
#  play_area_length_comment       :text
#  play_area_width                :decimal(8, 2)
#  play_area_width_comment        :text
#  users_at_1000mm                :integer
#  users_at_1200mm                :integer
#  users_at_1500mm                :integer
#  users_at_1800mm                :integer
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  inspection_id                  :string(12)       not null, primary key
#
# Indexes
#
#  user_height_assessments_new_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#

FactoryBot.define do
  factory :user_height_assessment, class: "Assessments::UserHeightAssessment" do
    association :inspection

    containing_wall_height { nil }
    users_at_1000mm { nil }
    users_at_1200mm { nil }
    users_at_1500mm { nil }
    users_at_1800mm { nil }
    custom_user_height_comment { nil }
    play_area_length { nil }
    play_area_width { nil }
    negative_adjustment { nil }

    trait :complete do
      containing_wall_height { 1.2 }
      containing_wall_height_comment { "Wall height adequate for age group" }
      play_area_length { 5.0 }
      play_area_length_comment { "Length meets capacity requirements" }
      play_area_width { 4.0 }
      play_area_width_comment { "Width adequate for user count" }
      negative_adjustment { 0.0 }
      negative_adjustment_comment { "No negative adjustments required" }
      users_at_1000mm { 10 }
      users_at_1200mm { 8 }
      users_at_1500mm { 6 }
      users_at_1800mm { 4 }
      custom_user_height_comment { "Custom height notes for testing" }
    end

    trait :incomplete do
      containing_wall_height { nil }
    end

    trait :standard_test_values do
      containing_wall_height { 2.5 }
      users_at_1000mm { 5 }
      users_at_1200mm { 4 }
      users_at_1500mm { 3 }
      users_at_1800mm { 2 }
      custom_user_height_comment { "Standard test height comments" }
      play_area_length { 10.0 }
      play_area_width { 8.0 }
      negative_adjustment { 2.0 }
    end

    trait :with_basic_data do
      containing_wall_height { 1.5 }
      users_at_1000mm { 10 }
      users_at_1200mm { 8 }
      users_at_1500mm { 6 }
      users_at_1800mm { 4 }
      custom_user_height_comment { "Basic height test comments" }
      play_area_length { 5.0 }
      play_area_width { 4.0 }
      negative_adjustment { 0.0 }
    end

    trait :extreme_values do
      containing_wall_height { 999.999999 }
      play_area_length { 999_999.123456 }
      play_area_width { 0.000000001 }
    end

    trait :edge_case_values do
      containing_wall_height { nil }
      users_at_1000mm { nil }
      users_at_1200mm { 0 }
      custom_user_height_comment { nil }
    end
  end
end
