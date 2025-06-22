require "rails_helper"
require "pdf/inspector"

RSpec.describe "PDF Debug Info for Impersonation", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:unit) { create(:unit, user: regular_user) }
  let(:inspection) { create(:inspection, :completed, user: regular_user, unit: unit) }

  describe "impersonation shows debug info" do
    it "admin impersonating user sees debug info in PDF" do
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

      # Should include debug info when impersonating
      expect(pdf_text).to include(I18n.t("debug.title"))
      expect(pdf_text).to include(I18n.t("debug.query_count"))
    end
  end
end
