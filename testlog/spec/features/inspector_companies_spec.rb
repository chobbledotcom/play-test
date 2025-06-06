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

    context "with no additional companies" do
      it "shows empty state when no extra companies exist" do
        # Clear any existing companies except the admin user's company
        InspectorCompany.where.not(id: admin_user.inspection_company.id).destroy_all

        visit inspector_companies_path

        # Should show the admin user's company but indicate if no others exist
        expect(page).to have_content(admin_user.inspection_company.name)
        expect(page).to have_link(I18n.t("inspector_companies.buttons.new_company"))
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

        expect(page).to have_content(I18n.t("inspector_companies.status.valid_credentials"))
      end

      it "allows searching by company name" do
        visit inspector_companies_path

        fill_in I18n.t("inspector_companies.search.placeholder"), with: "Test Company 1"
        click_button I18n.t("inspector_companies.buttons.search")

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
          expect(page).to have_link(I18n.t("inspector_companies.buttons.archive"))
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
      expect(page).to have_content(I18n.t("inspector_companies.headers.company_details"))
      expect(page).to have_content(I18n.t("inspector_companies.headers.contact_information"))
      expect(page).to have_content(I18n.t("inspector_companies.headers.company_status"))

      expect(page).to have_field(I18n.t("inspector_companies.forms.name"))
      expect(page).to have_field(I18n.t("inspector_companies.forms.rpii_registration_number"))
      expect(page).to have_field(I18n.t("inspector_companies.forms.email"))
      expect(page).to have_field(I18n.t("inspector_companies.forms.phone"))
      expect(page).to have_field(I18n.t("inspector_companies.forms.address"))
      expect(page).to have_field(I18n.t("inspector_companies.forms.city"))
      expect(page).to have_field(I18n.t("inspector_companies.forms.state"))
      expect(page).to have_field(I18n.t("inspector_companies.forms.postal_code"))
      expect(page).to have_field(I18n.t("inspector_companies.forms.country"))
      expect(page).to have_field(I18n.t("inspector_companies.forms.active"))
      expect(page).to have_field(I18n.t("inspector_companies.forms.notes"))
      expect(page).to have_field(I18n.t("inspector_companies.forms.logo"))

      expect(page).to have_button(I18n.t("inspector_companies.buttons.create"))
    end

    it "successfully creates a company with valid data" do
      visit new_inspector_company_path

      fill_in I18n.t("inspector_companies.forms.name"), with: "Test Inspector Company"
      fill_in I18n.t("inspector_companies.forms.rpii_registration_number"), with: "RPII-12345"
      fill_in I18n.t("inspector_companies.forms.email"), with: "test@example.com"
      fill_in I18n.t("inspector_companies.forms.phone"), with: "01234567890"
      fill_in I18n.t("inspector_companies.forms.address"), with: "123 Test Street"
      fill_in I18n.t("inspector_companies.forms.city"), with: "Test City"
      fill_in I18n.t("inspector_companies.forms.state"), with: "Test State"
      fill_in I18n.t("inspector_companies.forms.postal_code"), with: "TE1 2ST"
      check I18n.t("inspector_companies.forms.active")
      fill_in I18n.t("inspector_companies.forms.notes"), with: "Test notes"

      click_button I18n.t("inspector_companies.buttons.create")

      expect(page).to have_current_path(%r{/inspector_companies/\w+})
      expect(page).to have_content(I18n.t("inspector_companies.messages.created"))
      expect(page).to have_content("Test Inspector Company")
    end

    it "shows validation errors for missing required fields" do
      visit new_inspector_company_path

      click_button I18n.t("inspector_companies.buttons.create")

      expect(page).to have_content("prohibited this company from being saved")
      expect(page).to have_content("Name can't be blank")
      expect(page).to have_content("Rpii registration number can't be blank")
      expect(page).to have_content("Phone can't be blank")
      expect(page).to have_content("Address can't be blank")
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

      expect(page).to have_content(company.rpii_registration_number)
      expect(page).to have_content(company.phone)
      expect(page).to have_content(company.email)
    end

    it "shows action links" do
      visit inspector_company_path(company)

      expect(page).to have_link(I18n.t("ui.edit"))
      expect(page).to have_link(I18n.t("inspector_companies.buttons.archive"))
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
      expect(page).to have_field(I18n.t("inspector_companies.forms.name"), with: company.name)
      expect(page).to have_field(I18n.t("inspector_companies.forms.rpii_registration_number"), with: company.rpii_registration_number)
      expect(page).to have_button(I18n.t("inspector_companies.buttons.update"))
      expect(page).to have_link(I18n.t("inspector_companies.buttons.archive"))
    end

    it "successfully updates company data" do
      visit edit_inspector_company_path(company)

      fill_in I18n.t("inspector_companies.forms.name"), with: "Updated Company Name"
      fill_in I18n.t("inspector_companies.forms.phone"), with: "09876543210"

      click_button I18n.t("inspector_companies.buttons.update")

      expect(page).to have_current_path(inspector_company_path(company))
      expect(page).to have_content(I18n.t("inspector_companies.messages.updated"))
      expect(page).to have_content("Updated Company Name")
    end
  end

  describe "Archive Links Display" do
    let!(:company) { create(:inspector_company, name: "Archive Test Company") }

    before do
      login_user_via_form(admin_user)
    end

    it "shows archive link on index page" do
      visit inspector_companies_path

      expect(page).to have_content(company.name)
      expect(page).to have_link(I18n.t("inspector_companies.buttons.archive"))
    end

    it "shows archive link on show page" do
      visit inspector_company_path(company)

      expect(page).to have_link(I18n.t("inspector_companies.buttons.archive"))
    end

    it "shows archive link on edit page" do
      visit edit_inspector_company_path(company)

      expect(page).to have_link(I18n.t("inspector_companies.buttons.archive"))
    end
  end

  describe "Form accessibility and structure" do
    before do
      login_user_via_form(admin_user)
    end

    it "has proper form structure with fieldsets" do
      visit new_inspector_company_path

      expect(page).to have_css("fieldset")
      expect(page).to have_css("fieldset header h3", text: I18n.t("inspector_companies.headers.company_details"))
      expect(page).to have_css("fieldset header h4", text: I18n.t("inspector_companies.headers.contact_information"))
      expect(page).to have_css("fieldset header h4", text: I18n.t("inspector_companies.headers.company_status"))
    end

    it "has required attributes on mandatory fields" do
      visit new_inspector_company_path

      expect(find_field(I18n.t("inspector_companies.forms.name"))["required"]).to eq("required")
      expect(find_field(I18n.t("inspector_companies.forms.rpii_registration_number"))["required"]).to eq("required")
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
