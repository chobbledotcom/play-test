require "rails_helper"

RSpec.describe "Inspections", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  let(:valid_inspection_attributes) do
    {
      inspection_date: Date.today,
      inspection_location: "Test Location",
      passed: true,
      comments: "Test comments",
      status: "draft"
    }
  end

  describe "authentication requirements" do
    it "redirects to login page when not logged in for index" do
      get "/inspections"
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end

    it "redirects to login page when not logged in for show" do
      # Create a test inspection with user association
      inspection = create(:inspection, user: user, unit: unit)

      get "/inspections/#{inspection.id}"
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end

    it "redirects to login page when not logged in for new inspection" do
      get "/inspections/new"
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end

    it "redirects to login page when not logged in for create" do
      post "/inspections", params: {inspection: valid_inspection_attributes}
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end

    it "redirects to login page when not logged in for edit" do
      # Create a test inspection with user association
      inspection = create(:inspection, user: user, unit: unit)

      get "/inspections/#{inspection.id}/edit"
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end

    it "redirects to login page when not logged in for update" do
      # Create a test inspection with user association
      inspection = create(:inspection, user: user, unit: unit)

      patch "/inspections/#{inspection.id}", params: {inspection: {description: "Updated Unit"}}
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end

    it "redirects to login page when not logged in for destroy" do
      # Create a test inspection with user association
      inspection = create(:inspection, user: user, unit: unit)

      delete "/inspections/#{inspection.id}"
      expect(response).to redirect_to(login_path)
      expect(flash[:danger]).to include("Please log in")
    end
  end

  describe "user_id association" do
    before do
      login_as(user)
    end

    it "assigns the current user's ID when creating a new inspection" do
      post "/inspections", params: {inspection: valid_inspection_attributes.merge(unit_id: unit.id)}

      # Verify a new inspection was created
      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response).to have_http_status(:success)

      # Verify it was associated with the current user
      inspection = Inspection.last
      expect(inspection.user_id).to eq(user.id)
    end

    it "cannot override the user_id when creating a new inspection" do
      # Try to set user_id to another user
      post "/inspections", params: {
        inspection: valid_inspection_attributes.merge(unit_id: unit.id, user_id: other_user.id)
      }

      # Verify it still used the current user's ID
      inspection = Inspection.last
      expect(inspection.user_id).to eq(user.id)
      expect(inspection.user_id).not_to eq(other_user.id)
    end

    it "cannot override the user_id when updating an inspection" do
      # Create a test inspection with current user
      inspection = create(:inspection, user: user, unit: unit)

      # Try to change the user_id during update
      patch "/inspections/#{inspection.id}", params: {
        inspection: {inspection_location: "Updated Location", user_id: other_user.id}
      }

      # Verify the location updated but not the user_id
      inspection.reload
      expect(inspection.inspection_location).to eq("Updated Location")
      expect(inspection.user_id).to eq(user.id)
      expect(inspection.user_id).not_to eq(other_user.id)
    end
  end

  describe "authorization requirements" do
    before do
      # Create two inspections, one for each user
      @user_inspection = create(:inspection, user: user, unit: unit)
      other_unit = create(:unit, user: other_user)
      @other_inspection = create(:inspection, user: other_user, unit: other_unit)
    end

    it "only shows the current user's inspections in the index" do
      # Log in as the first user
      login_as(user)

      get "/inspections"
      expect(response).to have_http_status(:success)

      # Verify only the current user's inspections are displayed
      expect(response.body).to include(@user_inspection.serial)
      expect(response.body).not_to include(@other_inspection.serial)
    end

    it "prevents viewing another user's inspection" do
      # Log in as the first user
      login_as(user)

      # Try to view another user's inspection
      get "/inspections/#{@other_inspection.id}"

      # Should redirect with an unauthorized message
      expect(response).to redirect_to(inspections_path)
      expect(flash[:danger]).to include("Access denied")
    end

    it "prevents editing another user's inspection" do
      # Log in as the first user
      login_as(user)

      # Try to edit another user's inspection
      get "/inspections/#{@other_inspection.id}/edit"

      # Should redirect with an unauthorized message
      expect(response).to redirect_to(inspections_path)
      expect(flash[:danger]).to include("Access denied")
    end

    it "prevents updating another user's inspection" do
      # Log in as the first user
      login_as(user)

      # Try to update another user's inspection
      patch "/inspections/#{@other_inspection.id}", params: {
        inspection: {manufacturer: "Should Not Update"}
      }

      # Should redirect with an unauthorized message
      expect(response).to redirect_to(inspections_path)
      expect(flash[:danger]).to include("Access denied")

      # Verify the manufacturer did not change
      @other_inspection.reload
      expect(@other_inspection.manufacturer).to eq("Test Manufacturer")
    end

    it "prevents deleting another user's inspection" do
      # Log in as the first user
      login_as(user)

      # Try to delete another user's inspection
      delete "/inspections/#{@other_inspection.id}"

      # Should redirect with an unauthorized message
      expect(response).to redirect_to(inspections_path)
      expect(flash[:danger]).to include("Access denied")

      # Verify the inspection still exists
      expect(Inspection.exists?(@other_inspection.id)).to be true
    end
  end

  describe "when logged in" do
    before do
      login_as(user)
    end

    describe "GET /index" do
      it "returns http success" do
        get "/inspections"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /show" do
      it "returns http success for own inspection" do
        inspection = create(:inspection, user: user, unit: unit)

        get "/inspections/#{inspection.id}"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /edit" do
      it "returns http success for own inspection" do
        inspection = create(:inspection, user: user, unit: unit)

        get "/inspections/#{inspection.id}/edit"
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /create" do
      it "creates a new inspection and redirects" do
        post "/inspections", params: {inspection: valid_inspection_attributes.merge(unit_id: unit.id)}

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        # Verify the inspection was created with correct attributes
        inspection = Inspection.last
        expect(inspection.unit_id).to eq(unit.id)
        expect(inspection.user_id).to eq(user.id)
      end

      it "creates a new inspection with all attributes and redirects" do
        post "/inspections", params: {
          inspection: valid_inspection_attributes.merge(
            unit_id: unit.id
          )
        }

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        # Check attributes and user_id
        inspection = Inspection.last
        expect(inspection.unit_id).to eq(unit.id)
        expect(inspection.user_id).to eq(user.id)
      end
    end

    describe "PATCH /update" do
      it "updates own inspection and redirects" do
        inspection = create(:inspection, user: user, unit: unit)

        patch "/inspections/#{inspection.id}", params: {
          inspection: {inspection_location: "Updated Location"}
        }

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        # Verify the inspection was updated
        inspection.reload
        expect(inspection.inspection_location).to eq("Updated Location")
        expect(inspection.user_id).to eq(user.id)
      end

      it "updates inspection with user height assessment attributes" do
        inspection = create(:inspection, user: user, unit: unit)

        patch "/inspections/#{inspection.id}", params: {
          inspection: {
            inspection_location: "Updated Location",
            user_height_assessment_attributes: {
              containing_wall_height: 2.5,
              platform_height: 1.0,
              user_height: 1.8,
              permanent_roof: true,
              users_at_1000mm: 5,
              users_at_1200mm: 4,
              users_at_1500mm: 3,
              users_at_1800mm: 2,
              play_area_length: 10.0,
              play_area_width: 8.0,
              negative_adjustment: 2.0,
              user_height_comment: "Test assessment comment"
            }
          }
        }

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        # Verify the inspection and assessment were updated
        inspection.reload
        expect(inspection.inspection_location).to eq("Updated Location")

        # Verify user height assessment was created
        assessment = inspection.user_height_assessment
        expect(assessment).to be_present
        expect(assessment.containing_wall_height).to eq(2.5)
        expect(assessment.platform_height).to eq(1.0)
        expect(assessment.user_height).to eq(1.8)
        expect(assessment.permanent_roof).to be true
        expect(assessment.users_at_1000mm).to eq(5)
        expect(assessment.users_at_1200mm).to eq(4)
        expect(assessment.users_at_1500mm).to eq(3)
        expect(assessment.users_at_1800mm).to eq(2)
        expect(assessment.play_area_length).to eq(10.0)
        expect(assessment.play_area_width).to eq(8.0)
        expect(assessment.negative_adjustment).to eq(2.0)
        expect(assessment.user_height_comment).to eq("Test assessment comment")
      end

      it "updates existing user height assessment" do
        inspection = create(:inspection, user: user, unit: unit)
        assessment = create(:user_height_assessment, inspection: inspection, containing_wall_height: 1.5)

        patch "/inspections/#{inspection.id}", params: {
          inspection: {
            user_height_assessment_attributes: {
              id: assessment.id,
              containing_wall_height: 3.0
            }
          }
        }

        expect(response).to have_http_status(:redirect)

        # Verify the assessment was updated, not recreated
        inspection.reload
        expect(inspection.user_height_assessment.id).to eq(assessment.id)
        expect(inspection.user_height_assessment.containing_wall_height).to eq(3.0)
      end
    end

    describe "DELETE /destroy" do
      it "deletes own inspection and redirects" do
        inspection = create(:inspection, user: user, unit: unit)

        delete "/inspections/#{inspection.id}"

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        # Verify the inspection was deleted
        expect(Inspection.exists?(inspection.id)).to be false
      end
    end
  end
end
