module SafetyStandardsTurboHelpers
  def expect_safety_standards_turbo_stream(response, assessment_type)
    frame_id = "#{assessment_type}_safety_results"

    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include("text/vnd.turbo-stream.html")

    # Check for the safety results frame
    expect(response.body).to include("target=\"#{frame_id}\"")
    expect(response.body).to include("<turbo-stream")
    expect(response.body).to include('action="replace"')

    # Check for standard turbo streams
    expect(response.body).to include("inspection_progress_")
    expect(response.body).to include("mark_complete_section_")
    expect(response.body).to include("form_save_message")
  end

  def update_assessment_via_turbo(inspection, assessment_type, params)
    patch send("inspection_#{assessment_type}_assessment_path", inspection),
      params: {"assessments_#{assessment_type}_assessment" => params},
      headers: turbo_headers
  end

  def turbo_headers
    {"Accept" => "text/vnd.turbo-stream.html"}
  end
end

RSpec.configure do |config|
  config.include SafetyStandardsTurboHelpers, type: :request
end
