# == Schema Information
#
# Table name: fan_assessments
#
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
#  inspection_id              :string(12)       not null, primary key
#
# Indexes
#
#  fan_assessments_new_pkey  (inspection_id) UNIQUE
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
      fan_size_type { "2HP blower" }
      number_of_blowers { 1 }
      blower_flap_pass { :pass }
      blower_flap_comment { "Flap opens and closes properly" }
      blower_finger_pass { true }
      blower_finger_comment { "Finger guards in place and secure" }
      pat_pass { :pass }
      pat_comment { "PAT test completed successfully" }
      blower_visual_pass { true }
      blower_visual_comment { "Visual inspection shows good condition" }
      blower_serial { "BL123456" }
      blower_tube_length { 2.5 }
      blower_tube_length_pass { true }
      blower_tube_length_comment { "Tube length appropriate" }
    end

    trait :complete do
      fan_size_type { "2HP blower" }
      number_of_blowers { 1 }
      blower_flap_pass { :pass }
      blower_flap_comment { "Flap opens and closes properly" }
      blower_finger_pass { true }
      blower_finger_comment { "Finger guards in place and secure" }
      pat_pass { :pass }
      pat_comment { "PAT test completed successfully" }
      blower_visual_pass { true }
      blower_visual_comment { "Visual inspection shows good condition" }
      blower_serial { "BL123456" }
      blower_tube_length { 2.5 }
      blower_tube_length_pass { true }
      blower_tube_length_comment { "Tube length appropriate" }
    end

    trait :failed do
      fan_size_type { "2HP blower - safety issues identified" }
      number_of_blowers { 2 }
      blower_flap_pass { :fail }
      blower_finger_pass { false }
      pat_pass { :fail }
      blower_visual_pass { false }
      blower_flap_comment { "Flap does not open properly" }
      blower_finger_comment { "Finger guards damaged" }
      pat_comment { "PAT test failed" }
      blower_visual_comment { "Visible damage to housing" }
      blower_serial { "BL789012" }
      blower_tube_length { 0.5 }
      blower_tube_length_pass { false }
      blower_tube_length_comment { "Tube length too short" }
    end

    trait :pat_failure do
      pat_pass { :fail }
      pat_comment { "Electrical safety test failed - attention required" }
    end
  end
end
