require "rails_helper"

RSpec.describe "Public Access Control", type: :request do
  include Capybara::DSL

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  before do
    # Create pages for CMS system
    Page.find_or_create_by(slug: "/") do |page|
      page.content = "<h1>Homepage</h1>"
    end
    Page.find_or_create_by(slug: "about") do |page|
      page.content = "<h1>About</h1>"
    end
  end

  describe "Public pages (should be accessible without login)" do
    before do
      # Ensure we're not logged in
      logout if page.has_button?(I18n.t("sessions.buttons.log_out"))
    end

    it "allows access to home page" do
      visit root_path
      expect(page.status_code).to eq(200)
      expect(page.current_path).to eq(root_path)
    end

    it "allows access to about page" do
      visit "/pages/about"
      expect(page.status_code).to eq(200)
      expect(page.current_path).to eq("/pages/about")
    end

    it "allows access to safety standards page" do
      visit safety_standards_path
      expect(page.status_code).to eq(200)
      expect(page.current_path).to eq(safety_standards_path)
    end

    it "allows access to login page" do
      visit login_path
      expect(page.status_code).to eq(200)
      expect(page.current_path).to eq(login_path)
    end

    it "allows access to register page" do
      visit register_path
      expect(page.status_code).to eq(200)
      expect(page.current_path).to eq(register_path)
    end

    describe "Public report access" do
      it "shows minimal PDF viewer for inspection HTML" do
        visit "/inspections/#{inspection.id}"
        expect(page.response_headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(page.body).to include("<iframe")
      end

      it "allows access to inspection PDF" do
        visit "/inspections/#{inspection.id}.pdf"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end

      it "allows access to inspection JSON via short URL" do
        visit "/inspections/#{inspection.id}.json"
        expect(page.response_headers["Content-Type"]).to include("application/json")
        json = JSON.parse(page.body)
        expect(json).to have_key("inspection_date")
      end

      it "allows access to inspection JSON via long URL" do
        visit "/inspections/#{inspection.id}.json"
        expect(page.response_headers["Content-Type"]).to include("application/json")
        json = JSON.parse(page.body)
        expect(json).to have_key("inspection_date")
      end

      it "allows access to inspection QR code" do
        page.driver.browser.get("/inspections/#{inspection.id}.png")
        expect(page.driver.response.headers["Content-Type"]).to include("image/png")
        expect(page.driver.response.body[1..3]).to eq("PNG")
      end

      it "shows minimal PDF viewer for unit HTML" do
        visit "/units/#{unit.id}"
        expect(page.response_headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(page.body).to include("<iframe")
      end

      it "allows access to unit PDF" do
        visit "/units/#{unit.id}.pdf"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end

      it "allows access to unit JSON via short URL" do
        visit "/units/#{unit.id}.json"
        expect(page.response_headers["Content-Type"]).to include("application/json")
        json = JSON.parse(page.body)
        expect(json).to have_key("name")
      end

      it "allows access to unit JSON via long URL" do
        visit "/units/#{unit.id}.json"
        expect(page.response_headers["Content-Type"]).to include("application/json")
        json = JSON.parse(page.body)
        expect(json).to have_key("name")
      end

      it "allows access to unit QR code" do
        page.driver.browser.get("/units/#{unit.id}.png")
        expect(page.driver.response.headers["Content-Type"]).to include("image/png")
        expect(page.driver.response.body[1..3]).to eq("PNG")
      end
    end

    describe "Safety standards page" do
      it "allows access to safety standards page" do
        visit safety_standards_path
        expect(page.status_code).to eq(200)
        expect(page).to have_content(I18n.t("safety_standards.title"))
      end
    end
  end

  describe "Protected pages (should redirect to login)" do
    before do
      logout if page.has_button?(I18n.t("sessions.buttons.log_out"))
    end

    it "redirects inspections index to login" do
      visit inspections_path
      expect(page.current_path).to eq(login_path)
      expect(page).to have_content(I18n.t("forms.session_new.status.login_required"))
    end

    it "shows PDF viewer for inspection show page when not logged in" do
      visit inspection_path(inspection)
      expect(page.current_path).to eq(inspection_path(inspection))
      expect(page.html).to include("<iframe")
      expect(page.html).to include(inspection_path(inspection, format: :pdf))
    end

    it "redirects inspection edit page to login" do
      visit edit_inspection_path(inspection)
      expect(page.current_path).to eq(login_path)
    end

    it "redirects units index to login" do
      visit units_path
      expect(page.current_path).to eq(login_path)
    end

    it "shows PDF viewer for unit show page when not logged in" do
      visit unit_path(unit)
      expect(page.current_path).to eq(unit_path(unit))
      expect(page.html).to include("<iframe")
      expect(page.html).to include(unit_path(unit, format: :pdf))
    end

    it "redirects unit edit page to login" do
      visit edit_unit_path(unit)
      expect(page.current_path).to eq(login_path)
    end

    it "redirects new unit page to login" do
      visit new_unit_path
      expect(page.current_path).to eq(login_path)
    end

    it "redirects users index to login" do
      visit users_path
      expect(page.current_path).to eq(login_path)
    end

    it "returns 404 for user show page (no show action)" do
      visit user_path(user)
      expect(page.status_code).to eq(404)
    end

    it "redirects user edit page to login" do
      visit edit_user_path(user)
      expect(page.current_path).to eq(login_path)
    end

    it "redirects inspector companies index to login" do
      visit inspector_companies_path
      expect(page.current_path).to eq(login_path)
    end

    it "redirects inspector company show page to login" do
      company = create(:inspector_company)
      visit inspector_company_path(company)
      expect(page.current_path).to eq(login_path)
    end

    it "redirects inspector company edit page to login" do
      company = create(:inspector_company)
      visit edit_inspector_company_path(company)
      expect(page.current_path).to eq(login_path)
    end

    it "redirects new inspector company page to login" do
      visit new_inspector_company_path
      expect(page.current_path).to eq(login_path)
    end

    describe "Public JSON endpoints" do
      it "allows public access to inspection JSON" do
        visit "/inspections/#{inspection.id}.json"
        expect(page.status_code).to eq(200)
        expect(page.current_path).to eq("/inspections/#{inspection.id}.json")
        json = JSON.parse(page.body)
        expect(json).to have_key("inspection_date")
      end

      it "allows public access to unit JSON" do
        visit "/units/#{unit.id}.json"
        expect(page.status_code).to eq(200)
        expect(page.current_path).to eq("/units/#{unit.id}.json")
        json = JSON.parse(page.body)
        expect(json).to have_key("serial")
      end
    end
  end

  describe "Edge cases and security" do
    before do
      # Ensure we're not logged in
      logout if page.has_button?(I18n.t("sessions.buttons.log_out"))
    end

    it "returns 404 for non-existent inspection reports" do
      visit "/inspections/NONEXISTENT"
      expect(page.status_code).to eq(404)
    end

    it "returns 404 for non-existent unit reports" do
      visit "/units/NONEXISTENT"
      expect(page.status_code).to eq(404)
    end

    it "returns 404 for non-existent inspection QR codes" do
      page.driver.browser.get("/inspections/NONEXISTENT.png")
      expect(page.driver.response.status).to eq(404)
    end

    it "returns 404 for non-existent unit QR codes" do
      page.driver.browser.get("/units/NONEXISTENT.png")
      expect(page.driver.response.status).to eq(404)
    end

    it "handles case-insensitive IDs for public reports" do
      # Test lowercase
      visit "/inspections/#{inspection.id.downcase}"
      expect(page.response_headers["Content-Type"]).to eq("text/html; charset=utf-8")
      expect(page.body).to include("<iframe")

      # Test uppercase
      visit "/inspections/#{inspection.id.upcase}"
      expect(page.response_headers["Content-Type"]).to eq("text/html; charset=utf-8")
      expect(page.body).to include("<iframe")
    end

    it "prevents directory traversal attacks" do
      visit "/inspections/../../../etc/passwd"
      expect(page.status_code).to eq(404)
    end

    it "handles malformed requests gracefully" do
      # Safety standards page handles GET requests with params
      visit "#{safety_standards_path}?calculation[type]=invalid&calculation[value]=test"
      expect(page.status_code).to eq(200)
      # Page should still render even with invalid params
      expect(page).to have_content(I18n.t("safety_standards.title"))
    end
  end

  describe "Response headers and security" do
    it "sets noindex header on inspection reports" do
      visit "/inspections/#{inspection.id}"
      expect(page.response_headers["X-Robots-Tag"]).to include("noindex")
    end

    it "sets noindex header on unit reports" do
      visit "/units/#{unit.id}"
      expect(page.response_headers["X-Robots-Tag"]).to include("noindex")
    end

    it "does not leak user information in public JSON" do
      visit "/inspections/#{inspection.id}.json"
      json = JSON.parse(page.body)

      expect(json).not_to have_key("user_id")
    end
  end
end
