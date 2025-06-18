require "rails_helper"

RSpec.describe "Assessment Safety Calculations", type: :request do
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user: user) }
  let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html"} }

  before { login_as(user) }

  describe "dynamic calculations" do
    it "updates anchorage calculations" do
      patch inspection_anchorage_assessment_path(inspection),
        params: {
          assessments_anchorage_assessment: {
            num_low_anchors: 4,
            num_high_anchors: 3
          }
        },
        headers: turbo_headers

      expect(response.body).to include("7") # Total anchors
    end

    it "updates slide runout calculations" do
      inspection.slide_assessment.update!(slide_platform_height: 2.0)

      patch inspection_slide_assessment_path(inspection),
        params: {
          assessments_slide_assessment: {
            runout: 1.5
          }
        },
        headers: turbo_headers

      expect(response.body).to include("slide_safety_results")
    end

    it "updates user height calculations" do
      patch inspection_user_height_assessment_path(inspection),
        params: {
          assessments_user_height_assessment: {
            users_at_1000mm: 10,
            users_at_1200mm: 5
          }
        },
        headers: turbo_headers

      expect(response.body).to include("15") # Total users
    end
  end
end
