require "rails_helper"

RSpec.describe "Inspections PDF Generation", type: :request do
  let(:user) { User.create!(email: "test@example.com", password: "password", password_confirmation: "password") }

  # Mock user login for all inspection tests since they require login
  before do
    allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "GET /inspections/:id/certificate with esoteric test cases" do
    it "handles extremely long text in PDF generation" do
      # Create inspection with extremely long text in all fields
      extremely_long_text = "A" * 1000  # Long but not too long for the test

      inspection = Inspection.create!(
        user: user,
        inspector: "PDF #{extremely_long_text}",
        serial: "PDF-LONG-#{extremely_long_text[0..50]}",
        location: "Long location #{extremely_long_text}",
        manufacturer: "Manufacturer #{extremely_long_text[0..50]}",
        passed: true,
        comments: extremely_long_text
      )

      # Request the certificate
      get "/inspections/#{inspection.id}/certificate"

      # Verify response
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body.bytes.first(4).pack("C*")).to eq("%PDF")
    end

    it "handles Unicode and emoji in PDF generation" do
      # Create inspection with Unicode characters and emoji
      inspection = Inspection.create!(
        user: user,
        inspector: "Jörgen Müller 👨‍🔧",
        serial: "PDF-ÜNICØDÉ-😎-123",
        location: "Meeting Room 🏢 3F",
        manufacturer: "Åpple Inc. 💻",
        passed: true,
        comments: "❗️Tested with special 🔌 adapter. Result: ✅"
      )

      # Request the certificate
      get "/inspections/#{inspection.id}/certificate"

      # Verify response
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body.bytes.first(4).pack("C*")).to eq("%PDF")
    end

    it "handles HTML-like content in text fields for PDF generation" do
      # Create inspection with HTML-like content
      inspection = Inspection.create!(
        user: user,
        inspector: "<script>alert('XSS')</script>",
        serial: "PDF-HTML-123",
        location: "<div style='color:red'>Red Location</div>",
        manufacturer: "<b>Bold Company</b>",
        passed: true,
        comments: "<h1>Big Title</h1><p>Paragraph</p><a href='http://example.com'>Link</a>"
      )

      # Request the certificate
      get "/inspections/#{inspection.id}/certificate"

      # Verify response
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
      expect(response.body.bytes.first(4).pack("C*")).to eq("%PDF")
    end

    it "handles extremely precise numeric values in PDF generation" do
      # Create inspection with extreme numeric values
      inspection = Inspection.create!(
        user: user,
        inspector: "Precision Tester PDF",
        serial: "PDF-PRECISE-123",
        location: "Calibration Lab",
        manufacturer: "Precision Instruments, Inc.",
        passed: true,
        comments: "Extreme precision test"
      )

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

      # Should redirect with flash message
      expect(response).to have_http_status(:redirect)
      expect(flash[:danger]).to include("not found")
    end
  end
end
