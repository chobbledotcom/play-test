require "rails_helper"

RSpec.describe "Units PDF Generation", type: :request do
  include Capybara::DSL

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user, name: "Test Unit", manufacturer: "ACME Corp") }

  before do
    visit login_path
    fill_in I18n.t("session.login.email_label"), with: user.email
    fill_in I18n.t("session.login.password_label"), with: I18n.t("test.password")
    click_button I18n.t("session.login.submit")
  end

  describe "GET /units/:id/certificate" do
    it "generates PDF certificate for unit" do
      visit unit_path(unit)

      # Check if PDF Report link exists
      expect(page).to have_link("PDF Report")

      # Click the PDF Report link
      click_link "PDF Report"

      # Check response is a PDF
      expect(page.response_headers["Content-Type"]).to eq("application/pdf")
      expect(page.body[0..3]).to eq("%PDF")
    end

    it "handles unit with inspections in PDF" do
      # Create inspections for the unit
      create(:inspection, user: user, unit: unit, passed: true, inspector: "John Inspector")
      create(:inspection, user: user, unit: unit, passed: false, inspector: "Jane Inspector")

      visit unit_path(unit)
      click_link "PDF Report"

      # Verify PDF is generated
      expect(page.response_headers["Content-Type"]).to eq("application/pdf")
      expect(page.body[0..3]).to eq("%PDF")
    end

    it "handles missing unit gracefully" do
      visit "/units/NONEXISTENT/certificate"

      # Should return 404 for public certificate access
      expect(page).to have_http_status(:not_found)
    end

    it "allows access to other user's unit certificate" do
      other_user = create(:user, email: "other@example.com")
      other_unit = create(:unit, user: other_user)

      visit "/units/#{other_unit.id}/certificate"

      # Unit certificates are now publicly accessible - should return PDF
      expect(page.response_headers["Content-Type"]).to eq("application/pdf")
      expect(page.body[0..3]).to eq("%PDF")
    end

    it "generates PDF with Unicode content" do
      unit.update!(name: "Test Unit with émojis 🎉", manufacturer: "Tëst Mánufäcturer")

      visit unit_path(unit)
      click_link "PDF Report"

      # Verify PDF is generated despite Unicode content
      expect(page.response_headers["Content-Type"]).to eq("application/pdf")
      expect(page.body[0..3]).to eq("%PDF")
    end
  end

  describe "PDF download integration" do
    it "allows downloading PDF through direct link" do
      # Visit the certificate URL directly
      page.driver.browser.get("/units/#{unit.id}/certificate")

      # Check that it's a PDF response
      expect(page.driver.response.headers["Content-Type"]).to include("application/pdf")
      expect(page.driver.response.body[0..3]).to eq("%PDF")
    end

    it "sets proper filename for PDF download" do
      page.driver.browser.get("/units/#{unit.id}/certificate")

      content_disposition = page.driver.response.headers["Content-Disposition"]
      expect(content_disposition).to include("Equipment_History_#{unit.serial}.pdf")
      expect(content_disposition).to include("inline")
    end
  end

  describe "QR code generation integration" do
    it "generates QR code for unit" do
      visit unit_path(unit)

      # The QR code endpoint should be accessible (though we can't easily test the image)
      page.driver.browser.get("/units/#{unit.id}/qr_code")

      # Check that it's a PNG response
      expect(page.driver.response.headers["Content-Type"]).to include("image/png")
      expect(page.driver.response.body[1..3]).to eq("PNG") # PNG signature
    end
  end
end
