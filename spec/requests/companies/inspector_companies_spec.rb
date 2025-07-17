require "rails_helper"

RSpec.describe "InspectorCompanies", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  let(:valid_attributes) { attributes_for(:inspector_company) }
  let(:invalid_attributes) { { name: "", phone: "", address: "" } }

  describe "Authentication requirements" do
    describe "GET /inspector_companies" do
      it "redirects to login when not logged in" do
        visit inspector_companies_path
        expect(page).to have_current_path(login_path)
      end
    end

    describe "GET /inspector_companies/:id" do
      it "redirects to login when not logged in" do
        company = create(:inspector_company)
        visit inspector_company_path(company)
        expect(page).to have_current_path(login_path)
      end
    end

    describe "GET /inspector_companies/new" do
      it "redirects to login when not logged in" do
        visit new_inspector_company_path
        expect(page).to have_current_path(login_path)
      end
    end
  end

  describe "Authorization requirements" do
    before { login_as(regular_user) }

    describe "GET /inspector_companies/new" do
      it "denies access to regular users" do
        get new_inspector_company_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    describe "POST /inspector_companies" do
      it "denies access to regular users" do
        post inspector_companies_path, params: { inspector_company: valid_attributes }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    describe "GET /inspector_companies/:id/edit" do
      it "denies access to regular users" do
        company = create(:inspector_company)
        get edit_inspector_company_path(company)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    describe "PATCH /inspector_companies/:id" do
      it "denies access to regular users" do
        company = create(:inspector_company)
        patch inspector_company_path(company), params: { inspector_company: { name: "Updated Name" } }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "When logged in as regular user" do
    before { login_as(regular_user) }

    it "denies access to inspector companies index" do
      get inspector_companies_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include(I18n.t("forms.session_new.status.admin_required"))
    end

    it "allows access to inspector companies show" do
      company = create(:inspector_company)
      get inspector_company_path(company)
      expect(response).to have_http_status(:success)
    end
  end

  describe "When logged in as admin" do
    before { login_as(admin_user) }

    describe "GET /inspector_companies/new" do
      it "returns http success" do
        get new_inspector_company_path
        expect(response).to have_http_status(:success)
      end

      it "assigns a new inspector company" do
        get new_inspector_company_path
        expect(assigns(:inspector_company)).to be_a_new(InspectorCompany)
      end
    end

    describe "POST /inspector_companies" do
      context "with valid parameters" do
        it "creates a new inspector company" do
          expect {
            post inspector_companies_path, params: { inspector_company: valid_attributes }
          }.to change(InspectorCompany, :count).by(1)
        end

        it "creates company with proper attributes" do
          post inspector_companies_path, params: { inspector_company: valid_attributes }
          company = InspectorCompany.find_by(name: valid_attributes[:name])
          expect(company.name).to eq(valid_attributes[:name])
          # Company no longer has RPII field - that's per-inspector now
        end

        it "redirects to the created inspector company" do
          expect {
            post inspector_companies_path, params: { inspector_company: valid_attributes }
          }.to change(InspectorCompany, :count).by(1)

          created_company = InspectorCompany.find_by(name: valid_attributes[:name])
          expect(response).to redirect_to(created_company)
        end

        it "sets a success flash message" do
          post inspector_companies_path, params: { inspector_company: valid_attributes }
          expect(flash[:notice]).to be_present
        end
      end

      context "with invalid parameters" do
        it "does not create a new inspector company" do
          expect {
            post inspector_companies_path, params: { inspector_company: invalid_attributes }
          }.not_to change(InspectorCompany, :count)
        end

        it "renders the new template" do
          post inspector_companies_path, params: { inspector_company: invalid_attributes }
          expect(response).to render_template(:new)
        end
      end
    end

    describe "GET /inspector_companies/:id/edit" do
      it "returns http success" do
        company = create(:inspector_company)
        get edit_inspector_company_path(company)
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /inspector_companies/:id" do
      let(:company) { create(:inspector_company) }

      context "with valid parameters" do
        let(:new_attributes) do
          {
            name: "Updated Company Name",
            email: "updated@example.com"
          }
        end

        it "updates the requested inspector company" do
          patch inspector_company_path(company), params: { inspector_company: new_attributes }
          company.reload
          expect(company.name).to eq("Updated Company Name")
          expect(company.email).to eq("updated@example.com")
        end

        it "redirects to the inspector company" do
          patch inspector_company_path(company), params: { inspector_company: new_attributes }
          expect(response).to redirect_to(company)
        end

        it "sets a success flash message" do
          patch inspector_company_path(company), params: { inspector_company: new_attributes }
          expect(flash[:notice]).to be_present
        end
      end

      context "with invalid parameters" do
        it "renders the edit template" do
          patch inspector_company_path(company), params: { inspector_company: invalid_attributes }
          expect(response).to render_template(:edit)
        end

        it "does not update the company" do
          original_name = company.name
          patch inspector_company_path(company), params: { inspector_company: invalid_attributes }
          company.reload
          expect(company.name).to eq(original_name)
        end
      end
    end

    describe "Turbo stream responses" do
      let(:company) { create(:inspector_company) }

      context "successful update with turbo stream" do
        it "returns turbo stream with success message" do
          patch inspector_company_path(company),
            params: { inspector_company: { name: "Updated Name" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
          expect(response.body).to include("form_save_message")
          expect(response.body).to include(I18n.t("inspector_companies.messages.updated"))
        end
      end

      context "failed update with turbo stream" do
        it "returns turbo stream with error message" do
          patch inspector_company_path(company),
            params: { inspector_company: { name: "" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
          expect(response.body).to include("form_save_message")
          expect(response.body).to include(I18n.t("shared.messages.save_failed"))
        end
      end
    end

    describe "Admin-only fields" do
      it "allows setting logo field" do
        logo_file = fixture_file_upload("test_image.jpg", "image/jpeg")
        post inspector_companies_path, params: {
          inspector_company: valid_attributes.merge(logo: logo_file)
        }
        company = InspectorCompany.find_by(name: valid_attributes[:name])
        expect(company.logo).to be_attached
      end

      it "allows setting active field" do
        post inspector_companies_path, params: {
          inspector_company: valid_attributes.merge(active: false)
        }
        company = InspectorCompany.find_by(name: valid_attributes[:name])
        expect(company.active).to be false
      end

      it "allows setting notes field" do
        notes = "Admin notes about this company"
        post inspector_companies_path, params: {
          inspector_company: valid_attributes.merge(notes: notes)
        }
        company = InspectorCompany.find_by(name: valid_attributes[:name])
        expect(company.notes).to eq(notes)
      end
    end
  end

  describe "Edge cases" do
    before { login_as(admin_user) }

    it "returns 404 for missing inspector company on show" do
      get inspector_company_path("nonexistent")
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for missing inspector company on edit" do
      get edit_inspector_company_path("nonexistent")
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for missing inspector company on update" do
      patch inspector_company_path("nonexistent"), params: { inspector_company: { name: "Test" } }
      expect(response).to have_http_status(:not_found)
    end
  end
end
