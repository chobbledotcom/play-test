require "rails_helper"

RSpec.describe "Admin user company management", type: :request do
  let(:admin_user) { create(:user, :without_company, email: "admin@example.com") }
  let(:inspector_company) { create(:inspector_company) }
  let(:user_with_company) { create(:user, inspection_company: inspector_company) }
  let(:user_without_company) { create(:user, :without_company) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_EMAILS_PATTERN").and_return("admin@")
    login_as(admin_user)
  end

  describe "PATCH /users/:id" do
    context "when removing company assignment" do
      it "sets inspection_company_id to nil when empty string is passed" do
        expect(user_with_company.inspection_company_id).to eq(inspector_company.id)

        patch user_path(user_with_company), params: {
          user: {
            email: user_with_company.email,
            inspection_company_id: ""
          }
        }

        expect(response).to redirect_to(users_path)
        follow_redirect!
        expect(response.body).to include(I18n.t("users.messages.user_updated"))

        user_with_company.reload
        expect(user_with_company.inspection_company_id).to be_nil
      end
    end

    context "when assigning a company" do
      it "sets inspection_company_id when valid company id is passed" do
        expect(user_without_company.inspection_company_id).to be_nil

        patch user_path(user_without_company), params: {
          user: {
            email: user_without_company.email,
            inspection_company_id: inspector_company.id
          }
        }

        expect(response).to redirect_to(users_path)

        user_without_company.reload
        expect(user_without_company.inspection_company_id).to eq(inspector_company.id)
      end
    end
  end

  describe "GET /users/:id/edit" do
    it "shows 'No Company' option in select" do
      get edit_user_path(user_with_company)

      expect(response.body).to include(I18n.t("users.forms.no_company"))
      expect(response.body).to include("<option value=\"\">#{I18n.t("users.forms.no_company")}</option>")
    end

    it "shows current company as selected" do
      get edit_user_path(user_with_company)

      expect(response.body).to include("<option selected=\"selected\" value=\"#{inspector_company.id}\">#{inspector_company.name}</option>")
    end

    it "shows 'No Company' as selected when user has no company" do
      get edit_user_path(user_without_company)

      expect(response.body).to include("<option selected=\"selected\" value=\"\">#{I18n.t("users.forms.no_company")}</option>")
    end
  end
end
