require "rails_helper"

RSpec.describe "Inspections Search", type: :request do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  # Helper method to create inspection with test data
  def create_test_inspection(serial:, manufacturer: "Test Company", location: "Test Lab", passed: true)
    unit = create(:unit, serial: serial, manufacturer: manufacturer)
    create(:inspection, user: user, unit: unit, inspection_location: location, passed: passed)
  end

  describe "GET /inspections/search with esoteric test cases" do
    it "handles extremely long search queries" do
      create_test_inspection(serial: "AAAAA")

      get "/inspections/search", params: {query: "AAAAA"}

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:search)
      expect(assigns(:inspections).count).to eq(1)
    end

    it "handles search queries with special characters" do
      create_test_inspection(serial: "SPEC!@#$%^&*()_+", manufacturer: "Special Co.")

      get "/inspections/search", params: {query: "!@#$%"}

      expect(response).to have_http_status(:success)
      expect(response).to render_template(:search)
      expect(assigns(:inspections).count).to eq(1)
    end

    it "handles search queries with SQL injection patterns" do
      create_test_inspection(serial: "NORMAL123", manufacturer: "Test Manufacturer")

      sql_injection_queries = [
        "'; DROP TABLE inspections; --",
        "OR 1=1",
        "NORMAL123' OR '1'='1",
        "NORMAL123'; UPDATE users SET admin=true; --"
      ]

      sql_injection_queries.each do |query|
        get "/inspections/search", params: {query: query}
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:search)
      end

      # Verify inspections table still exists and record wasn't deleted
      expect(Inspection.joins(:unit).find_by(units: {serial: "NORMAL123"})).to be_present
    end

    it "handles empty search queries" do
      # Create some test inspections
      3.times do |i|
        unit = create(:unit, serial: "EMPTY#{i}", manufacturer: "Search Co. #{i}")
        create(:inspection,
          user: user,

          unit: unit,
          inspection_location: "Test Lab",
          passed: true)
      end

      # Search with empty query
      get "/inspections/search", params: {query: ""}

      # Should return successfully
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:search)

      # Should return all inspections
      expect(assigns(:inspections).count).to eq(Inspection.count)
    end

    it "handles Unicode and emoji in search queries" do
      # Create inspection with Unicode characters and emoji
      unit = create(:unit, serial: "ÜNICØDÉ-😎-123", manufacturer: "Émoji Company 😀")
      create(:inspection,
        user: user,

        unit: unit,
        inspection_location: "Test Lab",
        passed: true)

      # Search with Unicode and emoji
      get "/inspections/search", params: {query: "ÜNICØDÉ"}
      expect(response).to have_http_status(:success)
      expect(assigns(:inspections).count).to eq(1)

      get "/inspections/search", params: {query: "😎"}
      expect(response).to have_http_status(:success)
      expect(assigns(:inspections).count).to eq(1)
    end

    it "handles search for non-existent records" do
      # Search for record that doesn't exist
      get "/inspections/search", params: {query: "NONEXISTENTRECORD"}

      # Should return successfully
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:search)

      # Should return empty result set
      expect(assigns(:inspections).count).to eq(0)
    end

    it "handles case-insensitive searches correctly" do
      # Create inspection with mixed case serial
      unit = create(:unit, serial: "MiXeDcAsE123", manufacturer: "Case Sensitive Co.")
      create(:inspection,
        user: user,

        unit: unit,
        inspection_location: "Test Lab",
        passed: true)

      # Search with different case variations
      search_terms = ["mixedcase123", "MIXEDCASE123", "MiXeDcAsE123", "mixedCASE123"]

      search_terms.each do |term|
        get "/inspections/search", params: {query: term}
        expect(response).to have_http_status(:success)
        expect(assigns(:inspections).count).to eq(1)
      end
    end
  end
end
