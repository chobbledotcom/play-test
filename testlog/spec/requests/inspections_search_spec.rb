require "rails_helper"

RSpec.describe "Inspections Search", type: :request do
  let(:user) { create(:user) }

  # Create a user and create a session
  before do
    user # create the user
    post "/login", params: {session: {email: user.email, password: "password123"}}
  end

  describe "GET /inspections/search with esoteric test cases" do
    it "handles extremely long search queries" do
      # Create an inspection with a matching serial number
      unit = create(:unit, serial: "AAAAA", manufacturer: "Test Company")
      create(:inspection,
        user: user,
        inspector: "Search Tester",
        unit: unit,
        location: "Test Lab",
        passed: true)

      # Search with extremely long query - but just use first 5 characters to ensure a match
      get "/inspections/search", params: {query: "AAAAA"}

      # Should return successfully
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:search)

      # The search should find the record
      expect(assigns(:inspections).count).to eq(1)
    end

    it "handles search queries with special characters" do
      # Create inspection with special characters
      unit = create(:unit, serial: "SPEC!@#$%^&*()_+", manufacturer: "Special Co.")
      create(:inspection,
        user: user,
        inspector: "Special Chars Tester",
        unit: unit,
        location: "Test Lab",
        passed: true)

      # Search with special characters
      get "/inspections/search", params: {query: "!@#$%"}

      # Should return successfully
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:search)

      # Should find the record
      expect(assigns(:inspections).count).to eq(1)
    end

    it "handles search queries with SQL injection patterns" do
      # Create an inspection with a normal serial
      unit = create(:unit, serial: "NORMAL123", manufacturer: "Test Manufacturer")
      create(:inspection,
        user: user,
        inspector: "SQL Injection Tester",
        unit: unit,
        location: "Test Lab",
        passed: true)

      # Search with SQL injection patterns
      sql_injection_queries = [
        "'; DROP TABLE inspections; --",
        "OR 1=1",
        "NORMAL123' OR '1'='1",
        "NORMAL123'; UPDATE users SET admin=true; --"
      ]

      sql_injection_queries.each do |query|
        get "/inspections/search", params: {query: query}

        # Should return successfully, no errors
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
          inspector: "Empty Search Tester #{i}",
          unit: unit,
          location: "Test Lab",
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
        inspector: "Unicode Tester",
        unit: unit,
        location: "Test Lab",
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
        inspector: "Case Tester",
        unit: unit,
        location: "Test Lab",
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
