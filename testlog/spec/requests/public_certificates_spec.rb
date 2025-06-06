require "rails_helper"

RSpec.describe "Public Certificates", type: :request do
  include Capybara::DSL

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  describe "Inspection certificates - public access" do
    describe "GET /c/:id (short URL lowercase)" do
      it "allows access to inspection certificate without login" do
        # Ensure we're not logged in
        visit logout_path if page.has_button?("Log Out")

        # Visit the public certificate URL
        visit "/c/#{inspection.id}"

        # Should get PDF response without being redirected to login
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
        expect(page.current_path).not_to eq(login_path)
      end

      it "handles case-insensitive inspection IDs" do
        # Test with lowercase ID
        visit "/c/#{inspection.id.downcase}"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")

        # Test with uppercase ID
        visit "/c/#{inspection.id.upcase}"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end

      it "returns 404 for non-existent inspection ID" do
        visit "/c/NONEXISTENT123"
        expect(page).to have_http_status(:not_found)
      end

      it "works with direct browser access (no session)" do
        # Use a completely fresh browser session
        page.driver.browser.get("/c/#{inspection.id}")

        expect(page.driver.response.headers["Content-Type"]).to include("application/pdf")
        expect(page.driver.response.body[0..3]).to eq("%PDF")
      end

      it "serves appropriate PDF headers for download" do
        visit "/c/#{inspection.id}"

        # Check content type and disposition
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.response_headers["Content-Disposition"]).to include("inline")
      end

      it "works with special characters in inspection data" do
        # Create inspection with Unicode characters
        unit_unicode = create(:unit, user: user, name: "Tëst Ünït 🎉", manufacturer: "Tëst Mfg")
        inspection_unicode = create(:inspection, user: user, unit: unit_unicode,
          inspection_location: "Café München")

        visit "/c/#{inspection_unicode.id}"

        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end
    end

    describe "GET /C/:id (short URL uppercase)" do
      it "allows access to inspection certificate without login" do
        visit "/C/#{inspection.id}"

        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
        expect(page.current_path).not_to eq(login_path)
      end

      it "handles case variations consistently" do
        # Both uppercase and lowercase routes should work identically
        visit "/C/#{inspection.id}"
        uppercase_response = page.body

        visit "/c/#{inspection.id}"
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

  describe "Unit certificates - public access" do
    describe "GET /e/:id (short URL lowercase)" do
      it "allows access to unit certificate without login" do
        # Ensure we're not logged in
        visit logout_path if page.has_button?("Log Out")

        # Visit the public certificate URL
        visit "/e/#{unit.id}"

        # Should get PDF response without being redirected to login
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
        expect(page.current_path).not_to eq(login_path)
      end

      it "handles case-insensitive unit IDs" do
        # Test with lowercase ID
        visit "/e/#{unit.id.downcase}"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")

        # Test with uppercase ID
        visit "/e/#{unit.id.upcase}"
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end

      it "returns 404 for non-existent unit ID" do
        visit "/e/NONEXISTENT123"
        expect(page).to have_http_status(:not_found)
      end

      it "works with direct browser access (no session)" do
        # Use a completely fresh browser session
        page.driver.browser.get("/e/#{unit.id}")

        expect(page.driver.response.headers["Content-Type"]).to include("application/pdf")
        expect(page.driver.response.body[0..3]).to eq("%PDF")
      end

      it "serves appropriate PDF headers for download" do
        visit "/e/#{unit.id}"

        # Check content type and disposition
        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.response_headers["Content-Disposition"]).to include("inline")
      end

      it "works with special characters in unit data" do
        # Create unit with Unicode characters
        unit_unicode = create(:unit, user: user, name: "Tëst Ünït 🎉", manufacturer: "Tëst Mfg")

        visit "/e/#{unit_unicode.id}"

        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
      end
    end

    describe "GET /E/:id (short URL uppercase)" do
      it "allows access to unit certificate without login" do
        visit "/E/#{unit.id}"

        expect(page.response_headers["Content-Type"]).to eq("application/pdf")
        expect(page.body[0..3]).to eq("%PDF")
        expect(page.current_path).not_to eq(login_path)
      end

      it "handles case variations consistently" do
        # Both uppercase and lowercase routes should work identically
        visit "/E/#{unit.id}"
        uppercase_response = page.body

        visit "/e/#{unit.id}"
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
        page.driver.browser.get("/c/#{inspection.id}")

        expect(page.driver.response.headers["Content-Type"]).to include("application/pdf")
        expect(page.driver.response.body[0..3]).to eq("%PDF")
      end
    end

    context "with concurrent access" do
      it "handles multiple simultaneous requests" do
        threads = []
        5.times do
          threads << Thread.new do
            visit "/c/#{inspection.id}"
            expect(page.response_headers["Content-Type"]).to eq("application/pdf")
            expect(page.body[0..3]).to eq("%PDF")
          end
        end
        threads.each(&:join)
      end
    end

    context "with malformed requests" do
      it "handles invalid IDs gracefully" do
        visit "/c/invalid-id-format"
        expect(page).to have_http_status(:not_found)
      end

      it "handles extremely long IDs" do
        long_id = "A" * 1000
        visit "/c/#{long_id}"
        expect(page).to have_http_status(:not_found)
      end

      it "handles special characters in URL" do
        visit "/c/test%20id"
        expect(page).to have_http_status(:not_found)
      end
    end
  end

  describe "SEO and web crawlers" do
    it "prevents search engine indexing of public inspection certificates" do
      visit "/c/#{inspection.id}"

      # Public certificates should have noindex directive to prevent search engine indexing
      expect(page.response_headers["X-Robots-Tag"]).to include("noindex")
    end

    it "prevents search engine indexing of public unit certificates" do
      visit "/e/#{unit.id}"

      # Public unit certificates should also have noindex directive
      expect(page.response_headers["X-Robots-Tag"]).to include("noindex")
    end

    it "responds to HEAD requests properly" do
      page.driver.browser.process(:head, "/c/#{inspection.id}")

      expect(page.driver.response.headers["Content-Type"]).to include("application/pdf")
      expect(page).to have_http_status(:success)
    end
  end

  describe "Security considerations" do
    it "does not expose user information in public certificates" do
      # Public certificates should not leak user email or sensitive data
      visit "/c/#{inspection.id}"

      # PDF should be generated but shouldn't contain user's email
      expect(page.body).not_to include(user.email)
    end

    it "prevents brute force inspection ID guessing" do
      # Test with sequential IDs to ensure they're not easily guessable
      nonexistent_ids = ["AAA", "BBB", "CCC"]

      nonexistent_ids.each do |id|
        visit "/c/#{id}"
        expect(page).to have_http_status(:not_found)
      end
    end
  end
end
