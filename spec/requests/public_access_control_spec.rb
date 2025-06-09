require "rails_helper"

RSpec.describe "Public Access Control", type: :request do
  include Capybara::DSL

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  describe "Public pages (should be accessible without login)" do
    before do
      # Ensure we're not logged in
      visit logout_path if page.has_button?(I18n.t("sessions.buttons.logout"))
    end

    it "allows access to home page" do
      visit root_path
      expect(page).to have_http_status(:success)
      expect(page.current_path).to eq(root_path)
    end

    it "allows access to about page" do
      visit about_path
      expect(page).to have_http_status(:success)
      expect(page.current_path).to eq(about_path)
    end

    it "allows access to safety standards page" do
      visit safety_standards_path
      expect(page).to have_http_status(:success)
      expect(page.current_path).to eq(safety_standards_path)
    end

    it "allows access to login page" do
      visit login_path
      expect(page).to have_http_status(:success)
      expect(page.current_path).to eq(login_path)
    end

    it "allows access to signup page" do
      visit signup_path
      expect(page).to have_http_status(:success)
      expect(page.current_path).to eq(signup_path)
    end

    describe "Public report access" do
      it "allows access to inspection PDF via short URL (lowercase)" do
        visit "/r/#{inspection.id}"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end

      it "allows access to inspection PDF via short URL (uppercase)" do
        visit "/R/#{inspection.id}"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end

      it "allows access to inspection JSON via short URL" do
        visit "/r/#{inspection.id}.json"
        expect(page.response_headers["Content-Type"]).to include("application/json")
        json = JSON.parse(page.body)
        expect(json).to have_key("inspection_date")
      end

      it "allows access to inspection JSON via long URL" do
        visit "/inspections/#{inspection.id}/report.json"
        expect(page.response_headers["Content-Type"]).to include("application/json")
        json = JSON.parse(page.body)
        expect(json).to have_key("inspection_date")
      end

      it "allows access to inspection QR code" do
        page.driver.browser.get("/inspections/#{inspection.id}/qr_code")
        expect(page.driver.response.headers["Content-Type"]).to include("image/png")
        expect(page.driver.response.body[1..3]).to eq("PNG")
      end

      it "allows access to unit PDF via short URL (lowercase)" do
        visit "/u/#{unit.id}"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end

      it "allows access to unit PDF via short URL (uppercase)" do
        visit "/U/#{unit.id}"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end

      it "allows access to unit JSON via short URL" do
        visit "/u/#{unit.id}.json"
        expect(page.response_headers["Content-Type"]).to include("application/json")
        json = JSON.parse(page.body)
        expect(json).to have_key("name")
      end

      it "allows access to unit JSON via long URL" do
        visit "/units/#{unit.id}/report.json"
        expect(page.response_headers["Content-Type"]).to include("application/json")
        json = JSON.parse(page.body)
        expect(json).to have_key("name")
      end

      it "allows access to unit QR code" do
        page.driver.browser.get("/units/#{unit.id}/qr_code")
        expect(page.driver.response.headers["Content-Type"]).to include("image/png")
        expect(page.driver.response.body[1..3]).to eq("PNG")
      end
    end

    describe "Safety standards page" do
      it "allows access to safety standards page" do
        visit safety_standards_path
        expect(page).to have_http_status(:success)
        expect(page).to have_content(I18n.t("safety_standards_reference.title"))
      end
    end
  end

  describe "Protected pages (should redirect to login)" do
    before do
      # Ensure we're not logged in
      visit logout_path if page.has_button?(I18n.t("sessions.buttons.logout"))
    end

    it "redirects inspections index to login" do
      visit inspections_path
      expect(page.current_path).to eq(login_path)
      expect(page).to have_content(I18n.t("authorization.login_required"))
    end

    it "redirects inspection show page to login" do
      visit inspection_path(inspection)
      expect(page.current_path).to eq(login_path)
    end

    it "redirects inspection edit page to login" do
      visit edit_inspection_path(inspection)
      expect(page.current_path).to eq(login_path)
    end

    it "redirects units index to login" do
      visit units_path
      expect(page.current_path).to eq(login_path)
    end

    it "redirects unit show page to login" do
      visit unit_path(unit)
      expect(page.current_path).to eq(login_path)
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
      expect(page).to have_http_status(:not_found)
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

    describe "Protected JSON endpoints" do
      it "redirects inspection show JSON to login when not using report endpoint" do
        visit "/inspections/#{inspection.id}.json"
        expect(page.current_path).to eq(login_path)
      end

      it "redirects unit show JSON to login when not using report endpoint" do
        visit "/units/#{unit.id}.json"
        expect(page.current_path).to eq(login_path)
      end
    end
  end

  describe "Edge cases and security" do
    before do
      # Ensure we're not logged in
      visit logout_path if page.has_button?(I18n.t("sessions.buttons.logout"))
    end

    it "returns 404 for non-existent inspection reports" do
      visit "/r/NONEXISTENT"
      expect(page).to have_http_status(:not_found)
    end

    it "returns 404 for non-existent unit reports" do
      visit "/u/NONEXISTENT"
      expect(page).to have_http_status(:not_found)
    end

    it "returns 404 for non-existent inspection QR codes" do
      page.driver.browser.get("/inspections/NONEXISTENT/qr_code")
      expect(page.driver.response.status).to eq(404)
    end

    it "returns 404 for non-existent unit QR codes" do
      page.driver.browser.get("/units/NONEXISTENT/qr_code")
      expect(page.driver.response.status).to eq(404)
    end

    it "handles case-insensitive IDs for public reports" do
      # Test lowercase
      visit "/r/#{inspection.id.downcase}"
      expect(page.response_headers["Content-Type"]).to eq("application/pdf")

      # Test uppercase
      visit "/r/#{inspection.id.upcase}"
      expect(page.response_headers["Content-Type"]).to eq("application/pdf")
    end

    it "prevents directory traversal attacks" do
      visit "/r/../../../etc/passwd"
      expect(page).to have_http_status(:not_found)
    end

    it "handles malformed requests gracefully" do
      # Safety standards page handles GET requests with params
      visit "#{safety_standards_path}?calculation[type]=invalid&calculation[value]=test"
      expect(page).to have_http_status(:success)
      # Page should still render even with invalid params
      expect(page).to have_content(I18n.t("safety_standards_reference.title"))
    end
  end

  describe "Response headers and security" do
    it "sets noindex header on inspection reports" do
      visit "/r/#{inspection.id}"
      expect(page.response_headers["X-Robots-Tag"]).to include("noindex")
    end

    it "sets noindex header on unit reports" do
      visit "/u/#{unit.id}"
      expect(page.response_headers["X-Robots-Tag"]).to include("noindex")
    end

    it "does not leak user information in public JSON" do
      visit "/r/#{inspection.id}.json"
      json = JSON.parse(page.body)

      expect(json).not_to have_key("user_id")
      expect(json).not_to have_key("inspector_signature")
      expect(json).not_to have_key("signature_timestamp")
    end
  end
end
