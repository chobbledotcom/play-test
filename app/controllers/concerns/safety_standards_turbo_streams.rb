# typed: true
# frozen_string_literal: true

module SafetyStandardsTurboStreams
  extend ActiveSupport::Concern
  extend T::Sig

  private

  sig do
    params(additional_info: T.nilable(String)).returns(T::Array[T.untyped])
  end
  def success_turbo_streams(additional_info: nil)
    super + safety_standards_turbo_streams
  end

  sig { returns(T::Array[T.untyped]) }
  def safety_standards_turbo_streams
    [turbo_stream.replace(
      safety_results_frame_id,
      partial: safety_results_partial
    )]
  end

  sig { returns(String) }
  def safety_results_frame_id
    "#{assessment_type}_safety_results"
  end

  sig { returns(String) }
  def safety_results_partial
    "assessments/#{assessment_type}_safety_results"
  end
end
