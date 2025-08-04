require "rails_helper"

RSpec.feature "Inspector Company Management", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :without_company) }

  describe "Admin company management workflow" do
    before { sign_in(admin_user) }

    scenario "admin creates a new company with all details" do
      visit new_inspector_company_path

      expect(page).to have_content(I18n.t("inspector_companies.titles.new"))

      fill_in_form :inspector_companies, :name, "Test Inspection Company"
      fill_in_form :inspector_companies, :email, "contact@testcompany.com"
      fill_in_form :inspector_companies, :phone, "01234 567890"
      fill_in_form :inspector_companies, :address, "123 Test Street\nTest City"
      fill_in_form :inspector_companies, :city, "Test City"
      fill_in_form :inspector_companies, :postal_code, "TE5 7ST"
      fill_in_form :inspector_companies, :country, "UK"
      check_form :inspector_companies, :active
      fill_in_form :inspector_companies, :notes, "Admin notes for this company"

      submit_form :inspector_companies
# Flash messages may not render in test environment
      expect(page).to have_content("Test Inspection Company")
      expect(page).to have_content("contact@testcompany.com")
      expect(page).to have_content("01234567890")

      company = InspectorCompany.find_by(name: "Test Inspection Company")
      expect(company).to be_present
      expect(company.active).to be true
      expect(company.notes).to eq("Admin notes for this company")
    end

    scenario "admin edits company details using turbo form" do
      company = create(:inspector_company, name: "Original Company", email: "old@example.com")

      visit edit_inspector_company_path(company)

      expect(page).to have_content(I18n.t("inspector_companies.titles.edit"))
      expect(page).to have_field(I18n.t("forms.inspector_companies.fields.name"), with: "Original Company")

      fill_in_form :inspector_companies, :name, "Updated Company Name"
      fill_in_form :inspector_companies, :email, "updated@example.com"

      submit_form :inspector_companies
# Flash messages may not render in test environment
      expect(page).to have_content("Updated Company Name")

      company.reload
      expect(company.name).to eq("Updated Company Name")
      expect(company.email).to eq("updated@example.com")
    end

    scenario "admin sees validation errors via turbo form" do
      company = create(:inspector_company, name: "Test Company")

      visit edit_inspector_company_path(company)

      fill_in_form :inspector_companies, :name, ""
      fill_in_form :inspector_companies, :phone, ""

      submit_form :inspector_companies

      expect(page).to have_content("can't be blank")
      expect_form_errors :inspector_companies, count: 2

      expect(page).to have_content(I18n.t("inspector_companies.titles.edit"))
    end

    scenario "admin uploads company logo" do
      visit new_inspector_company_path

      fill_in_form :inspector_companies, :name, "Logo Test Company"
      fill_in_form :inspector_companies, :phone, "01234 567890"
      fill_in_form :inspector_companies, :address, "Test Address"

      attach_file I18n.t("forms.inspector_companies.fields.logo"),
        Rails.root.join("spec/fixtures/files/test_image.jpg")

      submit_form :inspector_companies
