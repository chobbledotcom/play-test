require "rails_helper"

RSpec.describe "Admin User Management", type: :request do
  before do
    # Clear all users
    User.destroy_all

    # Create admin user (first user)
    @admin = User.create!(
      email: "admin@example.com",
      password: "password",
      password_confirmation: "password"
    )

    # Create regular user
    @regular_user = User.create!(
      email: "regular@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  describe "as admin user" do
    before do
      post login_path, params: {session: {email: @admin.email, password: "password"}}
    end

    it "can access users index" do
      get users_path
      expect(response).to have_http_status(:success)
    end

    it "can edit other users" do
      get edit_user_path(@regular_user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "as regular user" do
    before do
      post login_path, params: {session: {email: @regular_user.email, password: "password"}}
    end

    it "cannot access users index" do
      get users_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:danger]).to be_present
    end

    it "cannot edit other users" do
      get edit_user_path(@admin)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:danger]).to be_present
    end
  end
end
