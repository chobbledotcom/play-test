# == Schema Information
#
# Table name: materials_assessments
#
#  artwork_comment           :text
#  artwork_pass              :integer
#  fabric_strength_comment   :text
#  fabric_strength_pass      :boolean
#  fire_retardant_comment    :text
#  fire_retardant_pass       :boolean
#  retention_netting_comment :text
#  retention_netting_pass    :integer
#  ropes                     :integer
#  ropes_comment             :text
#  ropes_pass                :integer
#  thread_comment            :text
#  thread_pass               :boolean
#  windows_comment           :text
#  windows_pass              :integer
#  zips_comment              :text
#  zips_pass                 :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  inspection_id             :string(12)       not null, primary key
#
# Indexes
#
#  materials_assessments_new_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#

FactoryBot.define do
  factory :materials_assessment, class: "Assessments::MaterialsAssessment" do
    association :inspection

    # Material specifications (defaults to nil for tests to control)
    ropes { nil }
    ropes_pass { nil }

    # Critical material checks
    fabric_strength_pass { nil }
    fire_retardant_pass { nil }
    thread_pass { nil }

    # Additional material checks
    retention_netting_pass { nil }
    zips_pass { nil }
    windows_pass { nil }
    artwork_pass { nil }

    trait :passed do
      ropes { 25 }
      ropes_pass { :pass }
      fabric_strength_pass { true }
      fire_retardant_pass { true }
      thread_pass { true }
      retention_netting_pass { :pass }
      zips_pass { :pass }
      windows_pass { :pass }
      artwork_pass { :pass }
    end

    trait :complete do
      ropes { 25 }
      ropes_pass { :pass }
      fabric_strength_pass { true }
      fire_retardant_pass { true }
      thread_pass { true }
      retention_netting_pass { :pass }
      zips_pass { :pass }
      windows_pass { :pass }
      artwork_pass { :pass }
      ropes_comment { "Rope diameter meets safety standards" }
      fabric_strength_comment { "Fabric in good condition" }
      fire_retardant_comment { "Fire retardant treatment effective" }
      thread_comment { "Thread quality appropriate" }
    end

    trait :failed do
      ropes { 10 }  # Below minimum
      ropes_pass { :fail }
      fabric_strength_pass { false }
      fire_retardant_pass { false }
      thread_pass { false }
      retention_netting_pass { :fail }
    end

    trait :critical_failures do
      fabric_strength_pass { false }
      fire_retardant_pass { false }
      thread_pass { false }
    end

    trait :ropes_na do
      ropes_pass { :na }
    end
  end
end
