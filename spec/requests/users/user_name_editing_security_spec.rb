require "rails_helper"

RSpec.describe "User Name Editing Security", type: :request do
  let(:regular_user) { create(:user, :without_company, name: "Original Name") }

  describe "Parameter tampering protection" do
    before { login_as(regular_user) }

    it "prevents regular users from changing name via parameter tampering" do
      patch update_settings_user_path(regular_user), params: {
        user: {
          name: "Hacked Name",
          theme: "light"
        }
      }

      regular_user.reload

      expect(regular_user.name).to eq("Original Name")

      expect(regular_user.theme).to eq("light")
    end

    it "prevents regular users from changing name via admin edit form tampering" do
      patch user_path(regular_user), params: {
        user: {
          name: "Hacked Name",
          email: regular_user.email
        }
      }

      expect(response).to redirect_to(root_path)

      regular_user.reload

      expect(regular_user.name).to eq("Original Name")
    end
  end
end
