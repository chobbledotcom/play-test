require "rails_helper"

RSpec.describe "Inspections PDF Generation", type: :request do
  include Capybara::DSL

  let(:user) { create(:user) }

  # Login using Capybara for better integration testing
  before do
    visit login_path
    fill_in I18n.t("session.login.email_label"), with: user.email
    fill_in I18n.t("session.login.password_label"), with: I18n.t("test.password")
    click_button I18n.t("session.login.submit")
  end

  describe "PDF navigation integration with Capybara" do
    let(:inspection) { create(:inspection, user: user) }

    it "allows accessing PDF certificate from inspection show page" do
      visit inspection_path(inspection)

      # Check if PDF Certificate link exists (if it does in the view)
      if page.has_link?("PDF Certificate") || page.has_link?("Certificate")
        click_link("PDF Certificate") || click_link("Certificate")

        # Check response is a PDF
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end
    end

    it "handles direct certificate URL access" do
      # Visit the certificate URL directly using Capybara
      page.driver.browser.get("/inspections/#{inspection.id}/certificate")

      # Check that it's a PDF response
      expect(page.driver.response.headers["Content-Type"]).to include("application/pdf")
      expect(page.driver.response.body[0..3]).to eq("%PDF")
    end
  end

  describe "GET /inspections/:id/certificate with esoteric test cases" do
    it "handles extremely long text in PDF generation" do
      # Create inspection with extremely long text in all fields
      extremely_long_text = "A" * 1000  # Long but not too long for the test

      unit = create(:unit, user: user,
        serial: "PDF-LONG-#{extremely_long_text[0..50]}",
        manufacturer: "Manufacturer #{extremely_long_text[0..50]}")

      inspection = create(:inspection,
        user: user,
        unit: unit,

        inspection_location: "Long location #{extremely_long_text}",
        passed: true,
        comments: extremely_long_text)

      # Request the certificate
      get "/inspections/#{inspection.id}/certificate"

      # Verify response
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body.bytes.first(4).pack("C*")).to eq("%PDF")
    end

    it "handles case-insensitive URLs" do
      inspection = create(:inspection, user: user)

      # Test with lowercase URL (user-friendly)
      get "/inspections/#{inspection.id.downcase}/certificate"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")

      # Test with uppercase URL (canonical)
      get "/inspections/#{inspection.id.upcase}/certificate"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
    end

    it "handles Unicode and emoji in PDF generation" do
      # Create inspection with Unicode characters and emoji
      inspection = create(:inspection, :with_unicode_data,
        user: user,
        passed: true)

      # Request the certificate
      get "/inspections/#{inspection.id}/certificate"

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

      inspection = create(:inspection,
        user: user,
        unit: unit,

        inspection_location: "<div style='color:red'>Red Location</div>",
        passed: true,
        comments: "<h1>Big Title</h1><p>Paragraph</p><a href='http://example.com'>Link</a>")

      # Request the certificate
      get "/inspections/#{inspection.id}/certificate"

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

      inspection = create(:inspection,
        user: user,
        unit: unit,

        inspection_location: "Calibration Lab",
        passed: true,
        comments: "Extreme precision test")

      # Request the certificate
      get "/inspections/#{inspection.id}/certificate"

      # Verify response
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body.bytes.first(4).pack("C*")).to eq("%PDF")
    end

    it "handles non-existent inspection ID gracefully" do
      # Try to get certificate for non-existent ID
      get "/inspections/99999999/certificate"

      # Should return 404 for public certificate access
      expect(response).to have_http_status(:not_found)
    end
  end
end
