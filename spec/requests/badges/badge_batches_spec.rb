# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BadgeBatches", type: :request do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :active_user) }

  describe "Authentication requirements" do
    it "redirects to login when not logged in" do
      get badge_batches_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "Authorization requirements" do
    before { login_as(regular_user) }

    it "denies access to regular users" do
      get badge_batches_path
      expect(response).to redirect_to(root_path)
      admin_required_msg = I18n.t("forms.session_new.status.admin_required")
      expect(flash[:alert]).to include(admin_required_msg)
    end
  end

  describe "When logged in as admin" do
    before { login_as(admin_user) }

    describe "GET /badges" do
      it "returns http success" do
        get badge_batches_path
        expect(response).to have_http_status(:success)
      end

      it "lists badge batches" do
        batch = create(:badge_batch, :with_badges)
        get badge_batches_path
        expect(response.body).to include(batch.id.to_s)
      end
    end

    describe "GET /badges/new" do
      it "returns http success" do
        get new_badge_batch_path
        expect(response).to have_http_status(:success)
      end

      it "assigns a new badge batch" do
        get new_badge_batch_path
        expect(assigns(:badge_batch)).to be_a_new(BadgeBatch)
      end
    end

    describe "POST /badges" do
      let(:valid_params) { {badge_batch: {count: 10, note: "Test batch"}} }

      it "creates a new badge batch" do
        expect {
          post badge_batches_path, params: valid_params
        }.to change(BadgeBatch, :count).by(1)
      end

      it "creates the specified number of badges" do
        expect {
          post badge_batches_path, params: valid_params
        }.to change(Badge, :count).by(10)
      end

      it "stores count on the batch" do
        post badge_batches_path, params: valid_params
        batch = BadgeBatch.last
        expect(batch.count).to eq(10)
      end

      it "redirects to the created badge batch" do
        post badge_batches_path, params: valid_params
        expect(response).to redirect_to(badge_batch_path(BadgeBatch.last))
      end

      it "sets a success flash message" do
        post badge_batches_path, params: valid_params
        expect(flash[:success]).to be_present
      end
    end

    describe "GET /badges/:id" do
      it "returns http success" do
        batch = create(:badge_batch, :with_badges)
        get badge_batch_path(batch)
        expect(response).to have_http_status(:success)
      end

      it "shows individual badges" do
        batch = create(:badge_batch)
        badge = create(:badge, badge_batch: batch)
        get badge_batch_path(batch)
        expect(response.body).to include(badge.id)
      end
    end

    describe "GET /badges/:id/edit" do
      it "returns http success" do
        batch = create(:badge_batch)
        get edit_badge_batch_path(batch)
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /badges/:id" do
      let(:batch) { create(:badge_batch, note: "Original note") }

      it "updates the badge batch note" do
        patch badge_batch_path(batch), params: {badge_batch: {note: "Updated"}}
        batch.reload
        expect(batch.note).to eq("Updated")
      end

      it "redirects to the badge batch" do
        patch badge_batch_path(batch), params: {badge_batch: {note: "Updated"}}
        expect(response).to redirect_to(badge_batch_path(batch))
      end

      it "sets a success flash message" do
        patch badge_batch_path(batch), params: {badge_batch: {note: "Updated"}}
        expect(flash[:success]).to be_present
      end
    end
  end

  describe "Edge cases" do
    before { login_as(admin_user) }

    it "returns 404 for missing badge batch on show" do
      get badge_batch_path(99999)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for missing badge batch on edit" do
      get edit_badge_batch_path(99999)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for missing badge batch on update" do
      patch badge_batch_path(99999), params: {badge_batch: {note: "Test"}}
      expect(response).to have_http_status(:not_found)
    end
  end
end
