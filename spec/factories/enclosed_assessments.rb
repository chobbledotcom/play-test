# == Schema Information
#
# Table name: enclosed_assessments
#
#  exit_number                      :integer
#  exit_number_comment              :text
#  exit_number_pass                 :boolean
#  exit_sign_always_visible_comment :text
#  exit_sign_always_visible_pass    :boolean
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  inspection_id                    :string(12)       not null, primary key
#
# Indexes
#
#  enclosed_assessments_new_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#

FactoryBot.define do
  factory :enclosed_assessment, class: "Assessments::EnclosedAssessment" do
    association :inspection

    exit_number { 2 }
    exit_number_pass { true }
    exit_number_comment { "Adequate emergency exits" }
    exit_sign_always_visible_pass { true }
    exit_sign_always_visible_comment { "Exits clearly marked and visible" }

    trait :complete do
      exit_number { 2 }
      exit_number_pass { true }
      exit_sign_always_visible_pass { true }
      exit_number_comment { "Adequate emergency exits" }
      exit_sign_always_visible_comment { "Exits clearly marked and visible" }
    end

    trait :failed do
      exit_number { 1 }  # Still a valid number, but assessment failed
      exit_number_pass { false }
      exit_sign_always_visible_pass { false }
      exit_number_comment { "Insufficient emergency exits for occupancy" }
      exit_sign_always_visible_comment { "Exits not clearly marked" }
    end
  end
end
