# typed: false

# == Schema Information
#
# Table name: fan_assessments
#
#  id                         :integer          not null
#  blower_finger_comment      :text
#  blower_finger_pass         :boolean
#  blower_flap_comment        :text
#  blower_flap_pass           :integer
#  blower_serial              :string
#  blower_tube_length         :decimal(8, 2)
#  blower_tube_length_comment :text
#  blower_tube_length_pass    :boolean
#  blower_visual_comment      :text
#  blower_visual_pass         :boolean
#  fan_size_type              :text
#  number_of_blowers          :integer
#  pat_comment                :text
#  pat_pass                   :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  inspection_id              :string(8)        not null, primary key
#
# Indexes
#
#  index_fan_assessments_on_inspection_id  (inspection_id)
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#

FactoryBot.define do
  factory :fan_assessment, class: "Assessments::FanAssessment" do
    association :inspection

    # Default to nil for tests to control values
    fan_size_type { nil }
    number_of_blowers { nil }
    blower_flap_pass { nil }
    blower_flap_comment { nil }
    blower_finger_pass { nil }
    blower_finger_comment { nil }
    pat_pass { nil }
    pat_comment { nil }
    blower_visual_pass { nil }
    blower_visual_comment { nil }
    blower_serial { nil }
    blower_tube_length { nil }
    blower_tube_length_pass { nil }
    blower_tube_length_comment { nil }

    trait :passed do
      fan_size_type { SeedData::PASS }
      number_of_blowers { 1 }
      blower_flap_pass { :pass }
      blower_flap_comment { SeedData::PASS }
      blower_finger_pass { true }
      blower_finger_comment { SeedData::PASS }
      pat_pass { :pass }
      pat_comment { SeedData::PASS }
      blower_visual_pass { true }
      blower_visual_comment { SeedData::PASS }
      blower_serial { "BL123456" }
      blower_tube_length { 2.5 }
      blower_tube_length_pass { true }
      blower_tube_length_comment { SeedData::OK }
    end

    trait :complete do
      fan_size_type { SeedData::PASS }
      number_of_blowers { 1 }
      blower_flap_pass { :pass }
      blower_flap_comment { SeedData::PASS }
      blower_finger_pass { true }
      blower_finger_comment { SeedData::PASS }
      pat_pass { :pass }
      pat_comment { SeedData::PASS }
      blower_visual_pass { true }
      blower_visual_comment { SeedData::PASS }
      blower_serial { "BL123456" }
      blower_tube_length { 2.5 }
      blower_tube_length_pass { true }
      blower_tube_length_comment { SeedData::OK }
    end

    trait :failed do
      fan_size_type { SeedData::FAIL }
      number_of_blowers { 2 }
      blower_flap_pass { :fail }
      blower_finger_pass { false }
      pat_pass { :fail }
      blower_visual_pass { false }
      blower_flap_comment { SeedData::FAIL }
      blower_finger_comment { SeedData::FAIL }
      pat_comment { SeedData::FAIL }
      blower_visual_comment { SeedData::WEAR }
      blower_serial { "BL789012" }
      blower_tube_length { 0.5 }
      blower_tube_length_pass { false }
      blower_tube_length_comment { SeedData::FAIL }
    end

    trait :pat_failure do
      pat_pass { :fail }
      pat_comment { SeedData::FAIL }
    end
  end
end
