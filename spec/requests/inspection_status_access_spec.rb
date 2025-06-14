require "rails_helper"

RSpec.describe "Inspection Status Access Control", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before do
    # Login
    post "/login", params: {session: {email: user.email, password: user.password}}
  end

  describe "PDF report access based on inspection status" do
    context "when inspection status is 'draft'" do
      let(:draft_inspection) { create(:inspection, user: user, unit: unit, complete_date: nil) }

      it "allows report access (now available for all statuses)" do
        get inspection_path(draft_inspection, format: :pdf)
        expect(response).to have_http_status(:ok)
      end

      it "allows QR code access (now available for all statuses)" do
        get inspection_path(draft_inspection, format: :png)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when inspection status is 'complete'" do
      let(:complete_inspection) { create_completed_inspection(user: user, unit: unit) }

      it "allows report access" do
        get inspection_path(complete_inspection, format: :pdf)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")
      end

      it "allows QR code access" do
        get inspection_path(complete_inspection, format: :png)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("image/png")
      end
    end

    # Note: Complete status allows access for all reports and QR codes
  end

  describe "Public access" do
    context "when inspection is draft" do
      let(:draft_inspection) { create(:inspection, user: user, unit: unit, complete_date: nil) }

      it "shows minimal PDF viewer for HTML requests" do
        # Logout first
        delete logout_path

        get "/inspections/#{draft_inspection.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("text/html; charset=utf-8")
        expect(response.body).to include("<iframe")
      end

      it "allows public PDF access" do
        # Logout first
        delete logout_path

        get "/inspections/#{draft_inspection.id}.pdf"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")
      end
    end

    context "when inspection is complete" do
      let(:complete_inspection) { create_completed_inspection(user: user, unit: unit) }

      it "shows minimal PDF viewer for HTML requests" do
        # Logout first
        delete logout_path

        get "/inspections/#{complete_inspection.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("text/html; charset=utf-8")
        expect(response.body).to include("<iframe")
      end

      it "allows public PDF access" do
        # Logout first
        delete logout_path

        get "/inspections/#{complete_inspection.id}.pdf"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")
      end
    end
  end

  describe "Authenticated access to inspection" do
    let(:inspection) { create(:inspection, user: user, unit: unit, complete_date: nil) }

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
