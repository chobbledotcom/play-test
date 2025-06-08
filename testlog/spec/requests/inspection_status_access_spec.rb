require "rails_helper"

RSpec.describe "Inspection Status Access Control", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before do
    # Login
    post "/login", params: {session: {email: user.email, password: "password123"}}
  end

  describe "PDF report access based on inspection status" do
    context "when inspection status is 'draft'" do
      let(:draft_inspection) { create(:inspection, user: user, unit: unit, status: "draft") }

      it "returns 404 for report access" do
        get report_inspection_path(draft_inspection)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for QR code access" do
        get qr_code_inspection_path(draft_inspection)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when inspection status is 'in_progress'" do
      let(:in_progress_inspection) { create(:inspection, user: user, unit: unit, status: "in_progress") }

      it "returns 404 for report access" do
        get report_inspection_path(in_progress_inspection)
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for QR code access" do
        get qr_code_inspection_path(in_progress_inspection)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when inspection status is 'completed'" do
      let(:completed_inspection) { create(:inspection, :completed, user: user, unit: unit) }

      it "allows report access" do
        get report_inspection_path(completed_inspection)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")
      end

      it "allows QR code access" do
        get qr_code_inspection_path(completed_inspection)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("image/png")
      end
    end

    # Note: Finalized status also allows access but requires complete assessments to create
    # which is complex for this test. The controller allows both 'completed' and 'finalized'.
  end

  describe "Public access via short URLs" do
    context "when inspection is not completed" do
      let(:draft_inspection) { create(:inspection, user: user, unit: unit, status: "draft") }

      it "returns 404 for public report URL" do
        # Logout first
        delete logout_path

        get "/r/#{draft_inspection.id}"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when inspection is completed" do
      let(:completed_inspection) { create(:inspection, :completed, user: user, unit: unit) }

      it "allows public report access" do
        # Logout first
        delete logout_path

        get "/r/#{completed_inspection.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")
      end
    end
  end

  describe "Authenticated access to inspection" do
    let(:inspection) { create(:inspection, user: user, unit: unit, status: "draft") }

    it "still allows viewing inspection details regardless of status" do
      get inspection_path(inspection)
      expect(response).to have_http_status(:success)
    end

    it "still allows editing inspection regardless of status" do
      get edit_inspection_path(inspection)
      expect(response).to have_http_status(:success)
    end
  end
end
