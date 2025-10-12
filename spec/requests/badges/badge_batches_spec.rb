# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BadgeBatches", type: :request do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :active_user) }

  describe "Authentication" do
    it "redirects to login when not logged in" do
      get badge_batches_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "Authorization" do
    before { login_as(regular_user) }

    it "denies access to regular users" do
      get badge_batches_path
      expect(response).to redirect_to(root_path)
      admin_required_msg = I18n.t("forms.session_new.status.admin_required")
      expect(flash[:alert]).to include(admin_required_msg)
    end
  end

  describe "Badge batch creation" do
    before { login_as(admin_user) }

    it "creates batch with specified count" do
      params = {badge_batch: {count: 10, note: "Test"}}
      expect {
        post badge_batches_path, params: params
      }.to change(BadgeBatch, :count).by(1)
        .and change(Badge, :count).by(10)
    end

    it "stores count on the batch" do
      params = {badge_batch: {count: 10, note: "Test"}}
      post badge_batches_path, params: params
      expect(BadgeBatch.last.count).to eq(10)
    end
  end

  describe "Edge cases" do
    before { login_as(admin_user) }

    it "returns 404 for missing badge batch" do
      get badge_batch_path(99999)
      expect(response).to have_http_status(:not_found)
    end
  end
end
