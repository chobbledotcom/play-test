# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Badges", type: :request do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :active_user) }
  let(:batch) { create(:badge_batch) }
  let(:badge) { create(:badge, badge_batch: batch) }

  describe "Authentication" do
    it "redirects to login when not logged in" do
      get edit_badge_path(badge)
      expect(response).to redirect_to(login_path)
    end
  end

  describe "Authorization" do
    before { login_as(regular_user) }

    it "denies access to regular users" do
      get edit_badge_path(badge)
      expect(response).to redirect_to(root_path)
      admin_required_msg = I18n.t("forms.session_new.status.admin_required")
      expect(flash[:alert]).to include(admin_required_msg)
    end
  end

  describe "Badge edit" do
    before { login_as(admin_user) }

    it "returns http success" do
      get edit_badge_path(badge)
      expect(response).to have_http_status(:success)
    end

    it "shows badge and batch details" do
      get edit_badge_path(badge)
      expect(response.body).to include(badge.id)
      expect(response.body).to include(batch.id.to_s)
    end
  end

  describe "Badge updates" do
    before { login_as(admin_user) }

    it "updates badge note and redirects to batch edit" do
      patch badge_path(badge), params: { badge: { note: "Updated note" } }
      badge.reload
      expect(badge.note).to eq("Updated note")
      expect(response).to redirect_to(edit_badge_batch_path(batch))
    end
  end

  describe "Edge cases" do
    before { login_as(admin_user) }

    it "returns 404 for missing badge" do
      get edit_badge_path("INVALID1")
      expect(response).to have_http_status(:not_found)
    end
  end
end
