require "rails_helper"

RSpec.describe "Admin User Management", type: :request do
  describe "as admin user" do
    let!(:admin) { create(:chobble_app_user, :admin) }
    let!(:regular_user) { create(:chobble_app_user) }

    before do
      login_as(admin)
    end

    it "can access users index" do
      get users_path
      expect(response).to have_http_status(:success)
    end

    it "can edit other users" do
      get edit_user_path(regular_user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "as regular user" do
    let!(:admin) { create(:chobble_app_user, :admin) }
    let!(:regular_user) { create(:chobble_app_user) }

    before do
      login_as(regular_user)
    end

    it "cannot access users index" do
      get users_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:alert]).to be_present
    end

    it "cannot edit other users" do
      get edit_user_path(admin)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:alert]).to be_present
    end
  end
end
