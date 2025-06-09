require "rails_helper"

RSpec.describe "Inspections", type: :request do
  # Shared test data
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:user_without_company) { create(:user, :without_company) }
  let(:user_with_limit) { create(:user, inspection_limit: 0) }

  let(:valid_inspection_attributes) do
    {
      inspection_date: Date.today,
      inspection_location: "Test Location",
      passed: true,
      comments: "Test comments",
      complete_date: nil
    }
  end

  # Helper methods
  def expect_redirect_with_alert(path, alert_pattern = nil)
    expect(response).to redirect_to(path)
    expect(flash[:alert]).to be_present
    expect(flash[:alert]).to match(alert_pattern) if alert_pattern
  end

  def expect_success_with_notice(notice_pattern = nil)
    expect(response).to have_http_status(:redirect)
    follow_redirect!
    expect(response).to have_http_status(:success)
    expect(flash[:notice]).to match(notice_pattern) if notice_pattern
  end

  def mock_failing_save(error_messages = ["Validation error"])
    allow_any_instance_of(Inspection).to receive(:save).and_return(false)
    allow_any_instance_of(Inspection).to receive(:errors).and_return(
      double(full_messages: error_messages)
    )
  end

  def mock_failing_update(error_messages = ["Update error"])
    allow_any_instance_of(Inspection).to receive(:update).and_return(false)
    allow_any_instance_of(Inspection).to receive(:errors).and_return(
      double(full_messages: error_messages)
    )
  end

  describe "authentication requirements" do
    %w[index show edit].each do |action|
      it "redirects to login for #{action}" do
        get "/inspections#{"/" + SecureRandom.hex(6) if action != "index"}"
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to include("Please log in")
      end
    end

    %w[create update destroy].each do |action|
      it "redirects to login for #{action}" do
        inspection = create(:inspection, user: user, unit: unit)
        case action
        when "create"
          post "/inspections", params: {inspection: valid_inspection_attributes}
        when "update"
          patch "/inspections/#{inspection.id}", params: {inspection: {comments: "test"}}
        when "destroy"
          delete "/inspections/#{inspection.id}"
        end
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to include("Please log in")
      end
    end
  end

  describe "authorization requirements" do
    let!(:user_inspection) { create(:inspection, user: user, unit: unit) }
    let!(:other_inspection) { create(:inspection, user: other_user, unit: create(:unit, user: other_user)) }

    before { login_as(user) }

    it "only shows user's own inspections in index" do
      get "/inspections"
      expect(response).to have_http_status(:success)
      expect(response.body).to include(user_inspection.serial)
      expect(response.body).not_to include(other_inspection.serial)
    end

    %w[show edit update destroy].each do |action|
      it "prevents access to other user's inspection for #{action}" do
        case action
        when "show", "edit"
          get "/inspections/#{other_inspection.id}#{"/" + action if action == "edit"}"
        when "update"
          patch "/inspections/#{other_inspection.id}", params: {inspection: {comments: "hack"}}
        when "destroy"
          delete "/inspections/#{other_inspection.id}"
        end

        expect_redirect_with_alert(inspections_path, /Access denied/)
      end
    end
  end

  describe "when logged in" do
    before { login_as(user) }

    describe "GET /index" do
      it "returns success" do
        get "/inspections"
        expect(response).to have_http_status(:success)
      end

      it "filters by parameters" do
        create(:inspection, :completed, user: user, unit: unit, passed: true)

        get "/inspections", params: {result: "passed"}
        expect(response).to have_http_status(:success)
        expect(assigns(:title)).to include("Passed")
      end

      it "exports CSV" do
        create(:inspection, :completed, user: user, unit: unit, comments: "Test")

        get "/inspections.csv"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/csv")
        expect(response.body).to include("Test")
      end
    end

    describe "GET /show" do
      let(:inspection) { create(:inspection, user: user, unit: unit) }

      it "returns success" do
        get "/inspections/#{inspection.id}"
        expect(response).to have_http_status(:success)
      end

      it "serves PDF" do
        allow(PdfGeneratorService).to receive(:generate_inspection_report).and_return(double(render: "PDF"))

        get "/inspections/#{inspection.id}.pdf"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/pdf")

        inspection.reload
        expect(inspection.pdf_last_accessed_at).to be_present
      end
    end

    describe "POST /create" do
      context "when user has no inspection company" do
        before { login_as(user_without_company) }

        it "redirects appropriately" do
          post "/inspections", params: {inspection: valid_inspection_attributes}
          expect_redirect_with_alert(root_path)
        end

        it "redirects to unit when unit_id provided" do
          post "/inspections", params: {inspection: valid_inspection_attributes, unit_id: unit.id}
          expect_redirect_with_alert(unit_path(unit.id))
        end
      end

      context "when user cannot create inspections" do
        let(:user_at_limit) do
          user = create(:user)
          user.update!(inspection_limit: 0)
          user
        end

        before { login_as(user_at_limit) }

        it "redirects with alert when limit is 0" do
          post "/inspections", params: {inspection: valid_inspection_attributes}
          expect_redirect_with_alert(root_path)
        end
      end

      context "with valid user" do
        it "creates inspection successfully" do
          post "/inspections", params: {inspection: valid_inspection_attributes.merge(unit_id: unit.id)}
          expect_success_with_notice

          inspection = user.inspections.last
          expect(inspection.unit).to eq(unit)
          expect(inspection.user).to eq(user)
        end

        it "handles invalid unit_id" do
          post "/inspections", params: {inspection: valid_inspection_attributes, unit_id: "invalid"}
          expect_redirect_with_alert(root_path, /invalid.*unit/i)
        end

        it "handles save failure" do
          mock_failing_save
          post "/inspections", params: {inspection: valid_inspection_attributes}
          expect_redirect_with_alert(root_path, /failed/i)
        end

        it "sends notification in production" do
          allow(Rails.env).to receive(:production?).and_return(true)
          allow(NtfyService).to receive(:notify)

          post "/inspections", params: {inspection: valid_inspection_attributes, unit_id: unit.id}
          expect(NtfyService).to have_received(:notify).with(/new inspection/)
        end
      end
    end

    describe "PATCH /update" do
      let(:inspection) { create(:inspection, user: user, unit: unit) }
      let(:complete_inspection) { create(:inspection, :completed, user: user, unit: unit) }

      it "updates successfully" do
        patch "/inspections/#{inspection.id}", params: {inspection: {comments: "Updated"}}
        expect_success_with_notice

        inspection.reload
        expect(inspection.comments).to eq("Updated")
      end

      it "prevents editing complete inspections" do
        patch "/inspections/#{complete_inspection.id}", params: {inspection: {comments: "hack"}}
        expect(response).to redirect_to(inspection_path(complete_inspection))
        expect(flash[:notice]).to be_present
      end

      it "handles invalid unit_id" do
        other_unit = create(:unit, user: other_user)
        patch "/inspections/#{inspection.id}", params: {inspection: {unit_id: other_unit.id}}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to match(/invalid.*unit/i)
      end

      %w[json turbo_stream].each do |format|
        context "#{format} format" do
          let(:headers) do
            case format
            when "json" then {"Accept" => "application/json"}
            when "turbo_stream" then {"Accept" => "text/vnd.turbo-stream.html"}
            end
          end

          it "returns success response" do
            patch "/inspections/#{inspection.id}",
              params: {inspection: {comments: "test"}},
              headers: headers

            expect(response).to have_http_status(:success)
            expect(response.content_type).to include((format == "json") ? "json" : "turbo-stream")
          end

          it "returns error response when update fails" do
            test_inspection = create(:inspection, user: user, unit: unit)
            mock_failing_update

            patch "/inspections/#{test_inspection.id}",
              params: {inspection: {comments: "test"}},
              headers: headers

            expect(response).to have_http_status(:success)

            if format == "json"
              json = JSON.parse(response.body)
              expect(json["status"]).to eq("error")
            else
              expect(response.body).to include("<turbo-stream")
            end
          end
        end
      end
    end

    describe "DELETE /destroy" do
      it "deletes draft inspection" do
        inspection = create(:inspection, user: user, unit: unit, complete_date: nil)

        delete "/inspections/#{inspection.id}"
        expect_success_with_notice
        expect(Inspection.exists?(inspection.id)).to be false
      end

      it "prevents deletion of complete inspections" do
        inspection = create(:inspection, :completed, user: user, unit: unit)

        delete "/inspections/#{inspection.id}"
        expect(response).to redirect_to(inspection_path(inspection))
        expect(flash[:alert]).to be_present
        expect(Inspection.exists?(inspection.id)).to be true
      end
    end

    describe "unit management" do
      let(:inspection) { create(:inspection, user: user, unit: nil) }
      let!(:unit1) { create(:unit, user: user, name: "Unit One", manufacturer: "Acme") }
      let!(:unit2) { create(:unit, user: user, name: "Unit Two", manufacturer: "Beta") }

      describe "GET /select_unit" do
        it "shows all units" do
          get "/inspections/#{inspection.id}/select_unit"
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Unit One", "Unit Two")
        end

        it "filters by search" do
          get "/inspections/#{inspection.id}/select_unit", params: {search: "One"}
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Unit One")
          expect(response.body).not_to include("Unit Two")
        end
      end

      describe "PATCH /update_unit" do
        it "updates unit successfully" do
          patch "/inspections/#{inspection.id}/update_unit", params: {unit_id: unit1.id}
          expect(response).to redirect_to(edit_inspection_path(inspection))
          expect(flash[:notice]).to include(unit1.name)

          inspection.reload
          expect(inspection.unit).to eq(unit1)
        end

        it "handles invalid unit_id" do
          patch "/inspections/#{inspection.id}/update_unit", params: {unit_id: "invalid"}
          expect_redirect_with_alert(select_unit_inspection_path(inspection), /invalid.*unit/i)
        end
      end

      describe "PATCH /replace_dimensions" do
        let(:inspection_with_unit) { create(:inspection, user: user, unit: unit1) }

        it "replaces dimensions from unit" do
          patch "/inspections/#{inspection_with_unit.id}/replace_dimensions"
          expect(response).to redirect_to(edit_inspection_path(inspection_with_unit, tab: "general"))
          expect(flash[:notice]).to be_present
        end

        it "handles inspection without unit" do
          patch "/inspections/#{inspection.id}/replace_dimensions"
          expect(response).to redirect_to(edit_inspection_path(inspection, tab: "general"))
          expect(flash[:alert]).to be_present
        end
      end
    end

    describe "inspection status management" do
      let(:inspection) { create(:inspection, user: user, unit: unit) }

      describe "PATCH /complete" do
        it "completes inspection successfully" do
          allow_any_instance_of(Inspection).to receive(:validate_completeness).and_return([])
          allow_any_instance_of(Inspection).to receive(:complete!)

          patch "/inspections/#{inspection.id}/complete"
          expect(response).to redirect_to(inspection_path(inspection))
          expect(flash[:notice]).to be_present
        end

        it "handles validation errors" do
          allow_any_instance_of(Inspection).to receive(:validate_completeness).and_return(["Missing data"])

          patch "/inspections/#{inspection.id}/complete"
          expect_redirect_with_alert(edit_inspection_path(inspection), /Missing data/)
        end

        it "handles completion errors" do
          allow_any_instance_of(Inspection).to receive(:validate_completeness).and_return([])
          allow_any_instance_of(Inspection).to receive(:complete!).and_raise("Error")

          patch "/inspections/#{inspection.id}/complete"
          expect_redirect_with_alert(edit_inspection_path(inspection), /Error/)
        end
      end

      describe "PATCH /mark_draft" do
        let(:complete_inspection) { create(:inspection, :completed, user: user, unit: unit) }

        it "marks as draft successfully" do
          patch "/inspections/#{complete_inspection.id}/mark_draft"
          expect(response).to redirect_to(edit_inspection_path(complete_inspection))
          expect(flash[:notice]).to be_present

          complete_inspection.reload
          expect(complete_inspection.complete_date).to be_nil
        end

        it "handles update failure" do
          test_inspection = create(:inspection, :completed, user: user, unit: unit)
          mock_failing_update

          patch "/inspections/#{test_inspection.id}/mark_draft"
          expect_redirect_with_alert(edit_inspection_path(test_inspection), /error/)
        end
      end
    end

    describe "error handling" do
      it "handles missing inspections" do
        get "/inspections/nonexistent"
        expect_redirect_with_alert(inspections_path, /not found/i)
      end

      it "handles case-insensitive lookup" do
        inspection = create(:inspection, user: user, unit: unit)
        get "/inspections/#{inspection.id.upcase}"
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "public routes (no authentication required)" do
    let(:inspection) { create(:inspection, user: user, unit: unit) }

    describe "GET /report" do
      it "serves PDF" do
        allow(PdfGeneratorService).to receive(:generate_inspection_report).and_return(double(render: "PDF"))

        get "/r/#{inspection.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/pdf")
      end

      it "serves JSON" do
        allow(JsonSerializerService).to receive(:serialize_inspection).and_return({id: inspection.id})

        get "/r/#{inspection.id}.json"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
      end

      it "returns 404 for missing inspection" do
        get "/r/nonexistent"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /qr_code" do
      it "serves QR code" do
        allow(QrCodeService).to receive(:generate_qr_code).and_return("QR PNG")

        get "/inspections/#{inspection.id}/qr_code"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("image/png")
        expect(response.body).to eq("QR PNG")
      end

      it "returns 404 for missing inspection" do
        get "/inspections/nonexistent/qr_code"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
