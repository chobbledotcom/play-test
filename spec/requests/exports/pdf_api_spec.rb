require "rails_helper"

RSpec.describe "PDF API Endpoints", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user, manufacturer: "Test Manufacturer", serial: "TEST123") }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  before do
    login_as(user)
  end

  describe "Inspection PDF endpoints" do
    describe "GET /inspections/:id.pdf" do
      it "returns a PDF for valid inspection" do
        get "/inspections/#{inspection.id}.pdf"

        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("inline")
        expect(response.body[0..3]).to eq("%PDF")
      end

      it "handles case-insensitive inspection IDs" do
        get "/inspections/#{inspection.id.upcase}.pdf"

        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("application/pdf")
      end

      it "returns 404 for non-existent inspection" do
        get "/inspections/NONEXISTENT.pdf"

        expect(response).to have_http_status(:not_found)
      end

      it "allows access to other users' inspections (public reports)" do
        other_user = create(:user)
        other_inspection = create(:inspection, :completed, user: other_user)

        get "/inspections/#{other_inspection.id}.pdf"

        # Reports are public, so this should succeed
        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("application/pdf")
      end

    end

    describe "GET /inspections/:id.pdf" do
      it "returns PDF via .pdf format" do
        get inspection_path(inspection, format: :pdf)

        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("inline")
      end

      it "allows PDF generation for draft inspections" do
        draft_inspection = create(:inspection, user: user, complete_date: nil)

        get inspection_path(draft_inspection, format: :pdf)

        # Draft inspections can generate PDFs
        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("application/pdf")
      end
    end

    describe "GET /inspections/:id (public access)" do
      it "shows minimal PDF viewer for HTML requests" do
        # Clear authentication for public access test
        logout

        get "/inspections/#{inspection.id}"

        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(response.body).to include("<iframe")
      end

      it "allows public access to PDF format" do
        # Clear authentication for public access test
        logout

        get "/inspections/#{inspection.id}.pdf"

        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("application/pdf")
      end

      it "handles case-insensitive public URLs" do
        logout

        get "/inspections/#{inspection.id.upcase}"

        expect(response).to have_http_status(:success)
      end

      it "returns 404 for non-existent public reports when not logged in" do
        logout

        get "/inspections/NONEXISTENT"

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "Unit PDF endpoints" do
    describe "GET /units/:id.pdf" do
      it "returns a PDF for valid unit" do
        get "/units/#{unit.id}.pdf"

        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("inline")
        expect(response.body[0..3]).to eq("%PDF")
      end

      it "includes unit details in PDF" do
        get "/units/#{unit.id}.pdf"

        # Should contain I18n unit report title
        pdf_text = pdf_text_content(response.body)
        expect(pdf_text).to include(I18n.t("pdf.unit.title"))
        expect(pdf_text).to include(unit.manufacturer)
      end

      it "handles units with no inspections" do
        empty_unit = create(:unit, user: user)

        get "/units/#{empty_unit.id}.pdf"

        expect(response).to have_http_status(:success)

        pdf_text = pdf_text_content(response.body)
        expect(pdf_text).to include(I18n.t("pdf.unit.no_completed_inspections"))
      end

    end

    describe "GET /units/:id.png" do
      it "returns QR code PNG for valid unit" do
        get "/units/#{unit.id}.png"

        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("image/png")
        expect(response.body.force_encoding("ASCII-8BIT")[0..3]).to eq("\x89PNG".force_encoding("ASCII-8BIT"))
      end
    end

    describe "GET /units/:id (public access)" do
      it "shows minimal PDF viewer for HTML requests" do
        logout

        get "/units/#{unit.id}"

        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(response.body).to include("<iframe")
      end

      it "allows public access to PDF format" do
        logout

        get "/units/#{unit.id}.pdf"

        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("application/pdf")
      end
    end
  end

  describe "QR Code endpoints" do
    describe "GET /inspections/:id.png" do
      it "returns QR code PNG for inspection" do
        get "/inspections/#{inspection.id}.png"

        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq("image/png")
        expect(response.body.force_encoding("ASCII-8BIT")[0..3]).to eq("\x89PNG".force_encoding("ASCII-8BIT"))
      end

      it "allows public access to inspection QR codes" do
        logout

        get "/inspections/#{inspection.id}.png"

        expect(response).to have_http_status(:success)
      end
    end
  end


  private

  def logout
    # Clear authentication for public access tests
    reset_session if respond_to?(:reset_session)
  end
end
