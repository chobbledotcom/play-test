require "rails_helper"

RSpec.describe "Turbo Streams", type: :request do
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user: user) }
  let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html"} }

  before { login_as(user) }

  describe "content negotiation" do
    it "returns turbo streams when requested" do
      patch inspection_path(inspection),
        params: {inspection: {inspection_location: "Test"}},
        headers: turbo_headers

      expect(response.content_type).to include("text/vnd.turbo-stream.html")
      expect(response.body).to include("<turbo-stream")
    end

    it "returns JSON when requested" do
      patch inspection_path(inspection),
        params: {inspection: {inspection_location: "Test"}},
        headers: {"Accept" => "application/json"}

      expect(response.content_type).to include("application/json")
      expect(JSON.parse(response.body)["status"]).to eq("success")
    end

    it "redirects for regular HTML" do
      patch inspection_path(inspection),
        params: {inspection: {inspection_location: "Test"}}

      expect(response).to redirect_to(inspection_path(inspection))
    end
  end

  describe "inspection updates" do
    it "updates via turbo with validation errors" do
      patch inspection_path(inspection),
        params: {inspection: {inspection_location: ""}},
        headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end

    it "redirects completed inspections" do
      completed = create(:inspection, :completed, user: user)
      
      patch inspection_path(completed),
        params: {inspection: {inspection_location: "Test"}},
        headers: turbo_headers

      expect(response).to redirect_to(inspection_path(completed))
    end
  end

  describe "assessment updates" do
    # Test all assessment types with a single loop
    Inspection::ASSESSMENT_TYPES.each_key do |assessment_type|
      context "#{assessment_type} assessment" do
        let(:assessment) { inspection.send(assessment_type) }
        let(:path) { send("inspection_#{assessment_type}_path", inspection) }
        let(:params) { {"assessments_#{assessment_type.to_s.classify.underscore}" => {id: assessment.id}} }

        it "accepts turbo stream updates" do
          patch path, params: params, headers: turbo_headers

          expect(response).to have_http_status(:ok)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
        end

        it "includes required turbo frames" do
          patch path, params: params, headers: turbo_headers

          expect(response.body).to include("mark_complete_section")
          
          # Only some assessments have safety results
          if %i[anchorage_assessment slide_assessment user_height_assessment].include?(assessment_type)
            frame_name = assessment_type.to_s.gsub('_assessment', '')
            expect(response.body).to include("#{frame_name}_safety_results")
          end
        end
      end
    end
  end

  # RPII verification uses format.turbo_stream instead of Accept headers
  # It's tested separately in spec/features/users/rpii_verification_with_turbo_spec.rb
end