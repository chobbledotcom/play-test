require "rails_helper"

RSpec.describe "User Name Editing Security", type: :request do
  let(:regular_user) { create(:user, :without_company, name: "Original Name") }

  describe "Parameter tampering protection" do
    before { login_as(regular_user) }

    it "prevents regular users from changing name via parameter tampering" do
      # Attempt to change name through settings update
      patch update_settings_user_path(regular_user), params: {
        user: {
          name: "Hacked Name",
          default_inspection_location: "Test Location"
        }
      }

      regular_user.reload
      # Name should not have changed due to controller parameter restrictions
      expect(regular_user.name).to eq("Original Name")
      # But allowed fields should have changed
      expect(regular_user.default_inspection_location).to eq("Test Location")
    end

    it "prevents regular users from changing name via admin edit form tampering" do
      # Attempt to use admin edit endpoint (should be blocked by authorization)
      patch user_path(regular_user), params: {
        user: {
          name: "Hacked Name",
          email: regular_user.email
        }
      }

      # Should redirect due to unauthorized access
      expect(response).to redirect_to(root_path)

      regular_user.reload
      # Name should not have changed
      expect(regular_user.name).to eq("Original Name")
    end
  end
end
