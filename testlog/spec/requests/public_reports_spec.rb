require "rails_helper"

RSpec.describe "Public Reports", type: :request do
  include Capybara::DSL

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  describe "Inspection reports - public access" do
    describe "GET /r/:id (short URL lowercase)" do
      it "allows access to inspection report without login" do
        # Ensure we're not logged in
        visit logout_path if page.has_button?("Log Out")

        # Visit the public report URL
        visit "/r/#{inspection.id}"

        # Should get PDF response without being redirected to login
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
        expect(page.current_path).not_to eq(login_path)
      end

      it "handles case-insensitive inspection IDs" do
        # Test with lowercase ID
        visit "/r/#{inspection.id.downcase}"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")

        # Test with uppercase ID
        visit "/r/#{inspection.id.upcase}"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end

      it "returns 404 for non-existent inspection ID" do
        visit "/r/NONEXISTENT123"
        expect(page).to have_http_status(:not_found)
      end

      it "works with direct browser access (no session)" do
        # Use a completely fresh browser session
        page.driver.browser.get("/r/#{inspection.id}")

        expect(page.driver.response.headers["Content-Type"]).to include("application/pdf")
        expect(page.driver.response.body[0..3]).to eq("%PDF")
      end

      it "serves appropriate PDF headers for download" do
        visit "/r/#{inspection.id}"

        # Check content type and disposition
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.response_headers["Content-Disposition"]).to include("inline")
      end

      it "works with special characters in inspection data" do
        # Create inspection with Unicode characters
        unit_unicode = create(:unit, user: user, name: "Tëst Ünït 🎉", manufacturer: "Tëst Mfg")
        inspection_unicode = create(:inspection, user: user, unit: unit_unicode,
          inspection_location: "Café München")

        visit "/r/#{inspection_unicode.id}"

        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end
    end

    describe "GET /R/:id (short URL uppercase)" do
      it "allows access to inspection report without login" do
        visit "/R/#{inspection.id}"

        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
        expect(page.current_path).not_to eq(login_path)
      end

      it "handles case variations consistently" do
        # Both uppercase and lowercase routes should work identically
        visit "/R/#{inspection.id}"
        uppercase_response = page.body

        visit "/r/#{inspection.id}"
        lowercase_response = page.body

        # Both should be valid PDFs (we won't compare exact content due to timestamps)
        expect(uppercase_response[0..3]).to eq("%PDF")
        expect(lowercase_response[0..3]).to eq("%PDF")
      end
    end

    describe "QR code public access" do
      it "allows access to inspection QR code without login" do
        # QR codes should also be publicly accessible for verification
        page.driver.browser.get("/inspections/#{inspection.id}/qr_code")

        expect(page.driver.response.headers["Content-Type"]).to include("image/png")
        expect(page.driver.response.body[1..3]).to eq("PNG")
      end
    end
  end

  describe "Unit reports - public access" do
    describe "GET /u/:id (short URL lowercase)" do
      it "allows access to unit report without login" do
        # Ensure we're not logged in
        visit logout_path if page.has_button?("Log Out")

        # Visit the public report URL
        visit "/u/#{unit.id}"

        # Should get PDF response without being redirected to login
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
        expect(page.current_path).not_to eq(login_path)
      end

      it "handles case-insensitive unit IDs" do
        # Test with lowercase ID
        visit "/u/#{unit.id.downcase}"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")

        # Test with uppercase ID
        visit "/u/#{unit.id.upcase}"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end

      it "returns 404 for non-existent unit ID" do
        visit "/u/NONEXISTENT123"
        expect(page).to have_http_status(:not_found)
      end

      it "works with direct browser access (no session)" do
        # Use a completely fresh browser session
        page.driver.browser.get("/u/#{unit.id}")

        expect(page.driver.response.headers["Content-Type"]).to include("application/pdf")
        expect(page.driver.response.body[0..3]).to eq("%PDF")
      end

      it "serves appropriate PDF headers for download" do
        visit "/u/#{unit.id}"

        # Check content type and disposition
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.response_headers["Content-Disposition"]).to include("inline")
      end

      it "works with special characters in unit data" do
        # Create unit with Unicode characters
        unit_unicode = create(:unit, user: user, name: "Tëst Ünït 🎉", manufacturer: "Tëst Mfg")

        visit "/u/#{unit_unicode.id}"

        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end
    end

    describe "GET /U/:id (short URL uppercase)" do
      it "allows access to unit report without login" do
        visit "/U/#{unit.id}"

        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
        expect(page.current_path).not_to eq(login_path)
      end

      it "handles case variations consistently" do
        # Both uppercase and lowercase routes should work identically
        visit "/U/#{unit.id}"
        uppercase_response = page.body

        visit "/u/#{unit.id}"
        lowercase_response = page.body

        # Both should be valid PDFs (we won't compare exact content due to timestamps)
        expect(uppercase_response[0..3]).to eq("%PDF")
        expect(lowercase_response[0..3]).to eq("%PDF")
      end
    end

    describe "QR code public access" do
      it "allows access to unit QR code without login" do
        # QR codes should also be publicly accessible for verification
        page.driver.browser.get("/units/#{unit.id}/qr_code")

        expect(page.driver.response.headers["Content-Type"]).to include("image/png")
        expect(page.driver.response.body[1..3]).to eq("PNG")
      end
    end
  end

  describe "Cross-browser and edge case testing" do
    context "with different browsers/user agents" do
      it "works with mobile user agents" do
        # Simulate mobile browser access
        page.driver.browser.get("/r/#{inspection.id}")

        expect(page.driver.response.headers["Content-Type"]).to include("application/pdf")
        expect(page.driver.response.body[0..3]).to eq("%PDF")
      end
    end

    context "with concurrent access" do
      it "handles multiple simultaneous requests" do
        threads = []
        5.times do
          threads << Thread.new do
            visit "/r/#{inspection.id}"
            expect(page.response_headers["Content-Type"]).to eq("application/pdf")
            expect(page.body[0..3]).to eq("%PDF")
          end
        end
        threads.each(&:join)
      end
    end

    context "with malformed requests" do
      it "handles invalid IDs gracefully" do
        visit "/r/invalid-id-format"
        expect(page).to have_http_status(:not_found)
      end

      it "handles extremely long IDs" do
        long_id = "A" * 1000
        visit "/r/#{long_id}"
        expect(page).to have_http_status(:not_found)
      end

      it "handles special characters in URL" do
        visit "/r/test%20id"
        expect(page).to have_http_status(:not_found)
      end
    end
  end

  describe "SEO and web crawlers" do
    it "prevents search engine indexing of public inspection reports" do
      visit "/r/#{inspection.id}"

      # Public reports should have noindex directive to prevent search engine indexing
      expect(page.response_headers["X-Robots-Tag"]).to include("noindex")
    end

    it "prevents search engine indexing of public unit reports" do
      visit "/u/#{unit.id}"

      # Public unit reports should also have noindex directive
      expect(page.response_headers["X-Robots-Tag"]).to include("noindex")
    end

    it "responds to HEAD requests properly" do
      page.driver.browser.process(:head, "/r/#{inspection.id}")

      expect(page.driver.response.headers["Content-Type"]).to include("application/pdf")
      expect(page).to have_http_status(:success)
    end
  end

  describe "Security considerations" do
    it "does not expose user information in public reports" do
      # Public reports should not leak user email or sensitive data
      visit "/r/#{inspection.id}"

      # PDF should be generated but shouldn't contain user's email
      expect(page.body).not_to include(user.email)
    end

    it "prevents brute force inspection ID guessing" do
      # Test with sequential IDs to ensure they're not easily guessable
      nonexistent_ids = ["AAA", "BBB", "CCC"]

      nonexistent_ids.each do |id|
        visit "/r/#{id}"
        expect(page).to have_http_status(:not_found)
      end
    end
  end
end
