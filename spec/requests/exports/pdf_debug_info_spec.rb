# typed: false

require "rails_helper"
require "pdf/inspector"

RSpec.describe "PDF Debug Info", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:unit) { create(:unit, user: regular_user) }
  let(:inspection) { create(:inspection, :completed, user: regular_user, unit: unit) }

  describe "debug info visibility" do
    context "in production mode" do
      before do
        allow(Rails.env).to receive(:development?).and_return(false)
      end

      it "admin does not see debug info in PDF" do
        login_as(admin_user)

        # Create unit and inspection for admin
        admin_unit = create(:unit, user: admin_user)
        admin_inspection = create(:inspection, :completed, user: admin_user, unit: admin_unit)

        # Get the PDF
        get "/inspections/#{admin_inspection.id}.pdf"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")

        # Extract PDF text
        pdf_text = PDF::Inspector::Text.analyze(response.body).strings.join(" ")

        # Should NOT include debug info for admin in production
        expect(pdf_text).not_to include(I18n.t("debug.title"))
        expect(pdf_text).not_to include(I18n.t("debug.query_count"))
      end

      it "admin impersonating user does not see debug info in PDF" do
        # Login as admin
        login_as(admin_user)

        # Impersonate regular user
        post impersonate_user_path(regular_user)

        # Verify impersonation is active
        expect(session[:original_admin_id]).to eq(admin_user.id)
        expect(session[:user_id]).to eq(regular_user.id)

        # Get the PDF
        get "/inspections/#{inspection.id}.pdf"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")

        # Extract PDF text
        pdf_text = PDF::Inspector::Text.analyze(response.body).strings.join(" ")

        # Should NOT include debug info when impersonating in production
        expect(pdf_text).not_to include(I18n.t("debug.title"))
        expect(pdf_text).not_to include(I18n.t("debug.query_count"))
      end
    end

    context "in development mode" do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "shows debug info in PDF" do
        login_as(regular_user)

        # Get the PDF
        get "/inspections/#{inspection.id}.pdf"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")

        # Extract PDF text
        pdf_text = PDF::Inspector::Text.analyze(response.body).strings.join(" ")

        # Should include debug info in development
        expect(pdf_text).to include(I18n.t("debug.title"))
        expect(pdf_text).to include(I18n.t("debug.query_count"))
      end
    end
  end
end
