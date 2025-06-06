require "rails_helper"

RSpec.describe "Admin User Management", type: :request do
  describe "as admin user" do
    let!(:admin) { create(:user, :admin) }
    let!(:regular_user) { create(:user) }

    before do
      post login_path, params: {session: {email: admin.email, password: I18n.t("test.password")}}
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
    let!(:admin) { create(:user, :admin) }
    let!(:regular_user) { create(:user) }

    before do
      post login_path, params: {session: {email: regular_user.email, password: I18n.t("test.password")}}
    end

    it "cannot access users index" do
      get users_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:danger]).to be_present
    end

    it "cannot edit other users" do
      get edit_user_path(admin)
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:danger]).to be_present
    end
  end
end
