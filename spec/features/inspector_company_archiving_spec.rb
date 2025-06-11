require "rails_helper"

RSpec.feature "Inspector Company Archiving", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let!(:inspector_company) { create(:inspector_company, name: "Test Archive Company", active: true) }

  before do
    sign_in(admin_user)
  end

  describe "Archiving a company" do
    it "archives a company when clicking the archive link" do
      visit inspector_companies_path

      # Company should be visible in active list
      expect(page).to have_content("Test Archive Company")
      expect(page).to have_link(I18n.t("inspector_companies.buttons.archive"))

      # Click the archive link for this specific company
      within("tr", text: "Test Archive Company") do
        click_link I18n.t("inspector_companies.buttons.archive")
      end

      # Should be redirected to companies index
      expect(page).to have_current_path(inspector_companies_path)

      # Should see success message
      expect(page).to have_content(I18n.t("inspector_companies.messages.archived"))

      # Company should still be visible in default view (which shows all companies)
      expect(page).to have_content("Test Archive Company")

      # But it should now show as "Archived" status and have "Unarchive" button
      expect(page).to have_content("Archived") # status
      expect(page).to have_link(I18n.t("inspector_companies.buttons.unarchive"))

      # Verify in database that company is archived
      inspector_company.reload
      expect(inspector_company.active).to be false
    end

    it "shows confirmation dialog before archiving" do
      visit inspector_companies_path

      # The archive link should have a confirmation dialog and use PATCH method
      within("tr", text: "Test Archive Company") do
        archive_link = find_link(I18n.t("inspector_companies.buttons.archive"))
        expect(archive_link["data-turbo-confirm"]).to include("Are you sure you want to archive Test Archive Company?")
        expect(archive_link["data-turbo-method"]).to eq("patch")
      end
    end
  end

  describe "Viewing archived companies" do
    let!(:archived_company) { create(:inspector_company, name: "Archived Company", active: false) }

    it "shows both active and archived companies in default view" do
      visit inspector_companies_path

      expect(page).to have_content("Test Archive Company") # active company
      expect(page).to have_content("Archived Company") # archived company
    end

    it "shows all companies (active and archived) when selecting All Companies" do
      visit inspector_companies_path(active: "all")

      # Should see both active and archived companies
      expect(page).to have_content("Test Archive Company") # active company
      expect(page).to have_content("Archived Company") # archived company
    end

    it "shows archived companies when filtering by archived status" do
      visit inspector_companies_path(active: "archived")

      # Should see archived company but not active company
      expect(page).to have_content("Archived Company")
      expect(page).not_to have_content("Test Archive Company")
    end
  end

  describe "Archive link behavior on company show page" do
    it "shows archive link on company show page for admins" do
      visit inspector_company_path(inspector_company)

      expect(page).to have_link(I18n.t("inspector_companies.buttons.archive"))
    end

    it "archives company from show page" do
      visit inspector_company_path(inspector_company)

      # Click the archive link (this will be a PATCH request)
      click_link I18n.t("inspector_companies.buttons.archive")

      # Should redirect to companies index
      expect(page).to have_current_path(inspector_companies_path)
      expect(page).to have_content(I18n.t("inspector_companies.messages.archived"))

      # Verify company is archived
      inspector_company.reload
      expect(inspector_company.active).to be false
    end
  end

  describe "Unarchiving companies" do
    let!(:archived_company) { create(:inspector_company, name: "Company to Unarchive", active: false) }

    it "shows unarchive link for archived companies" do
      visit inspector_companies_path(active: "archived")

      # Should see unarchive link instead of archive link
      expect(page).to have_link(I18n.t("inspector_companies.buttons.unarchive"))
      expect(page).not_to have_link(I18n.t("inspector_companies.buttons.archive"))
    end

    it "unarchives a company when clicking the unarchive link" do
      visit inspector_companies_path(active: "archived")

      # Company should be visible in archived list
      expect(page).to have_content("Company to Unarchive")
      expect(page).to have_link(I18n.t("inspector_companies.buttons.unarchive"))

      # Click the unarchive link for this specific company
      within("tr", text: "Company to Unarchive") do
        click_link I18n.t("inspector_companies.buttons.unarchive")
      end

      # Should be redirected to companies index
      expect(page).to have_current_path(inspector_companies_path)

      # Should see success message
      expect(page).to have_content(I18n.t("inspector_companies.messages.unarchived"))

      # Company should now be visible in default (active) view
      expect(page).to have_content("Company to Unarchive")

      # Verify in database that company is unarchived
      archived_company.reload
      expect(archived_company.active).to be true
    end

    it "shows unarchive link on archived company show page" do
      visit inspector_company_path(archived_company)

      expect(page).to have_link(I18n.t("inspector_companies.buttons.unarchive"))
      expect(page).not_to have_link(I18n.t("inspector_companies.buttons.archive"))
    end

    it "unarchives company from show page" do
      visit inspector_company_path(archived_company)

      # Click the unarchive link (this will be a PATCH request)
      click_link I18n.t("inspector_companies.buttons.unarchive")

      # Should redirect to companies index
      expect(page).to have_current_path(inspector_companies_path)
      expect(page).to have_content(I18n.t("inspector_companies.messages.unarchived"))

      # Verify company is unarchived
      archived_company.reload
      expect(archived_company.active).to be true
    end
  end
end
