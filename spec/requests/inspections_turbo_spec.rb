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
        inspection.user_height_assessment
        patch inspection_path(inspection),
          params: {
            inspection: {
              user_height_assessment_attributes: {
                users_at_1000mm: 2
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

      it "updates progress status when assessment is updated" do
        # Start with incomplete assessment
        inspection.user_height_assessment.update!(
          containing_wall_height: nil,
          platform_height: nil
        )

        # Complete the assessment
        patch inspection_path(inspection),
          params: {
            inspection: {
              user_height_assessment_attributes: {
                containing_wall_height: 1.5,
                platform_height: 1.0,
                tallest_user_height: 1.2,
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

        # The response should contain an updated progress status
        expect(response.body).to include("inspection_progress_#{inspection.id}")
        expect(response.body).to match(/(&lt;span class=&#39;value&#39;&gt;|<span class='value'>)(In Progress|Complete)(&lt;\/span&gt;|<\/span>)/)
      end

      it "redirects when trying to update completed inspections" do
        # Create a properly completed inspection
        completed_inspection = create_completed_inspection(user: user)

        # Verify the user_height_assessment has data we can try to update
        expect(completed_inspection.user_height_assessment.tallest_user_height_comment).to be_present

        patch inspection_path(completed_inspection),
          params: {
            inspection: {
              user_height_assessment_attributes: {
                id: completed_inspection.user_height_assessment.id,
                tallest_user_height_comment: "Updated comment"
              }
            }
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        # Should redirect because completed inspections cannot be edited
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(inspection_path(completed_inspection))
      end
    end

    context "when there are validation errors" do
      it "returns turbo stream with error handling" do
        # Send invalid data that should cause validation errors
        patch inspection_path(inspection),
          params: {
            inspection: {
              user_height_assessment_attributes: {
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
      inspection.user_height_assessment.update!(
        containing_wall_height: 1.5,
        platform_height: 1.0
      )

      patch inspection_path(inspection),
        params: {
          inspection: {
            user_height_assessment_attributes: {
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
