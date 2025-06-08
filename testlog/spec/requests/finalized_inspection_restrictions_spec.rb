require "rails_helper"

RSpec.describe "Finalized Inspection Restrictions", type: :request do
  let(:regular_user) { create(:user) }
  let(:admin_user) { create(:user, email: "admin@example.com") }
  let(:unit) { create(:unit, user: regular_user) }
  let(:finalized_inspection) do
    inspection = create(:inspection, :completed, user: regular_user, unit: unit)
    # Bypass validation to set finalized status for testing
    inspection.update_column(:status, "finalized")
    inspection
  end

  before do
    # Set up admin pattern
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_EMAILS_PATTERN").and_return("admin@")
  end

  describe "Non-admin user access to finalized inspections" do
    before do
      post "/login", params: {session: {email: regular_user.email, password: "password123"}}
    end

    it "redirects when trying to edit a finalized inspection" do
      get edit_inspection_path(finalized_inspection)

      expect(response).to redirect_to(inspection_path(finalized_inspection))
      expect(flash[:danger]).to eq(I18n.t("inspections.errors.finalized_no_edit"))
    end

    it "redirects when trying to update a finalized inspection" do
      patch inspection_path(finalized_inspection), params: {
        inspection: {comments: "Updated comments"}
      }

      expect(response).to redirect_to(inspection_path(finalized_inspection))
      expect(flash[:danger]).to eq(I18n.t("inspections.errors.finalized_no_edit"))

      # Verify the inspection wasn't updated
      finalized_inspection.reload
      expect(finalized_inspection.comments).not_to eq("Updated comments")
    end

    it "redirects when trying to replace dimensions on a finalized inspection" do
      patch replace_dimensions_inspection_path(finalized_inspection)

      expect(response).to redirect_to(inspection_path(finalized_inspection))
      expect(flash[:danger]).to eq(I18n.t("inspections.errors.finalized_no_edit"))
    end

    it "redirects when trying to destroy a finalized inspection" do
      delete inspection_path(finalized_inspection)

      expect(response).to redirect_to(inspection_path(finalized_inspection))
      expect(flash[:danger]).to eq(I18n.t("inspections.errors.finalized_no_delete"))

      # Verify the inspection wasn't deleted
      expect(Inspection.exists?(finalized_inspection.id)).to be true
    end

    it "allows viewing a finalized inspection" do
      get inspection_path(finalized_inspection)

      expect(response).to have_http_status(:success)
    end

    it "allows accessing report for finalized inspection" do
      get report_inspection_path(finalized_inspection)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
    end

    it "allows accessing QR code for finalized inspection" do
      get qr_code_inspection_path(finalized_inspection)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("image/png")
    end
  end

  describe "Admin user access to finalized inspections" do
    let(:admin_unit) { create(:unit, user: admin_user) }
    let(:admin_finalized_inspection) do
      inspection = create(:inspection, :completed, user: admin_user, unit: admin_unit)
      inspection.update_column(:status, "finalized")
      inspection
    end

    before do
      post "/login", params: {session: {email: admin_user.email, password: "password123"}}
    end

    it "allows admin to edit a finalized inspection" do
      get edit_inspection_path(admin_finalized_inspection)

      expect(response).to have_http_status(:success)
    end

    it "allows admin to update a finalized inspection" do
      patch inspection_path(admin_finalized_inspection), params: {
        inspection: {comments: "Admin updated comments"}
      }

      expect(response).to redirect_to(inspection_path(admin_finalized_inspection))
      expect(flash[:success]).to be_present

      # Verify the inspection was updated
      admin_finalized_inspection.reload
      expect(admin_finalized_inspection.comments).to eq("Admin updated comments")
    end

    it "allows admin to replace dimensions on a finalized inspection" do
      # Update unit dimensions first
      admin_unit.update!(width: 20, length: 20, height: 10)

      patch replace_dimensions_inspection_path(admin_finalized_inspection)

      expect(response).to redirect_to(edit_inspection_path(admin_finalized_inspection, tab: "general"))
      expect(flash[:success]).to eq(I18n.t("inspections.messages.dimensions_replaced"))
    end

    it "allows admin to destroy a finalized inspection" do
      delete inspection_path(admin_finalized_inspection)

      expect(response).to redirect_to(inspections_path)
      expect(flash[:success]).to be_present

      # Verify the inspection was deleted
      expect(Inspection.exists?(admin_finalized_inspection.id)).to be false
    end
  end

  describe "Access to non-finalized inspections" do
    let(:draft_inspection) { create(:inspection, user: regular_user, unit: unit, status: "draft") }
    let(:completed_inspection) { create(:inspection, :completed, user: regular_user, unit: unit) }

    before do
      post "/login", params: {session: {email: regular_user.email, password: "password123"}}
    end

    it "allows regular user to edit draft inspection" do
      get edit_inspection_path(draft_inspection)
      expect(response).to have_http_status(:success)
    end

    it "allows regular user to edit completed inspection" do
      get edit_inspection_path(completed_inspection)
      expect(response).to have_http_status(:success)
    end

    it "allows regular user to update completed inspection" do
      patch inspection_path(completed_inspection), params: {
        inspection: {comments: "Updated by user"}
      }

      expect(response).to redirect_to(inspection_path(completed_inspection))
      expect(flash[:success]).to be_present

      completed_inspection.reload
      expect(completed_inspection.comments).to eq("Updated by user")
    end
  end
end
