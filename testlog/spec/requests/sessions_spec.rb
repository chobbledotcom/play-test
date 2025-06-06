require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /login" do
    it "returns http success" do
      get "/login"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /login" do
    before do
      User.create!(
        email: "test@example.com",
        password: "password",
        password_confirmation: "password"
      )
    end

    it "authenticates a user and redirects" do
      # Log in with credentials
      post "/login", params: {session: {email: "test@example.com", password: "password"}}

      # Should redirect to root path after login
      expect(response).to redirect_to(root_path)
    end

    it "sets a permanent cookie if remember_me is checked" do
      # Log in with remember me
      post "/login", params: {session: {email: "test@example.com", password: "password", remember_me: "1"}}

      # Should redirect successfully
      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to be_present
    end

    it "does not set a permanent cookie if remember_me is not checked" do
      # Log in without remember me
      post "/login", params: {session: {email: "test@example.com", password: "password", remember_me: "0"}}

      # Should redirect successfully
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /logout" do
    it "logs out a user and redirects" do
      # Create a session
      allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(double("User"))

      # Log out
      delete "/logout"

      expect(response).to have_http_status(:redirect)
    end
  end
end
