require "rails_helper"

RSpec.describe "PDF Viewer Template", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user, serial: "TEST-123") }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  describe "Minimal PDF viewer for non-logged-in users" do
    context "when accessing inspection HTML as non-logged-in user" do
      it "renders the minimal PDF viewer template" do
        get inspection_path(inspection)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("<iframe")
        expect(response.body).to include(inspection_path(inspection, format: :pdf))
        expect(response.body).to include("<title>")
        expect(response.body).to include("#{inspection.unit&.serial || inspection.id}.pdf")

        # Should NOT include the normal application layout elements
        expect(response.body).not_to include("nav")
        expect(response.body).not_to include("Log Out")
        expect(response.body).not_to include("Home")
      end

      it "sets correct iframe styling for full viewport" do
        get inspection_path(inspection)

        expect(response.body).to include("width: 100%")
        expect(response.body).to include("height: 100%")
        expect(response.body).to include("border: none")
      end
    end

    context "when accessing unit HTML as non-logged-in user" do
      it "renders the minimal PDF viewer template" do
        get unit_path(unit)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("<iframe")
        expect(response.body).to include(unit_path(unit, format: :pdf))
        expect(response.body).to include("<title>")
        expect(response.body).to include("#{unit.serial}.pdf")

        # Should NOT include the normal application layout elements
        expect(response.body).not_to include("nav")
        expect(response.body).not_to include("Log Out")
        expect(response.body).not_to include("Home")
      end
    end

    context "when logged in as owner" do
      before { login_as(user) }

      it "renders the normal inspection view for HTML" do
        get inspection_path(inspection)

        expect(response).to have_http_status(:success)
        # Should render the full application layout with navigation
        expect(response.body).to include("Log Out")
        expect(response.body).to include("nav")
        # Should use the main application layout, not the minimal pdf_viewer layout
        expect(response.body).to include("play-test | Professional Inspection Management")
      end

      it "renders the normal unit view for HTML" do
        get unit_path(unit)

        expect(response).to have_http_status(:success)
        # Should render the full application layout with navigation
        expect(response.body).to include("Log Out")
        expect(response.body).to include("nav")
        # Should use the main application layout, not the minimal pdf_viewer layout
        expect(response.body).to include("play-test | Professional Inspection Management")
      end
    end

    context "when logged in as different user" do
      let(:other_user) { create(:user) }
      before { login_as(other_user) }

      it "renders the minimal PDF viewer for inspection HTML" do
        get inspection_path(inspection)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("<iframe")
        expect(response.body).to include(inspection_path(inspection, format: :pdf))
        expect(response.body).to include("#{inspection.unit&.serial || inspection.id}.pdf")

        # Should NOT include the normal application layout elements
        expect(response.body).not_to include("nav")
        expect(response.body).not_to include("Log Out")
      end

      it "renders the minimal PDF viewer for unit HTML" do
        get unit_path(unit)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("<iframe")
        expect(response.body).to include(unit_path(unit, format: :pdf))
        expect(response.body).to include("#{unit.serial}.pdf")

        # Should NOT include the normal application layout elements
        expect(response.body).not_to include("nav")
        expect(response.body).not_to include("Log Out")
      end
    end

    context "when accessing other formats" do
      it "returns PDF directly for inspection PDF requests" do
        get inspection_path(inspection, format: :pdf)

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")
      end

      it "returns PDF directly for unit PDF requests" do
        get unit_path(unit, format: :pdf)

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")
      end

      it "returns JSON for inspection JSON requests" do
        get inspection_path(inspection, format: :json)

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
      end

      it "returns PNG for inspection QR code requests" do
        get inspection_path(inspection, format: :png)

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("image/png")
      end
    end
  end

  describe "404 handling for non-existent resources" do
    it "returns 404 for non-existent inspection regardless of format" do
      get "/inspections/NONEXISTENT"
      expect(response).to have_http_status(:not_found)

      get "/inspections/NONEXISTENT.pdf"
      expect(response).to have_http_status(:not_found)

      get "/inspections/NONEXISTENT.json"
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for non-existent unit regardless of format" do
      get "/units/NONEXISTENT"
      expect(response).to have_http_status(:not_found)

      get "/units/NONEXISTENT.pdf"
      expect(response).to have_http_status(:not_found)

      get "/units/NONEXISTENT.json"
      expect(response).to have_http_status(:not_found)
    end
  end
end
