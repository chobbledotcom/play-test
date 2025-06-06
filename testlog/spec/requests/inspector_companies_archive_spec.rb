require "rails_helper"

RSpec.describe "Inspector Companies Archive", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let!(:company) { create(:inspector_company, user: admin, name: "Archive Test Company") }

  describe "PATCH /inspector_companies/:id/archive" do
    context "when logged in as admin" do
      before do
        post login_path, params: {session: {email: admin.email, password: I18n.t("test.password")}}
      end

      it "archives the company" do
        expect(company.active).to be true

        patch archive_inspector_company_path(company)

        expect(response).to redirect_to(inspector_companies_path)
        expect(flash[:success]).to eq(I18n.t("inspector_companies.messages.archived"))

        company.reload
        expect(company.active).to be false
      end

      it "redirects to inspector companies index" do
        patch archive_inspector_company_path(company)

        expect(response).to redirect_to(inspector_companies_path)
      end

      it "sets success flash message" do
        patch archive_inspector_company_path(company)

        follow_redirect!
        expect(response.body).to include(I18n.t("inspector_companies.messages.archived"))
      end

      it "removes archived company from index" do
        patch archive_inspector_company_path(company)

        follow_redirect!
        expect(response.body).not_to include(company.name)
      end
    end

    context "when logged in as regular user" do
      before do
        post login_path, params: {session: {email: regular_user.email, password: I18n.t("test.password")}}
      end

      it "denies access" do
        patch archive_inspector_company_path(company)

        expect(response).to redirect_to(root_path)
        expect(flash[:danger]).to eq(I18n.t("inspector_companies.messages.unauthorized"))

        company.reload
        expect(company.active).to be true
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        patch archive_inspector_company_path(company)

        expect(response).to redirect_to(login_path)
        expect(flash[:danger]).to include("Please log in")
      end
    end
  end
end
