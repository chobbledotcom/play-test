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

  describe "Badge search" do
    before { login_as(admin_user) }

    it "redirects to badge edit when badge exists" do
      batch = create(:badge_batch)
      badge = create(:badge, badge_batch: batch)

      get search_badge_batches_path, params: {query: badge.id}
      expect(response).to redirect_to(edit_badge_path(badge))
      expect(flash[:success]).to be_present
    end

    it "redirects to index with error when badge not found" do
      get search_badge_batches_path, params: {query: "NOTFOUND"}
      expect(response).to redirect_to(badge_batches_path)
      expect(flash[:alert]).to be_present
    end

    it "redirects to index when query is blank" do
      get search_badge_batches_path, params: {query: ""}
      expect(response).to redirect_to(badge_batches_path)
    end
  end

  describe "CSV export" do
    before do
      login_as(admin_user)
      timestamp = Time.current
      Unit.insert(
        {
          id: "BADGE001",
          user_id: admin_user.id,
          name: "Test Unit",
          serial: "TEST123",
          description: "Test",
          manufacturer: "Test Mfg",
          created_at: timestamp,
          updated_at: timestamp
        }
      )
    end

    let(:badge_batch) { create(:badge_batch, note: "Test Batch") }
    let!(:badge1) do
      create(:badge, id: "BADGE001", badge_batch: badge_batch)
    end
    let!(:badge2) do
      badge_note = "Test Note"
      create(:badge, id: "BADGE002", badge_batch: badge_batch, note: badge_note)
    end

    it "exports CSV with correct headers" do
      get export_badge_batch_path(badge_batch)
      expect(response).to have_http_status(:success)
      expect(response.headers["Content-Type"]).to include("text/csv")

      csv_lines = response.body.split("\n")
      headers = csv_lines.first
      expected = "Badge ID,Batch Creation Date,Batch Notes,Badge Notes,Used,URL"
      expect(headers).to eq(expected)
    end

    it "includes badge data in CSV" do
      get export_badge_batch_path(badge_batch)

      csv = CSV.parse(response.body, headers: true)
      expect(csv.length).to eq(2)

      badge1_row = csv.find { |row| row["Badge ID"] == "BADGE001" }
      expect(badge1_row["Used"]).to eq("true")
      expect(badge1_row["Batch Notes"]).to eq("Test Batch")
      expect(badge1_row["Badge Notes"]).to eq("")
      expect(badge1_row["URL"]).to include("/units/BADGE001.pdf")

      badge2_row = csv.find { |row| row["Badge ID"] == "BADGE002" }
      expect(badge2_row["Used"]).to eq("false")
      expect(badge2_row["Badge Notes"]).to eq("Test Note")
    end

    it "returns CSV with correct filename" do
      get export_badge_batch_path(badge_batch)
      filename = response.headers["Content-Disposition"]
      expect(filename).to include("badge-batch-#{badge_batch.id}")
      expect(filename).to include(".csv")
    end
  end

  describe "Edge cases" do
    before { login_as(admin_user) }

    it "returns 404 for missing badge batch" do
      get edit_badge_batch_path(99999)
      expect(response).to have_http_status(:not_found)
    end
  end
end
