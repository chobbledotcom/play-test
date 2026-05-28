# typed: false

# == Schema Information
#
# Table name: inflatable_game_assessments
#
#  age_range_marking_comment             :text
#  age_range_marking_pass                :boolean
#  ancillary_equipment_comment           :text
#  ancillary_equipment_compliant_comment :text
#  ancillary_equipment_compliant_pass    :boolean
#  ancillary_equipment_pass              :boolean
#  constant_air_flow_comment             :text
#  constant_air_flow_pass                :boolean
#  containing_wall_height                :decimal(8, 2)
#  containing_wall_height_comment        :text
#  containing_wall_height_pass           :boolean
#  design_risk_comment                   :text
#  design_risk_pass                      :boolean
#  game_type                             :text
#  intended_play_risk_comment            :text
#  intended_play_risk_pass               :boolean
#  max_user_mass_comment                 :text
#  max_user_mass_pass                    :boolean
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#  inspection_id                         :string(12)       not null, primary key
#
# Indexes
#
#  inflatable_game_assessments_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#
FactoryBot.define do
  factory :inflatable_game_assessment,
    class: "Assessments::InflatableGameAssessment" do
    association :inspection

    # Comment-only field
    game_type { nil }

    # Pass/fail assessments
    max_user_mass_pass { nil }
    age_range_marking_pass { nil }
    constant_air_flow_pass { nil }
    design_risk_pass { nil }
    intended_play_risk_pass { nil }
    ancillary_equipment_pass { nil }
    ancillary_equipment_compliant_pass { nil }
    containing_wall_height_pass { nil }

    # Measurements
    containing_wall_height { nil }

    trait :passed do
      game_type { "Standard inflatable obstacle course" }
      max_user_mass_pass { true }
      age_range_marking_pass { true }
      constant_air_flow_pass { true }
      design_risk_pass { true }
      intended_play_risk_pass { true }
      ancillary_equipment_pass { true }
      ancillary_equipment_compliant_pass { true }
      containing_wall_height { 1.5 }
      containing_wall_height_pass { true }
    end

    trait :complete do
      game_type { "Standard inflatable obstacle course" }
      max_user_mass_pass { true }
      max_user_mass_comment { SeedData::OK }
      age_range_marking_pass { true }
      age_range_marking_comment { SeedData::OK }
      constant_air_flow_pass { true }
      constant_air_flow_comment { SeedData::PASS }
      design_risk_pass { true }
      design_risk_comment { SeedData::PASS }
      intended_play_risk_pass { true }
      intended_play_risk_comment { SeedData::PASS }
      ancillary_equipment_pass { true }
      ancillary_equipment_comment { SeedData::OK }
      ancillary_equipment_compliant_pass { true }
      ancillary_equipment_compliant_comment { SeedData::OK }
      containing_wall_height { 1.5 }
      containing_wall_height_pass { true }
      containing_wall_height_comment { SeedData::OK }
    end

    trait :failed do
      game_type { "Inflatable assault course" }
      max_user_mass_pass { false }
      age_range_marking_pass { false }
      constant_air_flow_pass { true }
      design_risk_pass { false }
      intended_play_risk_pass { true }
      ancillary_equipment_pass { false }
      ancillary_equipment_compliant_pass { false }
      containing_wall_height { 0.8 }
      containing_wall_height_pass { false }
    end
  end
end
