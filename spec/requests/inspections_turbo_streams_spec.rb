require "rails_helper"

RSpec.describe "Inspections Turbo Streams", type: :request do
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user: user) }

  before do
    login_as(user)
  end

  describe "PATCH /inspections/:id with Turbo Streams" do
    context "when request accepts turbo streams" do
      let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html"} }

      it "returns turbo stream content type" do
        patch inspection_path(inspection),
          params: {inspection: {comments: "Updated via turbo"}},
          headers: turbo_headers

        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "returns properly formatted turbo stream elements" do
        patch inspection_path(inspection),
          params: {inspection: {comments: "Test update"}},
          headers: turbo_headers

        # Parse the response to check structure
        expect(response.body).to include("<turbo-stream")
        expect(response.body).to include('action="replace"')
        expect(response.body).to include("target=\"inspection_progress_#{inspection.id}\"")
        expect(response.body).to include("<template>")
        expect(response.body).to include("</template>")
        expect(response.body).to include("</turbo-stream>")
      end

      it "includes progress percentage in turbo stream" do
        patch inspection_path(inspection),
          params: {inspection: {comments: "Test"}},
          headers: turbo_headers

        # Should include a percentage value (HTML might be escaped in template)
        expect(response.body).to match(/(&lt;span class=&#39;value&#39;&gt;|<span class='value'>)\d+%(&lt;\/span&gt;|<\/span>)/)
      end

      it "includes completion issues turbo stream" do
        patch inspection_path(inspection),
          params: {inspection: {comments: "Test"}},
          headers: turbo_headers

        expect(response.body).to include("target=\"completion_issues_#{inspection.id}\"")
      end

      context "when updating assessment data" do
        before do
          inspection.create_user_height_assessment!(
            containing_wall_height: 1.0,
            platform_height: 1.0
          )
        end

        it "successfully updates assessment via turbo stream" do
          expect {
            patch inspection_path(inspection),
              params: {
                inspection: {
                  user_height_assessment_attributes: {
                    id: inspection.user_height_assessment.id,
                    containing_wall_height: 2.0
                  }
                }
              },
              headers: turbo_headers
          }.to change {
            inspection.user_height_assessment.reload.containing_wall_height
          }.from(1.0).to(2.0)

          expect(response).to have_http_status(:ok)
        end
      end

      context "with validation errors" do
        it "still returns turbo stream format on error" do
          # Force a validation error by trying to clear a required field
          # Don't mark as complete so we can actually test the validation error handling
          patch inspection_path(inspection),
            params: {inspection: {inspection_location: ""}},
            headers: turbo_headers

          expect(response.content_type).to include("text/vnd.turbo-stream.html")
          expect(response.body).to include("<turbo-stream")
        end
      end
    end

    context "when request accepts JSON" do
      let(:json_headers) { {"Accept" => "application/json"} }

      it "returns JSON response for backwards compatibility" do
        patch inspection_path(inspection),
          params: {inspection: {comments: "Updated via JSON"}},
          headers: json_headers

        expect(response.content_type).to include("application/json")
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("success")
      end
    end

    context "when request is standard HTML" do
      it "redirects on success" do
        patch inspection_path(inspection),
          params: {inspection: {comments: "Updated via HTML"}}

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(inspection_path(inspection))
      end
    end
  end


  describe "Progress calculation in turbo streams" do
    let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html"} }

    it "updates progress when assessment is marked complete" do
      # Create an incomplete assessment
      inspection.create_user_height_assessment!(
        containing_wall_height: nil,
        platform_height: nil
      )

      # Complete the assessment
      patch inspection_path(inspection),
        params: {
          inspection: {
            user_height_assessment_attributes: attributes_for(:user_height_assessment, :with_basic_data).merge(
              id: inspection.user_height_assessment.id,
              tallest_user_height_comment: "Complete"
            )
          }
        },
        headers: turbo_headers

      # Should show some progress (not 0%)
      expect(response.body).to match(/(&lt;span class=&#39;value&#39;&gt;|<span class='value'>)([1-9]\d*)%(&lt;\/span&gt;|<\/span>)/)
    end
  end

  describe "Completed inspection behavior" do
    let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html"} }

    before do
      inspection.update!(status: "complete")
      inspection.create_user_height_assessment!(
        containing_wall_height: 1.5,
        platform_height: 1.0,
        tallest_user_height: 1.2
      )
    end

    it "redirects when trying to update completed inspections" do
      patch inspection_path(inspection),
        params: {inspection: {comments: "Updated"}},
        headers: turbo_headers

      # Should redirect because completed inspections cannot be edited
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(inspection_path(inspection))
    end
  end

  describe "Error handling" do
    let(:turbo_headers) { {"Accept" => "text/vnd.turbo-stream.html"} }

    it "doesn't break on controller helper method calls" do
      # This test ensures we're using helpers.method_name correctly
      patch inspection_path(inspection),
        params: {inspection: {comments: "Test"}},
        headers: turbo_headers

      expect(response).to have_http_status(:ok)
      # Should not raise NoMethodError for content_tag or helper methods
    end

    it "handles missing assessments gracefully" do
      # Ensure no assessments exist
      inspection.user_height_assessment&.destroy

      patch inspection_path(inspection),
        params: {inspection: {comments: "Test"}},
        headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("0%") # Should show 0% progress
    end
  end
end
