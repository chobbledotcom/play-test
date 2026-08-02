# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rate limiting", type: :request do
  it "limits password guessing by IP address" do
    user = create(:user, password: "password123")
    params = {
      session: {email: user.email, password: "wrong-password"}
    }

    10.times do
      post "/login", params: params
      expect(response).to have_http_status(:unprocessable_content)
    end

    post "/login", params: params
    expect(response).to have_http_status(:too_many_requests)
  end

  it "limits account registrations by IP address" do
    invalid_params = {
      user: {
        email: "",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    5.times do
      post "/register", params: invalid_params
      expect(response).to have_http_status(:unprocessable_content)
    end

    post "/register", params: invalid_params
    expect(response).to have_http_status(:too_many_requests)
  end

  it "limits anonymous inspection ID lookups before resource loading" do
    30.times do
      get "/inspections/nonexistent"
      expect(response).to have_http_status(:not_found)
    end

    get "/inspections/nonexistent"
    expect(response).to have_http_status(:too_many_requests)
  end
end
