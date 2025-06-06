require "rails_helper"

RSpec.describe "Equipment", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password", password_confirmation: "password") }
  let(:equipment) { Equipment.create!(name: "Test Equipment", serial: "TEST123", location: "Test Location", manufacturer: "Test Manufacturer", user: user) }

  # Create a user and create a session
  before do
    post "/login", params: {session: {email: user.email, password: "password"}}
  end

  describe "GET /equipment" do
    it "returns http success" do
      get "/equipment"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /equipment/:id" do
    it "returns http success" do
      get "/equipment/#{equipment.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /equipment/new" do
    it "returns http success" do
      get "/equipment/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /equipment/:id/edit" do
    it "returns http success" do
      get "/equipment/#{equipment.id}/edit"
      expect(response).to have_http_status(:success)
    end
  end
end
