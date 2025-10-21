# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unit Badges Security", type: :request do
  let(:user_a) { create(:user) }
  let(:user_b) { create(:user) }
  let(:badge_batch) { create(:badge_batch, count: 1) }
  let(:badge) { create(:badge, badge_batch: badge_batch) }

  describe "POST /inspections with unit_id parameter" do
    context "when UNIT_BADGES is enabled" do
      around { |example| with_unit_badges_enabled(&example) }

      before do
        login_as(user_b)
      end

      it "allows creating inspection for another user's unit" do
        # User A creates a unit with badge
        unit = create(:unit, id: badge.id, user: user_a)

        # User B creates inspection for User A's unit
        post "/inspections", params: {unit_id: unit.id}

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)
        expect(flash[:notice]).to match(/created/i)

        inspection = Inspection.order(created_at: :desc).first
        expect(inspection.user_id).to eq(user_b.id)
        expect(inspection.unit_id).to eq(unit.id)
      end

      it "allows multiple users to create inspections for same unit" do
        unit = create(:unit, id: badge.id, user: user_a)
        create(:inspection, :completed, unit: unit, user: user_a)

        # User B creates inspection
        post "/inspections", params: {unit_id: unit.id}

        expect(response).to have_http_status(:redirect)
        query = Inspection.where(user_id: user_b.id, unit_id: unit.id)
        inspection = query.first
        expect(inspection).to be_present
      end
    end

    context "when UNIT_BADGES is disabled" do
      around { |example| with_unit_badges_disabled(&example) }

      before do
        login_as(user_b)
      end

      it "prevents creating inspection for another user's unit" do
        # User A creates a unit (without badges)
        unit = create(:unit, user: user_a)

        # User B attempts to create inspection for User A's unit
        post "/inspections", params: {unit_id: unit.id}

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to("/")
        expect(flash[:alert]).to match(/invalid unit/i)

        inspection = Inspection.where(user_id: user_b.id, unit_id: unit.id)
        expect(inspection).to be_empty
      end

      it "allows creating inspection for own unit only" do
        # User B creates their own unit
        unit = create(:unit, user: user_b)

        # User B creates inspection for their own unit
        post "/inspections", params: {unit_id: unit.id}

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)
        expect(flash[:notice]).to match(/created/i)

        query = Inspection.where(user_id: user_b.id, unit_id: unit.id)
        inspection = query.first
        expect(inspection).to be_present
      end

      it "prevents malicious unit_id injection via POST" do
        unit_a = create(:unit, user: user_a)

        # Direct POST attempt with another user's unit_id
        post "/inspections",
          params: {unit_id: unit_a.id},
          headers: {"HTTP_REFERER" => "/inspections"}

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to("/")
        expect(flash[:alert]).to match(/invalid unit/i)

        inspections = Inspection.where(unit_id: unit_a.id, user_id: user_b.id)
        expect(inspections).to be_empty
      end

      it "prevents malicious inspection params with wrong unit_id" do
        unit_a = create(:unit, user: user_a)

        # Attempt with nested inspection params
        post "/inspections",
          params: {
            inspection: {
              unit_id: unit_a.id,
              inspection_date: Date.current,
              passed: true
            }
          }

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to("/")
        expect(flash[:alert]).to match(/invalid unit/i)

        inspections = Inspection.where(unit_id: unit_a.id, user_id: user_b.id)
        expect(inspections).to be_empty
      end
    end
  end

  describe "security boundary enforcement" do
    around { |example| with_unit_badges_disabled(&example) }

    before do
      login_as(user_b)
    end

    it "does not allow bypassing unit ownership via multiple params" do
      unit_a = create(:unit, user: user_a)

      # Try both parameter formats simultaneously
      post "/inspections",
        params: {
          unit_id: unit_a.id,
          inspection: {unit_id: unit_a.id}
        }

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to match(/invalid unit/i)

      inspections = Inspection.where(unit_id: unit_a.id, user_id: user_b.id)
      expect(inspections).to be_empty
    end

    it "prevents inspection creation via JSON API with wrong unit" do
      unit_a = create(:unit, user: user_a)

      post "/inspections.json",
        params: {unit_id: unit_a.id}.to_json,
        headers: {"CONTENT_TYPE" => "application/json"}

      expect(response.status).to be_between(300, 499)

      inspections = Inspection.where(unit_id: unit_a.id, user_id: user_b.id)
      expect(inspections).to be_empty
    end

    it "validates unit ownership on every request, not cached" do
      unit_b = create(:unit, user: user_b)

      # First request with own unit - succeeds
      post "/inspections", params: {unit_id: unit_b.id}
      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response).to have_http_status(:success)

      # Second request with another user's unit - fails
      unit_a = create(:unit, user: user_a)
      post "/inspections", params: {unit_id: unit_a.id}

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to("/")
      expect(flash[:alert]).to match(/invalid unit/i)
    end
  end

  describe "PATCH /inspections/:id with unit_id update" do
    context "when UNIT_BADGES is enabled" do
      around { |example| with_unit_badges_enabled(&example) }

      before do
        login_as(user_b)
      end

      it "allows updating inspection to use another user's unit" do
        # User A creates a unit with badge
        unit_a = create(:unit, id: badge.id, user: user_a)

        # User B creates their own inspection (without a unit initially)
        inspection = create(:inspection, user: user_b, unit: nil)

        # User B updates their inspection to use User A's unit
        patch "/inspections/#{inspection.id}",
          params: {inspection: {unit_id: unit_a.id}}

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        inspection.reload
        expect(inspection.unit_id).to eq(unit_a.id)
      end

      it "allows changing from one badge unit to another" do
        unit_a = create(:unit, id: badge.id, user: user_a)
        badge_b = create(:badge)
        unit_b = create(:unit, id: badge_b.id, user: user_a)

        # User B creates inspection with unit_a
        inspection = create(:inspection, user: user_b, unit: unit_a)

        # User B changes to unit_b (also owned by user_a)
        patch "/inspections/#{inspection.id}",
          params: {inspection: {unit_id: unit_b.id}}

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        inspection.reload
        expect(inspection.unit_id).to eq(unit_b.id)
      end
    end

    context "when UNIT_BADGES is disabled" do
      around { |example| with_unit_badges_disabled(&example) }

      before do
        login_as(user_b)
      end

      it "prevents updating to use another user's unit" do
        unit_a = create(:unit, user: user_a)
        inspection = create(:inspection, user: user_b, unit: nil)

        # User B tries to update to use User A's unit
        patch "/inspections/#{inspection.id}",
          params: {inspection: {unit_id: unit_a.id}}

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to match(/invalid unit/i)

        inspection.reload
        expect(inspection.unit_id).to be_nil
      end

      it "allows updating inspection to use own unit" do
        unit_b = create(:unit, user: user_b)
        inspection = create(:inspection, user: user_b, unit: nil)

        # User B updates their inspection to use their own unit
        patch "/inspections/#{inspection.id}",
          params: {inspection: {unit_id: unit_b.id}}

        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:success)

        inspection.reload
        expect(inspection.unit_id).to eq(unit_b.id)
      end

      it "prevents changing from own to another user's unit" do
        unit_a = create(:unit, user: user_a)
        unit_b = create(:unit, user: user_b)
        inspection = create(:inspection, user: user_b, unit: unit_b)

        # User B tries to change to User A's unit
        patch "/inspections/#{inspection.id}",
          params: {inspection: {unit_id: unit_a.id}}

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to match(/invalid unit/i)

        inspection.reload
        expect(inspection.unit_id).to eq(unit_b.id)
      end
    end
  end

  describe "edge cases and attack vectors" do
    around { |example| with_unit_badges_disabled(&example) }

    before do
      login_as(user_b)
    end

    it "handles non-existent unit_id gracefully" do
      post "/inspections", params: {unit_id: "FAKEID1"}

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to("/")
      expect(flash[:alert]).to match(/invalid unit/i)
    end

    it "handles empty unit_id without error" do
      post "/inspections", params: {unit_id: ""}

      expect(response).to have_http_status(:redirect)
    end

    it "handles nil unit_id without error" do
      post "/inspections", params: {unit_id: nil}

      expect(response).to have_http_status(:redirect)
    end

    it "prevents SQL injection via unit_id" do
      unit_a = create(:unit, user: user_a)

      malicious_ids = [
        "#{unit_a.id}' OR '1'='1",
        "#{unit_a.id}; DROP TABLE units;--",
        "#{unit_a.id}' UNION SELECT * FROM users--"
      ]

      malicious_ids.each do |malicious_id|
        post "/inspections", params: {unit_id: malicious_id}

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to("/")
        expect(flash[:alert]).to match(/invalid unit/i)

        count = Inspection.where(user_id: user_b.id, unit_id: unit_a.id).count
        expect(count).to eq(0)
      end
    end
  end
end
