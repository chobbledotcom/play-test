require "rails_helper"

RSpec.feature "Inspector Company Management", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :without_company) }

  describe "Admin company management workflow" do
    before { sign_in(admin_user) }

    scenario "admin creates a new company with all details" do
      visit new_inspector_company_path

      expect(page).to have_content(I18n.t("inspector_companies.titles.new"))

      fill_in I18n.t("inspector_companies.forms.name"), with: "Test Inspection Company"
      fill_in I18n.t("inspector_companies.forms.email"), with: "contact@testcompany.com"
      fill_in I18n.t("inspector_companies.forms.phone"), with: "01234 567890"
      fill_in I18n.t("inspector_companies.forms.address"), with: "123 Test Street\nTest City"
      fill_in I18n.t("inspector_companies.forms.city"), with: "Test City"
      fill_in I18n.t("inspector_companies.forms.postal_code"), with: "TE5 7ST"
      fill_in I18n.t("inspector_companies.forms.country"), with: "UK"
      check I18n.t("inspector_companies.forms.active")
      fill_in I18n.t("inspector_companies.forms.notes"), with: "Admin notes for this company"

      click_button I18n.t("inspector_companies.buttons.create")

      expect(page).to have_content(I18n.t("inspector_companies.messages.created"))
      expect(page).to have_content("Test Inspection Company")
      expect(page).to have_content("contact@testcompany.com")
      expect(page).to have_content("01234567890")

      # Verify company was created in database
      company = InspectorCompany.find_by(name: "Test Inspection Company")
      expect(company).to be_present
      expect(company.active).to be true
      expect(company.notes).to eq("Admin notes for this company")
    end

    scenario "admin edits company details using turbo form" do
      company = create(:inspector_company, name: "Original Company", email: "old@example.com")

      visit edit_inspector_company_path(company)

      expect(page).to have_content(I18n.t("inspector_companies.titles.edit"))
      expect(page).to have_field(I18n.t("inspector_companies.forms.name"), with: "Original Company")

      fill_in I18n.t("inspector_companies.forms.name"), with: "Updated Company Name"
      fill_in I18n.t("inspector_companies.forms.email"), with: "updated@example.com"

      click_button I18n.t("inspector_companies.buttons.update")

      # Should show success message and redirect to show page
      expect(page).to have_content(I18n.t("inspector_companies.messages.updated"))
      expect(page).to have_content("Updated Company Name")

      # Verify database was updated
      company.reload
      expect(company.name).to eq("Updated Company Name")
      expect(company.email).to eq("updated@example.com")
    end

    scenario "admin sees validation errors via turbo form" do
      company = create(:inspector_company, name: "Test Company")

      visit edit_inspector_company_path(company)

      fill_in I18n.t("inspector_companies.forms.name"), with: ""
      fill_in I18n.t("inspector_companies.forms.phone"), with: ""

      click_button I18n.t("inspector_companies.buttons.update")

      # Should show error message via Turbo without page reload
      expect(page).to have_content("can't be blank")
      expect(page).to have_content("Could not save company")

      # Form should remain on edit page
      expect(page).to have_content(I18n.t("inspector_companies.titles.edit"))
    end

    scenario "admin uploads company logo" do
      visit new_inspector_company_path

      fill_in I18n.t("inspector_companies.forms.name"), with: "Logo Test Company"
      fill_in I18n.t("inspector_companies.forms.phone"), with: "01234 567890"
      fill_in I18n.t("inspector_companies.forms.address"), with: "Test Address"

      attach_file I18n.t("inspector_companies.forms.logo"),
        Rails.root.join("spec", "fixtures", "files", "test_image.jpg")

      click_button I18n.t("inspector_companies.buttons.create")

      expect(page).to have_content(I18n.t("inspector_companies.messages.created"))

      company = InspectorCompany.find_by(name: "Logo Test Company")
      expect(company.logo).to be_attached
    end

    scenario "admin filters companies by status" do
      create(:inspector_company, name: "Filter Active Company", active: true)
      create(:inspector_company, name: "Filter Archived Company", active: false)

      visit inspector_companies_path

      # Check that filtering UI is present
      expect(page).to have_select("active")
      expect(page).to have_content(I18n.t("inspector_companies.status.active"))
      expect(page).to have_content(I18n.t("inspector_companies.status.archived"))

      # Test filtering via direct URL visit (more reliable than JS dropdown)
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
      click_button I18n.t("inspector_companies.buttons.search")

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

      expect(page).to have_content(I18n.t("inspector_companies.messages.unauthorized"))
      expect(page).to have_current_path(root_path)
    end

    scenario "regular user cannot access company creation" do
      visit new_inspector_company_path

      expect(page).to have_content(I18n.t("inspector_companies.messages.unauthorized"))
      expect(page).to have_current_path(root_path)
    end

    scenario "regular user cannot access company editing" do
      company = create(:inspector_company)

      visit edit_inspector_company_path(company)

      expect(page).to have_content(I18n.t("inspector_companies.messages.unauthorized"))
      expect(page).to have_current_path(root_path)
    end
  end

  describe "Error handling and edge cases" do
    before { sign_in(admin_user) }

    scenario "admin tries to access non-existent company" do
      visit inspector_company_path("nonexistent-id")

      expect(page).to have_content(I18n.t("inspector_companies.messages.not_found"))
      expect(page).to have_current_path(inspector_companies_path)
    end

    scenario "admin creates company with missing required fields" do
      visit new_inspector_company_path

      # Leave required fields blank
      click_button I18n.t("inspector_companies.buttons.create")

      # Should show validation errors
      expect(page).to have_content("can't be blank")
      expect(page).to have_content(I18n.t("inspector_companies.titles.new"))
    end

    scenario "admin creates company with default country" do
      visit new_inspector_company_path

      # Country field should be pre-filled with UK
      expect(page).to have_field(I18n.t("inspector_companies.forms.country"), with: "UK")

      fill_in I18n.t("inspector_companies.forms.name"), with: "UK Default Company"
      fill_in I18n.t("inspector_companies.forms.phone"), with: "01234 567890"
      fill_in I18n.t("inspector_companies.forms.address"), with: "Test Address"

      click_button I18n.t("inspector_companies.buttons.create")

      company = InspectorCompany.find_by(name: "UK Default Company")
      expect(company.country).to eq("UK")
    end
  end

  describe "Navigation and UI flow" do
    before { sign_in(admin_user) }

    scenario "admin navigates through company management workflow" do
      # Start from index
      visit inspector_companies_path
      expect(page).to have_content(I18n.t("inspector_companies.titles.index"))

      # Go to new company (use first link to avoid ambiguity)
      first(:link, I18n.t("inspector_companies.buttons.new_company")).click
      expect(page).to have_content(I18n.t("inspector_companies.titles.new"))

      # Create company
      fill_in I18n.t("inspector_companies.forms.name"), with: "Navigation Test Company"
      fill_in I18n.t("inspector_companies.forms.phone"), with: "01234 567890"
      fill_in I18n.t("inspector_companies.forms.address"), with: "Test Address"
      click_button I18n.t("inspector_companies.buttons.create")

      # Should be on show page
      expect(page).to have_content("Navigation Test Company")
      expect(page).to have_link(I18n.t("ui.edit"))

      # Go to edit
      click_link I18n.t("ui.edit")
      expect(page).to have_content(I18n.t("inspector_companies.titles.edit"))

      # Update and verify we stay on edit page with success message
      fill_in I18n.t("inspector_companies.forms.name"), with: "Updated Navigation Company"
      click_button I18n.t("inspector_companies.buttons.update")

      expect(page).to have_content(I18n.t("inspector_companies.messages.updated"))
      expect(page).to have_content("Updated Navigation Company")
    end
  end
end
