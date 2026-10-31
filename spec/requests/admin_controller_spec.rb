# typed: false
# frozen_string_literal: true

require "rails_helper"
require "net/http"

RSpec.describe "AdminController", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  describe "access control" do
    it "redirects non-admins away from the admin pages" do
      login_as(regular_user)
      get admin_path
      expect(response).to redirect_to(root_path)

      get admin_releases_path
      expect(response).to redirect_to(root_path)

      get admin_files_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/releases" do
    before { login_as(admin) }

    it "renders the no-releases message when the API fails" do
      api_response = Net::HTTPResponse.new("1.1", "500", "Error")
      api_response.instance_variable_set(:@read, true)
      api_response.instance_variable_set(:@body, "oops")
      allow_any_instance_of(AdminController)
        .to receive(:make_github_api_request)
        .and_return(api_response)

      get admin_releases_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(I18n.t("admin.releases.no_releases"))
    end
  end
end
