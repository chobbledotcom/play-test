# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Badges", type: :request do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :active_user) }
  let(:batch) { create(:badge_batch) }
  let(:badge) { create(:badge, badge_batch: batch) }

  describe "Authentication requirements" do
    it "redirects to login when not logged in" do
      get edit_badge_path(badge)
      expect(response).to redirect_to(login_path)
    end
  end

  describe "Authorization requirements" do
    before { login_as(regular_user) }

    it "denies access to regular users" do
      get edit_badge_path(badge)
      expect(response).to redirect_to(root_path)
      admin_required_msg = I18n.t("forms.session_new.status.admin_required")
      expect(flash[:alert]).to include(admin_required_msg)
    end
  end

  describe "When logged in as admin" do
    before { login_as(admin_user) }

    describe "GET /unit_badges/:id/edit" do
      it "returns http success" do
        get edit_badge_path(badge)
        expect(response).to have_http_status(:success)
      end

      it "assigns the badge" do
        get edit_badge_path(badge)
        expect(assigns(:badge)).to eq(badge)
      end
    end

    describe "PATCH /unit_badges/:id" do
      it "updates the badge note" do
        patch badge_path(badge), params: {badge: {note: "Updated note"}}
        badge.reload
        expect(badge.note).to eq("Updated note")
      end

      it "redirects to the badge batch" do
        patch badge_path(badge), params: {badge: {note: "Updated note"}}
        expect(response).to redirect_to(badge_batch_path(batch))
      end

      it "sets a success flash message" do
        patch badge_path(badge), params: {badge: {note: "Updated note"}}
        expect(flash[:success]).to be_present
      end
    end
  end

  describe "Edge cases" do
    before { login_as(admin_user) }

    it "returns 404 for missing badge on edit" do
      get edit_badge_path("INVALID1")
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for missing badge on update" do
      patch badge_path("INVALID1"), params: {badge: {note: "Test"}}
      expect(response).to have_http_status(:not_found)
    end
  end
end