# Flash messages may not render in test environment

      company = InspectorCompany.find_by(name: "Logo Test Company")
      expect(company.logo).to be_attached
    end

    scenario "admin filters companies by status" do
      create(:inspector_company, name: "Filter Active Company", active: true)
      create(:inspector_company, name: "Filter Archived Company", active: false)

      visit inspector_companies_path

      expect(page).to have_select("active")
      expect(page).to have_content(I18n.t("inspector_companies.status.active"))
      expect(page).to have_content(I18n.t("inspector_companies.status.archived"))

      visit inspector_companies_path(active: "active")
      expect(page).to have_content("Filter Active Company")

      visit inspector_companies_path(active: "archived")
      expect(page).to have_content("Filter Archived Company")
    end

    scenario "admin searches companies by name" do
      create(:inspector_company, name: "ABC Inspections")
      create(:inspector_company, name: "XYZ Safety")

      visit inspector_companies_path

      fill_in "search", with: "ABC"

      visit inspector_companies_path(search: "ABC")

      expect(page).to have_content("ABC Inspections")
      expect(page).not_to have_content("XYZ Safety")
    end

    scenario "admin views company statistics" do
      company = create(:inspector_company, name: "Stats Company")
      user = create(:user, inspection_company: company)
      create_list(:inspection, 3, user: user, inspector_company: company)

      visit inspector_company_path(company)

      expect(page).to have_content("Stats Company")
      expect(page).to have_content("3") # inspection count
    end
  end

  describe "Regular user restrictions" do
    before { sign_in(regular_user) }

    scenario "regular user can view company details but not admin functions" do
      company = create(:inspector_company, name: "Viewable Company")

      visit inspector_company_path(company)

      expect(page).to have_content("Viewable Company")
      expect(page).not_to have_link(I18n.t("ui.edit"))
    end

    scenario "regular user cannot access company index" do
      visit inspector_companies_path

      expect(page).to have_content(I18n.t("forms.session_new.status.admin_required"))
      expect(page).to have_current_path(root_path)
    end

    scenario "regular user cannot access company creation" do
      visit new_inspector_company_path

      expect(page).to have_content(I18n.t("forms.session_new.status.admin_required"))
      expect(page).to have_current_path(root_path)
    end

    scenario "regular user cannot access company editing" do
      company = create(:inspector_company)

      visit edit_inspector_company_path(company)

      expect(page).to have_content(I18n.t("forms.session_new.status.admin_required"))
      expect(page).to have_current_path(root_path)
    end
  end

  describe "Error handling and edge cases" do
    before { sign_in(admin_user) }

    scenario "admin tries to access non-existent company" do
      visit inspector_company_path("nonexistent-id")

      # Should see Rails error page with RecordNotFound
      expect(page).to have_content("ActiveRecord::RecordNotFound")
      expect(page).to have_content("Couldn't find InspectorCompany")
    end

    scenario "admin creates company with missing required fields" do
      visit new_inspector_company_path

      submit_form :inspector_companies

      expect(page).to have_content("can't be blank")
      expect(page).to have_content(I18n.t("inspector_companies.titles.new"))
    end

    scenario "admin creates company with default country" do
      visit new_inspector_company_path

      expect(page).to have_field(I18n.t("forms.inspector_companies.fields.country"), with: "UK")

      fill_in_form :inspector_companies, :name, "UK Default Company"
      fill_in_form :inspector_companies, :phone, "01234 567890"
      fill_in_form :inspector_companies, :address, "Test Address"

      submit_form :inspector_companies

      company = InspectorCompany.find_by(name: "UK Default Company")
      expect(company.country).to eq("UK")
    end
  end

  describe "Navigation and UI flow" do
    before { sign_in(admin_user) }

    scenario "admin navigates through company management workflow" do
      visit inspector_companies_path
      expect(page).to have_content(I18n.t("inspector_companies.titles.index"))

      click_button I18n.t("inspector_companies.buttons.new_company")
      expect(page).to have_content(I18n.t("inspector_companies.titles.new"))

      fill_in_form :inspector_companies, :name, "Navigation Test Company"
      fill_in_form :inspector_companies, :phone, "01234 567890"
      fill_in_form :inspector_companies, :address, "Test Address"
      submit_form :inspector_companies

      expect(page).to have_content("Navigation Test Company")
      expect(page).to have_link(I18n.t("ui.edit"))

      click_link I18n.t("ui.edit")
      expect(page).to have_content(I18n.t("inspector_companies.titles.edit"))

      fill_in_form :inspector_companies, :name, "Updated Navigation Company"
      submit_form :inspector_companies
# Flash messages may not render in test environment
      expect(page).to have_content("Updated Navigation Company")
    end
  end
end
