require "rails_helper"

RSpec.describe "Inspector Companies Archive", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let!(:company) { create(:inspector_company, name: "Archive Test Company") }

  describe "PATCH /inspector_companies/:id/archive" do
    context "when logged in as admin" do
      before do
        login_as(admin)
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

      it "shows archived company in index with archived status" do
        patch archive_inspector_company_path(company)

        follow_redirect!
        expect(response.body).to include(company.name)
        expect(response.body).to include("Archived") # Shows archived status
      end
    end

    context "when logged in as regular user" do
      before do
        login_as(regular_user)
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
