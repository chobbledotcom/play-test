require "rails_helper"

RSpec.describe "Inspector Companies", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  describe "Access control" do
    context "when not logged in" do
      it "redirects to login page" do
        visit inspector_companies_path

        expect(page).to have_current_path(login_path)
      end
    end

    context "when logged in as regular user" do
      before do
        login_user_via_form(regular_user)
      end

      it "prevents access to inspector companies" do
        visit inspector_companies_path

        expect(page).to have_current_path(root_path)
        expect(page).to have_content(I18n.t("inspector_companies.messages.unauthorized"))
      end

      it "does not show inspector companies link in navigation" do
        expect(page).not_to have_link(I18n.t("inspector_companies.titles.index"))
      end
    end

    context "when logged in as admin" do
      before do
        login_user_via_form(admin_user)
      end

      it "allows access to inspector companies" do
        visit inspector_companies_path

        expect(page).to have_current_path(inspector_companies_path)
        expect(page).to have_content(I18n.t("inspector_companies.titles.index"))
      end

      it "shows inspector companies link in navigation" do
        expect(page).to have_link(I18n.t("inspector_companies.titles.index"))
      end
    end
  end

  describe "Inspector Companies Index", js: false do
    before do
      login_user_via_form(admin_user)
    end

    context "with only admin's company" do
      it "shows the company list with minimal data" do
        visit inspector_companies_path

        # Should show at least the admin user's company
        expect(page).to have_content(admin_user.inspection_company.name)
        expect(page).to have_button(I18n.t("inspector_companies.buttons.new_company"))

        # Check the table exists
        expect(page).to have_css("table")
      end
    end

    context "with existing companies" do
      let!(:company1) { create(:inspector_company, name: "Test Company 1") }
      let!(:company2) { create(:inspector_company, name: "Test Company 2") }
      let!(:archived_company) { create(:inspector_company, name: "Archived Company", active: false) }

      it "displays all companies in table by default" do
        visit inspector_companies_path

        expect(page).to have_content(company1.name)
        expect(page).to have_content(company2.name)
        expect(page).to have_content(archived_company.name)
      end

      it "allows searching by company name" do
        visit inspector_companies_path

        fill_in I18n.t("inspector_companies.search.placeholder"), with: "Test Company 1"
        # Since we can't simulate Enter key in tests, visit the URL with search params
        visit inspector_companies_path(search: "Test Company 1")

        expect(page).to have_content(company1.name)
        expect(page).not_to have_content(company2.name)
      end

      it "allows filtering by active status" do
        visit inspector_companies_path(active: "active")

        expect(page).to have_content(company1.name)
        expect(page).to have_content(company2.name)
        expect(page).not_to have_content(archived_company.name)
      end

      it "shows action links for each company" do
        visit inspector_companies_path

        within("table tbody") do
          expect(page).to have_link(I18n.t("ui.view"))
          expect(page).to have_link(I18n.t("ui.edit"))
        end
      end
    end
  end

  describe "Creating Inspector Company" do
    before do
      login_user_via_form(admin_user)
    end

    it "displays the new company form" do
      visit new_inspector_company_path

      expect(page).to have_content(I18n.t("inspector_companies.titles.new"))

      # Use our comprehensive form helper to verify all i18n is correct
      expect_form_matches_i18n("forms.inspector_companies")
    end

    it "successfully creates a company with valid data" do
      visit new_inspector_company_path

      fill_in_form :inspector_companies, :name, "Test Inspector Company"
      fill_in_form :inspector_companies, :email, "test@example.com"
      fill_in_form :inspector_companies, :phone, "01234567890"
      fill_in_form :inspector_companies, :address, "123 Test Street"
      fill_in_form :inspector_companies, :city, "Test City"
      fill_in_form :inspector_companies, :state, "Test State"
      fill_in_form :inspector_companies, :postal_code, "TE1 2ST"
      check_form :inspector_companies, :active
      fill_in_form :inspector_companies, :notes, "Test notes"

      submit_form :inspector_companies

      expect(page).to have_current_path(%r{/inspector_companies/\w+})
      expect(page).to have_content(I18n.t("inspector_companies.messages.created"))
      expect(page).to have_content("Test Inspector Company")
    end

    it "shows validation errors for missing required fields" do
      visit new_inspector_company_path

      submit_form :inspector_companies

      expect_form_errors :inspector_companies, count: 3
      expect(page).to have_content("Name #{I18n.t("errors.messages.cant_be_blank")}")
      expect(page).to have_content("Phone #{I18n.t("errors.messages.cant_be_blank")}")
      expect(page).to have_content("Address #{I18n.t("errors.messages.cant_be_blank")}")
    end
  end

  describe "Viewing Inspector Company" do
    let!(:company) { create(:inspector_company, name: "View Test Company") }

    before do
      login_user_via_form(admin_user)
    end

    it "displays company details" do
      visit inspector_company_path(company)

      expect(page).to have_content(company.name)
      expect(page).to have_content(I18n.t("inspector_companies.headers.company_details"))
      expect(page).to have_content(I18n.t("inspector_companies.headers.company_statistics"))

      # Company RPII field no longer exists
      expect(page).to have_content(company.phone)
      expect(page).to have_content(company.email)
    end

    it "shows action links" do
      visit inspector_company_path(company)

      expect(page).to have_link(I18n.t("ui.edit"))
      expect(page).to have_link(I18n.t("inspector_companies.titles.index"))
    end
  end

  describe "Editing Inspector Company" do
    let!(:company) { create(:inspector_company, name: "Edit Test Company") }

    before do
      login_user_via_form(admin_user)
    end

    it "displays the edit form with existing data" do
      visit edit_inspector_company_path(company)

      expect(page).to have_content(I18n.t("inspector_companies.titles.edit"))
      expect(page).to have_field(I18n.t("forms.inspector_companies.fields.name"), with: company.name)

      # Use our comprehensive form helper to verify all i18n is correct
      expect_form_matches_i18n("forms.inspector_companies")
    end

    it "successfully updates company data" do
      visit edit_inspector_company_path(company)

      fill_in_form :inspector_companies, :name, "Updated Company Name"
      fill_in_form :inspector_companies, :phone, "09876543210"

      submit_form :inspector_companies

      expect(page).to have_current_path(inspector_company_path(company))
      expect(page).to have_content(I18n.t("inspector_companies.messages.updated"))
      expect(page).to have_content("Updated Company Name")
    end
  end

  describe "Form accessibility and structure" do
    before do
      login_user_via_form(admin_user)
    end

    it "has proper form structure with i18n" do
      visit new_inspector_company_path

      expect_form_matches_i18n("forms.inspector_companies")
    end

    it "has required attributes on mandatory fields" do
      visit new_inspector_company_path

      expect(find_field(I18n.t("inspector_companies.forms.name"))["required"]).to eq("required")
      expect(find_field(I18n.t("inspector_companies.forms.phone"))["required"]).to eq("required")
      expect(find_field(I18n.t("inspector_companies.forms.address"))["required"]).to eq("required")
    end

    it "uses proper input types" do
      visit new_inspector_company_path

      expect(find_field(I18n.t("inspector_companies.forms.email"))[:type]).to eq("email")
      expect(find_field(I18n.t("inspector_companies.forms.phone"))[:type]).to eq("tel")
      expect(find_field(I18n.t("inspector_companies.forms.logo"))[:type]).to eq("file")
    end
  end
end
