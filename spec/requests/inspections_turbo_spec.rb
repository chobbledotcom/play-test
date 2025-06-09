require "rails_helper"

RSpec.describe "Inspections Turbo Streams", type: :request do
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user: user) }

  before do
    login_as user
  end

  describe "PATCH /inspections/:id with Turbo Stream" do
    context "when updating assessment data" do
      it "returns turbo stream response with progress update" do
        # Create an assessment to update
        assessment = inspection.create_user_height_assessment!(
          containing_wall_height: 1.5,
          platform_height: 1.0,
          tallest_user_height: 1.2
        )

        patch inspection_path(inspection),
          params: {
            inspection: {
              user_height_assessment_attributes: {
                id: assessment.id,
                permanent_roof: true
              }
            }
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")

        # Check that the response contains turbo stream elements
        expect(response.body).to include("turbo-stream")
        expect(response.body).to include("inspection_progress_#{inspection.id}")
        expect(response.body).to include("completion_issues_#{inspection.id}")
      end

      it "updates progress percentage when assessment is completed" do
        # Start with incomplete assessment
        assessment = inspection.create_user_height_assessment!(
          containing_wall_height: nil,
          platform_height: nil
        )

        # Complete the assessment
        patch inspection_path(inspection),
          params: {
            inspection: {
              user_height_assessment_attributes: {
                id: assessment.id,
                containing_wall_height: 1.5,
                platform_height: 1.0,
                tallest_user_height: 1.2,
                permanent_roof: false,
                users_at_1000mm: 10,
                users_at_1200mm: 8,
                users_at_1500mm: 6,
                users_at_1800mm: 4,
                play_area_length: 5.0,
                play_area_width: 4.0,
                tallest_user_height_comment: "Test comment"
              }
            }
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:success)

        # The response should contain an updated progress percentage
        # Since we have one complete assessment out of several, it should be > 0%
        expect(response.body).to match(/\d+%/)
      end

      it "redirects when trying to update completed inspections" do
        # Mark inspection as completed
        inspection.update!(status: "complete")

        # Create an assessment
        inspection.create_user_height_assessment!(
          containing_wall_height: 1.5,
          platform_height: 1.0,
          tallest_user_height: 1.2,
          permanent_roof: false,
          users_at_1000mm: 10,
          users_at_1200mm: 8,
          users_at_1500mm: 6,
          users_at_1800mm: 4,
          play_area_length: 5.0,
          play_area_width: 4.0,
          tallest_user_height_comment: "Complete"
        )

        patch inspection_path(inspection),
          params: {
            inspection: {
              user_height_assessment_attributes: {
                id: inspection.user_height_assessment.id,
                tallest_user_height_comment: "Updated comment"
              }
            }
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        # Should redirect because completed inspections cannot be edited
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(inspection_path(inspection))
      end
    end

    context "when there are validation errors" do
      it "returns turbo stream with error handling" do
        assessment = inspection.create_user_height_assessment!

        # Send invalid data that should cause validation errors
        patch inspection_path(inspection),
          params: {
            inspection: {
              user_height_assessment_attributes: {
                id: assessment.id,
                containing_wall_height: -1  # Invalid negative value
              }
            }
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        # Should still return a turbo stream response even with errors
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "Turbo Stream content validation" do
    it "produces valid turbo stream markup" do
      assessment = inspection.create_user_height_assessment!(
        containing_wall_height: 1.5,
        platform_height: 1.0
      )

      patch inspection_path(inspection),
        params: {
          inspection: {
            user_height_assessment_attributes: {
              id: assessment.id,
              tallest_user_height: 1.2
            }
          }
        },
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      # Validate that the turbo stream is well-formed
      expect(response.body).to include("<turbo-stream")
      expect(response.body).to include('action="replace"')
      expect(response.body).to include('target="inspection_progress_')
      expect(response.body).to include("</turbo-stream>")
    end
  end
end
