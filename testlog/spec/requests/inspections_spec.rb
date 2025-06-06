require "rails_helper"

RSpec.describe "Inspections", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  let(:valid_inspection_attributes) do
    {
      inspection_date: Date.today,
      reinspection_date: Date.today + 1.year,
      inspector: "Test Inspector",
      location: "Test Location",
      place_inspected: "Test Facility",
      passed: true,
      comments: "Test comments"
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
      post "/login", params: {session: {email: user.email, password: "password123"}}
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
        inspection: {location: "Updated Location", user_id: other_user.id}
      }

      # Verify the location updated but not the user_id
      inspection.reload
      expect(inspection.location).to eq("Updated Location")
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
      post "/login", params: {session: {email: user.email, password: "password123"}}

      get "/inspections"
      expect(response).to have_http_status(:success)

      # Verify only the current user's inspections are displayed
      expect(response.body).to include(@user_inspection.serial)
      expect(response.body).not_to include(@other_inspection.serial)
    end

    it "prevents viewing another user's inspection" do
      # Log in as the first user
      post "/login", params: {session: {email: user.email, password: "password123"}}

      # Try to view another user's inspection
      get "/inspections/#{@other_inspection.id}"

      # Should redirect with an unauthorized message
      expect(response).to redirect_to(inspections_path)
      expect(flash[:danger]).to include("Access denied")
    end

    it "prevents editing another user's inspection" do
      # Log in as the first user
      post "/login", params: {session: {email: user.email, password: "password123"}}

      # Try to edit another user's inspection
      get "/inspections/#{@other_inspection.id}/edit"

      # Should redirect with an unauthorized message
      expect(response).to redirect_to(inspections_path)
      expect(flash[:danger]).to include("Access denied")
    end

    it "prevents updating another user's inspection" do
      # Log in as the first user
      post "/login", params: {session: {email: user.email, password: "password123"}}

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
      post "/login", params: {session: {email: user.email, password: "password123"}}

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
      post "/login", params: {session: {email: user.email, password: "password123"}}
    end

    describe "GET /index" do
      it "returns http success" do
        get "/inspections"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /show" do
      it "returns http success for own inspection" do
        inspection = Inspection.create!(valid_inspection_attributes.merge(user: user, unit: unit))

        get "/inspections/#{inspection.id}"
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /edit" do
      it "returns http success for own inspection" do
        inspection = Inspection.create!(valid_inspection_attributes.merge(user: user, unit: unit))

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
        inspection = Inspection.create!(valid_inspection_attributes.merge(
          user: user,
          unit: unit
        ))

        patch "/inspections/#{inspection.id}", params: {
          inspection: {location: "Updated Location"}
        }

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        # Verify the inspection was updated
        inspection.reload
        expect(inspection.location).to eq("Updated Location")
        expect(inspection.user_id).to eq(user.id)
      end
    end

    describe "DELETE /destroy" do
      it "deletes own inspection and redirects" do
        inspection = Inspection.create!(valid_inspection_attributes.merge(
          user: user,
          unit: unit
        ))

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
