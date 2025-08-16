# == Schema Information
#
# Table name: user_height_assessments
#
#  id                             :integer          not null
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
#  index_user_height_assessments_on_inspection_id  (inspection_id)
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#

# typed: true
# frozen_string_literal: true

module Assessments
  class UserHeightAssessment < ApplicationRecord
    extend T::Sig
    include AssessmentLogging
    include AssessmentCompletion
    include FormConfigurable
    include ValidationConfigurable

    self.primary_key = "inspection_id"

    belongs_to :inspection

    validates :inspection_id,
      uniqueness: true

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def validate_play_area
      return {valid: false, errors: ["Inspection not found"]} unless inspection

      unit_length = inspection.length
      unit_width = inspection.width

      # Check if we have all required measurements
      if [unit_length, unit_width, play_area_length, play_area_width].any?(&:nil?)
        return {
          valid: false,
          errors: ["Missing required measurements for play area validation"],
          measurements: {}
        }
      end

      # Use the negative_adjustment value, defaulting to 0 if nil
      adjustment = negative_adjustment || 0

      # Call the EN14960 validator - convert BigDecimal to Float
      EN14960.validate_play_area(
        unit_length: unit_length.to_f,
        unit_width: unit_width.to_f,
        play_area_length: play_area_length.to_f,
        play_area_width: play_area_width.to_f,
        negative_adjustment_area: adjustment.to_f
      )
    end

    sig { returns(T::Boolean) }
    def play_area_valid?
      validate_play_area[:valid]
    end
  end
end
