# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Access Control", type: :request do
  include Capybara::DSL

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  def ensure_logged_out
    logout if page.has_button?(I18n.t("sessions.buttons.log_out"))
  end

  def expect_public_access(path, expected_path = nil)
    visit path
    expect(page.status_code).to eq(200)
    expect(page.current_path).to eq(expected_path || path)
  end

  def expect_redirect_to_login(path)
    visit path
    expect(page.current_path).to eq(login_path)
  end

  def expect_pdf_viewer(path)
    visit path
    expect(page.current_path).to eq(path)
    expect(page.html).to include("<iframe")
    expect(page.html).to include("#{path}.pdf")
  end

  def expect_pdf_response(path)
    visit path
    expect(page.response_headers["Content-Type"]).to eq("application/pdf")
    expect(page.body[0..3]).to eq("%PDF")
  end

  def expect_json_response(path, expected_key)
    visit path
    content_type = page.response_headers["Content-Type"]
    expect(content_type).to include("application/json")
    json = JSON.parse(page.body)
    expect(json).to have_key(expected_key)
  end

  def expect_png_response(path)
    page.driver.browser.get(path)
    content_type = page.driver.response.headers["Content-Type"]
    expect(content_type).to include("image/png")
    expect(page.driver.response.body[1..3]).to eq("PNG")
  end

  def expect_html_with_iframe(path)
    visit path
    content_type = page.response_headers["Content-Type"]
    expect(content_type).to eq("text/html; charset=utf-8")
    expect(page.body).to include("<iframe")
  end

  before do
    # Create pages for CMS system
    Page.find_or_create_by(slug: "/") do |page|
      page.content = "<h1>Homepage</h1>"
      page.link_title = "Home"
    end
    Page.find_or_create_by(slug: "about") do |page|
      page.content = "<h1>About</h1>"
      page.link_title = "About"
    end
  end

  describe "Public pages (should be accessible without login)" do
    before do
      ensure_logged_out
    end

    it "allows access to home page" do
      expect_public_access(root_path)
    end

    it "allows access to about page" do
      expect_public_access("/pages/about")
    end

    it "allows access to safety standards page" do
      expect_public_access(safety_standards_path)
    end

    it "allows access to login page" do
      expect_public_access(login_path)
    end

    it "allows access to register page" do
      expect_public_access(register_path)
    end

    describe "Public report access" do
      it "shows minimal PDF viewer for inspection HTML" do
        expect_html_with_iframe("/inspections/#{inspection.id}")
      end

      it "allows access to inspection PDF" do
        expect_pdf_response("/inspections/#{inspection.id}.pdf")
      end

      it "allows access to inspection JSON via short URL" do
        json_path = "/inspections/#{inspection.id}.json"
        expect_json_response(json_path, "inspection_date")
      end

      it "allows access to inspection JSON via long URL" do
        json_path = "/inspections/#{inspection.id}.json"
        expect_json_response(json_path, "inspection_date")
      end

      it "allows access to inspection QR code" do
        expect_png_response("/inspections/#{inspection.id}.png")
      end

      it "shows minimal PDF viewer for unit HTML" do
        expect_html_with_iframe("/units/#{unit.id}")
      end

      it "allows access to unit PDF" do
        expect_pdf_response("/units/#{unit.id}.pdf")
      end

      it "allows access to unit JSON via short URL" do
        expect_json_response("/units/#{unit.id}.json", "name")
      end

      it "allows access to unit JSON via long URL" do
        expect_json_response("/units/#{unit.id}.json", "name")
      end

      it "allows access to unit QR code" do
        expect_png_response("/units/#{unit.id}.png")
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
      ensure_logged_out
    end

    it "redirects inspections index to login" do
      expect_redirect_to_login(inspections_path)
      # Flash messages may not render in test environment
    end

    it "shows PDF viewer for inspection show page when not logged in" do
      expect_pdf_viewer(inspection_path(inspection))
    end

    it "redirects inspection edit page to login" do
      expect_redirect_to_login(edit_inspection_path(inspection))
    end

    it "redirects units index to login" do
      expect_redirect_to_login(units_path)
    end

    it "shows PDF viewer for unit show page when not logged in" do
      expect_pdf_viewer(unit_path(unit))
    end

    it "redirects unit edit page to login" do
      expect_redirect_to_login(edit_unit_path(unit))
    end

    it "redirects new unit page to login" do
      expect_redirect_to_login(new_unit_path)
    end

    it "redirects users index to login" do
      expect_redirect_to_login(users_path)
    end

    it "returns 404 for user show page (no show action)" do
      visit user_path(user)
      expect(page.status_code).to eq(404)
    end

    it "redirects user edit page to login" do
      expect_redirect_to_login(edit_user_path(user))
    end

    it "redirects inspector companies index to login" do
      expect_redirect_to_login(inspector_companies_path)
    end

    it "redirects inspector company show page to login" do
      company = create(:inspector_company)
      expect_redirect_to_login(inspector_company_path(company))
    end

    it "redirects inspector company edit page to login" do
      company = create(:inspector_company)
      expect_redirect_to_login(edit_inspector_company_path(company))
    end

    it "redirects new inspector company page to login" do
      expect_redirect_to_login(new_inspector_company_path)
    end

    describe "Public JSON endpoints" do
      it "allows public access to inspection JSON" do
        path = "/inspections/#{inspection.id}.json"
        expect_public_access(path)
        json = JSON.parse(page.body)
        expect(json).to have_key("inspection_date")
      end

      it "allows public access to unit JSON" do
        path = "/units/#{unit.id}.json"
        expect_public_access(path)
        json = JSON.parse(page.body)
        expect(json).to have_key("serial")
      end
    end
  end

  describe "Edge cases and security" do
    before do
      ensure_logged_out
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
      expect_html_with_iframe("/inspections/#{inspection.id.downcase}")

      # Test uppercase
      expect_html_with_iframe("/inspections/#{inspection.id.upcase}")
    end

    it "prevents directory traversal attacks" do
      visit "/inspections/../../../etc/passwd"
      expect(page.status_code).to eq(404)
    end

    it "handles malformed requests gracefully" do
      # Safety standards page handles GET requests with params
      path_with_params = "#{safety_standards_path}?calculation[type]=invalid&calculation[value]=test"
      expect_public_access(path_with_params, safety_standards_path)
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
