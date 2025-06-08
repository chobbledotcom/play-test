require "rails_helper"

RSpec.describe "Inspection PDF Embed", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before { login_as(user) }

  describe "GET /inspections/:id.pdf" do
    context "with complete inspection with all assessments" do
      let(:inspection) do
        create(:inspection, user: user, unit: unit, status: "completed").tap do |insp|
          # Create complete assessments
          create(:user_height_assessment, :complete, inspection: insp)
          create(:structure_assessment, :complete, inspection: insp)
          create(:anchorage_assessment, :passed, inspection: insp)
          create(:materials_assessment, :passed, inspection: insp)
          create(:fan_assessment, :passed, inspection: insp)
          insp.update!(status: "complete")
        end
      end

      it "renders the PDF" do
        get inspection_path(inspection, format: :pdf)

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("PAT_Report_#{inspection.serial}.pdf")
      end
    end

    context "with completed inspection" do
      let(:inspection) { create(:inspection, user: user, unit: unit, status: "completed") }

      it "renders the PDF" do
        get inspection_path(inspection, format: :pdf)

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/pdf")
      end
    end

    context "with draft inspection" do
      let(:inspection) { create(:inspection, user: user, unit: unit, status: "draft") }

      it "redirects with error message" do
        get inspection_path(inspection, format: :pdf)

        expect(response).to redirect_to(inspection_path(inspection))
        expect(flash[:danger]).to eq(I18n.t("inspections.errors.pdf_not_available"))
      end
    end
  end
end
