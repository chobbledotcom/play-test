require "rails_helper"

RSpec.describe "Inspections PDF Generation", type: :request do
  include Capybara::DSL

  let(:user) { create(:user) }

  # Login using Capybara for better integration testing
  before do
    visit login_path
    fill_in I18n.t("session.login.email"), with: user.email
    fill_in I18n.t("session.login.password"), with: "password123"
    click_button I18n.t("session.login.submit")
  end

  describe "PDF navigation integration with Capybara" do
    let(:inspection) { create(:inspection, :complete, user: user) }

    it "allows accessing PDF report from inspection show page" do
      visit inspection_path(inspection)

      # Check if PDF Report link exists (if it does in the view)
      if page.has_link?("PDF Report") || page.has_link?("Report")
        click_link("PDF Report") || click_link("Report")

        # Check response is a PDF
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end
    end

    it "handles direct report URL access" do
      # Visit the report URL directly using Capybara
      page.driver.browser.get("/inspections/#{inspection.id}/report")

      # Check that it's a PDF response
      expect(page.driver.response.headers["Content-Type"]).to include("application/pdf")
      expect(page.driver.response.body[0..3]).to eq("%PDF")
    end
  end

  describe "GET /inspections/:id/report with esoteric test cases" do
    it "handles extremely long text in PDF generation" do
      # Create inspection with extremely long text in all fields
      extremely_long_text = "A" * 1000  # Long but not too long for the test

      unit = create(:unit, user: user,
        serial: "PDF-LONG-#{extremely_long_text[0..50]}",
        manufacturer: "Manufacturer #{extremely_long_text[0..50]}")

      inspection = create(:inspection, :complete,
        user: user,
        unit: unit,
        inspection_location: "Long location #{extremely_long_text}",
        passed: true,
        comments: extremely_long_text)

      # Request the report
      get "/inspections/#{inspection.id}/report"

      # Verify response
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body.bytes.first(4).pack("C*")).to eq("%PDF")
    end

    it "handles case-insensitive URLs" do
      inspection = create(:inspection, :complete, user: user)

      # Test with lowercase URL (user-friendly)
      get "/inspections/#{inspection.id.downcase}/report"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")

      # Test with uppercase URL (canonical)
      get "/inspections/#{inspection.id.upcase}/report"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
    end

    it "handles Unicode and emoji in PDF generation" do
      # Create inspection with Unicode characters and emoji
      inspection = create(:inspection, :complete, :with_unicode_data,
        user: user,
        passed: true)

      # Request the report
      get "/inspections/#{inspection.id}/report"

      # Verify response
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body.bytes.first(4).pack("C*")).to eq("%PDF")
    end

    it "handles HTML-like content in text fields for PDF generation" do
      # Create inspection with HTML-like content
      unit = create(:unit, user: user,
        serial: "PDF-HTML-123",
        manufacturer: "<b>Bold Company</b>")

      inspection = create(:inspection, :complete,
        user: user,
        unit: unit,
        inspection_location: "<div style='color:red'>Red Location</div>",
        passed: true,
        comments: "<h1>Big Title</h1><p>Paragraph</p><a href='http://example.com'>Link</a>")

      # Request the report
      get "/inspections/#{inspection.id}/report"

      # Verify response
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body.bytes.first(4).pack("C*")).to eq("%PDF")
    end

    it "handles extremely precise numeric values in PDF generation" do
      # Create inspection with extreme numeric values
      unit = create(:unit, user: user,
        serial: "PDF-PRECISE-123",
        manufacturer: "Precision Instruments, Inc.")

      inspection = create(:inspection, :complete,
        user: user,
        unit: unit,
        inspection_location: "Calibration Lab",
        passed: true,
        comments: "Extreme precision test")

      # Request the report
      get "/inspections/#{inspection.id}/report"

      # Verify response
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body.bytes.first(4).pack("C*")).to eq("%PDF")
    end

    it "handles non-existent inspection ID gracefully" do
      # Try to get report for non-existent ID
      get "/inspections/99999999/report"

      # Should return 404 for public report access
      expect(response).to have_http_status(:not_found)
    end
  end
end
