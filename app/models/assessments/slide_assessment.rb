# == Schema Information
#
# Table name: slide_assessments
#
#  clamber_netting_comment                 :text
#  clamber_netting_pass                    :integer
#  runout                                  :decimal(8, 2)
#  runout_comment                          :text
#  runout_pass                             :boolean
#  slide_beyond_first_metre_height         :decimal(8, 2)
#  slide_beyond_first_metre_height_comment :text
#  slide_first_metre_height                :decimal(8, 2)
#  slide_first_metre_height_comment        :text
#  slide_permanent_roof                    :boolean
#  slide_permanent_roof_comment            :text
#  slide_platform_height                   :decimal(8, 2)
#  slide_platform_height_comment           :text
#  slide_wall_height                       :decimal(8, 2)
#  slide_wall_height_comment               :text
#  slip_sheet_comment                      :text
#  slip_sheet_pass                         :boolean
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  inspection_id                           :string(12)       not null, primary key
#
# Indexes
#
#  slide_assessments_new_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#

# typed: true
# frozen_string_literal: true

class Assessments::SlideAssessment < ApplicationRecord
  extend T::Sig
  include AssessmentLogging
  include AssessmentCompletion
  include FormConfigurable
  include ValidationConfigurable

  self.primary_key = "inspection_id"

  belongs_to :inspection

  enum :clamber_netting_pass, Inspection::PASS_FAIL_NA

  sig { returns(T::Boolean) }
  def meets_runout_requirements?
    return false unless runout.present? && slide_platform_height.present?
    EN14960::Calculators::SlideCalculator.meets_runout_requirements?(
      runout, slide_platform_height
    )
  end

  sig { returns(T.nilable(Integer)) }
  def required_runout_length
    return nil if slide_platform_height.blank?
    EN14960::Calculators::SlideCalculator.calculate_runout_value(
      slide_platform_height
    )
  end

  sig { returns(String) }
  def runout_compliance_status
    return I18n.t("forms.slide.compliance.not_assessed") if runout.blank?
    if meets_runout_requirements?
      I18n.t("forms.slide.compliance.compliant")
    else
      I18n.t("forms.slide.compliance.non_compliant",
        required: required_runout_length)
    end
  end

  sig { returns(T::Boolean) }
  def meets_wall_height_requirements?
    return false unless slide_platform_height.present? &&
      slide_wall_height.present? && !slide_permanent_roof.nil?

    # Check if wall height requirements are met for all preset user heights
    [1.0, 1.2, 1.5, 1.8].all? do |user_height|
      EN14960::Calculators::SlideCalculator.meets_height_requirements?(
        slide_platform_height,
        user_height,
        slide_wall_height,
        slide_permanent_roof
      )
    end
  end
end
