require "rails_helper"

RSpec.describe "Units PDF Generation", type: :request do
  include Capybara::DSL

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user, name: "Test Unit", manufacturer: "ACME Corp") }

  before do
    login_user_via_form(user)
  end

  describe "GET /units/:id/report" do

    it "handles missing unit gracefully" do
      visit "/units/NONEXISTENT/report"

      # Should return 404 for public report access
      expect(page).to have_http_status(:not_found)
    end

    it "allows access to other user's unit report" do
      other_user = create(:user, email: "other@example.com")
      other_unit = create(:unit, user: other_user)

      visit "/units/#{other_unit.id}.pdf"

      # Unit reports are now publicly accessible - should return PDF
      expect(page.response_headers["Content-Type"]).to eq("application/pdf")
      expect(page.body[0..3]).to eq("%PDF")
    end

    it "generates PDF with Unicode content" do
      unit.update!(name: "Test Unit with émojis 🎉", manufacturer: "Tëst Mánufäcturer")

      visit unit_path(unit)
      click_link I18n.t("units.buttons.pdf_report")

      # Verify PDF is generated despite Unicode content
      expect(page.response_headers["Content-Type"]).to eq("application/pdf")
      expect(page.body[0..3]).to eq("%PDF")
    end
  end

  describe "PDF download integration" do
    it "sets proper filename for PDF download" do
      get_pdf("/units/#{unit.id}.pdf")

      content_disposition = page.driver.response.headers["Content-Disposition"]
      expect(content_disposition).to include("#{unit.serial}.pdf")
      expect(content_disposition).to include("inline")
    end
  end

  describe "QR code generation integration" do
    it "generates QR code for unit" do
      visit unit_path(unit)

      # The QR code endpoint should be accessible (though we can't easily test the image)
      page.driver.browser.get("/units/#{unit.id}.png")

      # Check that it's a PNG response
      expect(page.driver.response.headers["Content-Type"]).to include("image/png")
      expect(page.driver.response.body[1..3]).to eq("PNG") # PNG signature
    end
  end
end
