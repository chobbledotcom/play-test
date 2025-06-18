module SafetyStandardsTurboStreams
  extend ActiveSupport::Concern

  private

  def success_turbo_streams
    super + safety_standards_turbo_streams
  end

  def safety_standards_turbo_streams
    Rails.logger.debug "=== SafetyStandardsTurboStreams Debug ==="
    Rails.logger.debug "Assessment: #{@assessment.inspect}"
    Rails.logger.debug "Partial: #{safety_results_partial}"
    Rails.logger.debug "========================================"
    
    [turbo_stream.replace(safety_results_frame_id, partial: safety_results_partial)]
  end

  def safety_results_frame_id
    "#{assessment_type}_safety_results"
  end

  def safety_results_partial
    "assessments/#{assessment_type}_safety_results"
  end
end
