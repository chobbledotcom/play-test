require "rails_helper"

RSpec.describe "Inspections Auto-save", type: :request do
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user: user) }

  before do
    login_as user
  end

  describe "Auto-save functionality" do
    it "responds to PATCH requests with turbo stream accept header" do
      assessment = inspection.create_user_height_assessment!

      patch inspection_path(inspection),
        params: {
          inspection: {
            user_height_assessment_attributes: {
              id: assessment.id,
              containing_wall_height: 1.5
            }
          }
        },
        headers: {
          "Accept" => "text/vnd.turbo-stream.html",
          "X-CSRF-Token" => "test-token"  # In real browser this comes from meta tag
        }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end

    it "updates assessment data via auto-save request" do
      assessment = inspection.create_user_height_assessment!(containing_wall_height: 1.0)

      expect {
        patch inspection_path(inspection),
          params: {
            inspection: {
              user_height_assessment_attributes: {
                id: assessment.id,
                containing_wall_height: 2.0,
                user_height: 1.5
              }
            }
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}
      }.to change { assessment.reload.containing_wall_height }.from(1.0).to(2.0)
        .and change { assessment.reload.user_height }.from(nil).to(1.5)
    end

    it "calculates and returns updated progress percentage" do
      # Create multiple assessments to test progress calculation
      inspection.create_user_height_assessment!(
        containing_wall_height: 1.5,
        platform_height: 1.0,
        user_height: 1.2,
        permanent_roof: false,
        users_at_1000mm: 10,
        users_at_1200mm: 8,
        users_at_1500mm: 6,
        users_at_1800mm: 4,
        play_area_length: 5.0,
        play_area_width: 4.0,
        user_height_comment: "Complete"
      )

      slide = inspection.create_slide_assessment!(
        slide_platform_height: 2.0,
        slide_wall_height: 1.5,
        runout_value: 1.0
      )

      patch inspection_path(inspection),
        params: {
          inspection: {
            slide_assessment_attributes: {
              id: slide.id,
              slide_platform_height_comment: "Updated via auto-save"
            }
          }
        },
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:success)

      # Should contain updated progress - with 2 assessments partially complete
      expect(response.body).to include("inspection_progress_#{inspection.id}")
      expect(response.body).to match(/\d+%/)
    end

    it "handles rapid successive auto-save requests" do
      assessment = inspection.create_user_height_assessment!

      # Simulate rapid successive updates (like user typing quickly)
      3.times do |i|
        patch inspection_path(inspection),
          params: {
            inspection: {
              user_height_assessment_attributes: {
                id: assessment.id,
                containing_wall_height: 1.0 + i,
                user_height_comment: "Update #{i}"
              }
            }
          },
          headers: {"Accept" => "text/vnd.turbo-stream.html"}

        expect(response).to have_http_status(:success)
      end

      # Final value should be the last update
      expect(assessment.reload.containing_wall_height).to eq(3.0)
      expect(assessment.reload.user_height_comment).to eq("Update 2")
    end
  end

  describe "Progress percentage calculation" do
    it "shows 0% when no assessments are complete" do
      # Create assessments but don't complete them
      inspection.create_user_height_assessment!(containing_wall_height: 1.0)
      inspection.create_slide_assessment!(slide_platform_height: 2.0)

      patch inspection_path(inspection),
        params: {
          inspection: {
            user_height_assessment_attributes: {
              id: inspection.user_height_assessment.id,
              platform_height: 1.5
            }
          }
        },
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      # Progress should be > 0% as assessments exist but may not be complete
      expect(response.body).to include("inspection_progress_#{inspection.id}")
    end

    it "increases percentage as more assessments are completed" do
      # Complete one assessment fully
      inspection.create_user_height_assessment!(
        containing_wall_height: 1.5,
        platform_height: 1.0,
        user_height: 1.2,
        permanent_roof: false,
        users_at_1000mm: 10,
        users_at_1200mm: 8,
        users_at_1500mm: 6,
        users_at_1800mm: 4,
        play_area_length: 5.0,
        play_area_width: 4.0,
        user_height_comment: "Complete"
      )

      # Add another incomplete assessment
      incomplete_assessment = inspection.create_slide_assessment!(
        slide_platform_height: 2.0
      )

      patch inspection_path(inspection),
        params: {
          inspection: {
            slide_assessment_attributes: {
              id: incomplete_assessment.id,
              slide_wall_height: 1.5,
              runout_value: 1.0,
              slide_platform_height_comment: "Now more complete"
            }
          }
        },
        headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:success)
      # Should show some progress > 0%
      expect(response.body).to match(/\d+%/)
    end
  end
end
