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
      inspection_date: Time.zone.today,
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
    %w[index edit].each do |action|
      it "redirects to login for #{action}" do
        path = (action == "index") ?
          "/inspections" :
          "/inspections/#{SecureRandom.hex(6)}/edit"
        get path
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq(I18n.t("forms.session_new.status.login_required"))
      end
    end

    it "returns 404 for show when not logged in and inspection doesn't exist" do
      get "/inspections/nonexistent"
      expect(response).to have_http_status(:not_found)
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
        expect(flash[:alert]).to eq(I18n.t("forms.session_new.status.login_required"))
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
      expect(response.body).to include(user_inspection.id)
      expect(response.body).not_to include(other_inspection.id)
    end

    %w[edit update destroy].each do |action|
      it "prevents access to other user's inspection for #{action}" do
        case action
        when "edit"
          get "/inspections/#{other_inspection.id}/edit"
        when "update"
          patch "/inspections/#{other_inspection.id}", params: {inspection: {comments: "hack"}}
        when "destroy"
          delete "/inspections/#{other_inspection.id}"
        end

        expect(response).to have_http_status(:not_found)
      end
    end

    it "shows PDF viewer for other user's inspection show page" do
      get "/inspections/#{other_inspection.id}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("<iframe")
      expect(response.body).to include("/inspections/#{other_inspection.id}.pdf")
    end
  end

  describe "assessments disabled" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("HAS_ASSESSMENTS").and_return("false")
      login_as(user)
    end

    it "returns 404 when assessments are disabled" do
      get "/inspections"
      expect(response).to have_http_status(:not_found)
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
        create(:inspection, :completed, user: user, unit: unit, risk_assessment: "Test risk assessment")

        get "/inspections.csv"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/csv")
        expect(response.body).to include("Test risk assessment")
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

      it "inspection_path helper generates correct PDF URL" do
        # Verify that the Rails path helper generates the expected URL
        expect(inspection_path(inspection, format: :pdf)).to eq("/inspections/#{inspection.id}.pdf")
      end

      context "JSON format" do
        it "returns inspection data as JSON using InspectionBlueprint" do
          # Don't mock - let InspectionBlueprint actually render
          get "/inspections/#{inspection.id}.json"

          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("application/json")

          json = JSON.parse(response.body)
          # id is excluded from public API, check other fields
          expect(json["inspection_date"]).to be_present
          expect(json["complete"]).to be false
          expect(json["passed"]).to eq(inspection.passed)
        end
      end
    end

    describe "POST /create" do
      context "when user is inactive" do
        let(:inactive_user) { create(:user, active_until: Date.current - 1.day) }
        before do
          logout_user  # Ensure previous user is logged out
          login_as(inactive_user)
        end

        it "redirects appropriately" do
          # Verify the user is actually inactive
          expect(inactive_user.active_until).to eq(Date.current - 1.day)
          expect(inactive_user.is_active?).to be false
          expect(inactive_user.can_create_inspection?).to be false

          # This should be prevented by the before_action
          expect {
            post "/inspections", params: {inspection: valid_inspection_attributes}
          }.not_to change(Inspection, :count)

          # The inactive user should be redirected and prevented from creating
          expect_redirect_with_alert(inspections_path)
        end

        it "redirects to unit when unit_id provided and user owns it" do
          # Create unit owned by the inactive user
          inactive_unit = create(:unit, user: inactive_user)

          post "/inspections", params: {inspection: valid_inspection_attributes, unit_id: inactive_unit.id}
          expect_redirect_with_alert(unit_path(inactive_unit))
        end
      end

      context "when user cannot create inspections" do
        let(:user_at_limit) do
          user = create(:user, :inactive_user)
          user
        end

        before do
          logout_user  # Ensure previous user is logged out
          login_as(user_at_limit)
        end

        it "redirects with alert when user is inactive" do
          post "/inspections", params: {inspection: valid_inspection_attributes}
          expect_redirect_with_alert(inspections_path)
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
        patch "/inspections/#{inspection.id}", params: {inspection: {risk_assessment: "Updated assessment"}}
        expect_success_with_notice

        inspection.reload
        expect(inspection.risk_assessment).to eq("Updated assessment")
      end

      it "prevents editing complete inspections" do
        patch "/inspections/#{complete_inspection.id}", params: {inspection: {risk_assessment: "hack"}}
        expect(response).to redirect_to(inspection_path(complete_inspection))
        expect(flash[:notice]).to be_present
      end

      it "handles invalid unit_id" do
        other_unit = create(:unit, user: other_user)
        patch "/inspections/#{inspection.id}", params: {inspection: {unit_id: other_unit.id}}
        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to match(/invalid.*unit/i)
      end

      context "with image processing error" do
        before do
          # Simulate image processing error by stubbing process_image_params
          allow_any_instance_of(InspectionsController).to receive(:process_image_params) do |controller, params, *args|
            controller.instance_variable_set(:@image_processing_error, StandardError.new("Image processing failed"))
            params
          end
        end

        it "handles image processing errors gracefully" do
          patch "/inspections/#{inspection.id}", params: {
            inspection: {
              risk_assessment: "Test assessment",
              photo_1: fixture_file_upload("spec/fixtures/files/test_image.jpg", "image/jpeg")
            }
          }

          expect(response).to have_http_status(:unprocessable_content)
          expect(flash[:alert]).to eq("Image processing failed")
          expect(response).to render_template(:edit)
        end
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
              params: {inspection: {risk_assessment: "test assessment"}},
              headers: headers

            expect(response).to have_http_status(:success)
            expect(response.content_type).to include((format == "json") ?
              "json" :
              "turbo-stream")
          end

          it "returns error response when update fails" do
            test_inspection = create(:inspection, user: user, unit: unit)
            mock_failing_update

            patch "/inspections/#{test_inspection.id}",
              params: {inspection: {risk_assessment: "test assessment"}},
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

          # Verify event logging
          event = Event.for_resource(inspection).last
          expect(event.action).to eq("unit_changed")
          expect(event.details).to include(unit1.name)
        end

        it "handles invalid unit_id" do
          patch "/inspections/#{inspection.id}/update_unit", params: {unit_id: "invalid"}
          expect_redirect_with_alert(select_unit_inspection_path(inspection), /invalid.*unit/i)
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

        it "lets errors bubble up when completion fails" do
          allow_any_instance_of(Inspection).to receive(:validate_completeness).and_return([])
          allow_any_instance_of(Inspection).to receive(:complete!).and_raise(StandardError, "Unexpected error")

          expect {
            patch "/inspections/#{inspection.id}/complete"
          }.to raise_error(StandardError, "Unexpected error")
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
        expect(response).to have_http_status(:not_found)
      end

      it "handles case-insensitive lookup" do
        inspection = create(:inspection, user: user, unit: unit)
        get "/inspections/#{inspection.id.upcase}"
        expect(response).to have_http_status(:success)
      end
    end

    describe "HEAD requests" do
      let(:inspection) { create(:inspection, user: user, unit: unit) }

      it "returns 200 OK for HEAD request" do
        head "/inspections/#{inspection.id}"
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_empty
      end
    end

    describe "GET /log" do
      let(:inspection) { create(:inspection, user: user, unit: unit) }

      before do
        # Create some events for the inspection
        Event.log(
          user: user,
          action: "created",
          resource: inspection,
          details: "Inspection created"
        )
        Event.log(
          user: user,
          action: "updated",
          resource: inspection,
          details: "Inspection updated"
        )
      end

      it "displays inspection event log" do
        get "/inspections/#{inspection.id}/log"

        expect(response).to have_http_status(:success)
        expect(assigns(:events)).to be_present
        expect(assigns(:events).count).to eq(2)
        expect(assigns(:title)).to include(inspection.id)
      end
    end

    describe "prefill functionality" do
      let(:previous_inspection) do
        create(:inspection, :completed,
          user: user,
          unit: unit,
          risk_assessment: "Previous risk")
      end

      let(:new_inspection) do
        create(:inspection, user: user, unit: unit)
      end

      before do
        # Set up previous inspection on unit
        allow_any_instance_of(Unit).to receive(:last_inspection).and_return(previous_inspection)
      end

      describe "translate_field_name" do
        it "translates field names for prefill display" do
          get "/inspections/#{new_inspection.id}/edit", params: {tab: "inspection"}

          expect(response).to have_http_status(:success)
          # The prefilled_fields will be set if there are fields to prefill
          expect(assigns(:prefilled_fields)).to be_an(Array)
        end

        it "handles pass/fail field translation for assessments" do
          # Update previous inspection's assessment with data
          previous_inspection.user_height_assessment.update(
            containing_wall_height: 100,
            containing_wall_height_comment: "Test comment"
          )

          get "/inspections/#{new_inspection.id}/edit", params: {tab: "user_height"}

          expect(response).to have_http_status(:success)
          expect(assigns(:previous_inspection)).to eq(previous_inspection)
          # Prefilled fields would include the ground_clearance fields
          expect(assigns(:prefilled_fields)).to be_an(Array)
        end
      end

      describe "get_prefill_objects for results tab" do
        it "handles results tab prefill correctly" do
          previous_inspection.update(
            passed: true,
            risk_assessment: "Test risk"
          )

          get "/inspections/#{new_inspection.id}/edit", params: {tab: "results"}

          expect(assigns(:previous_inspection)).to eq(previous_inspection)
          # Results tab should only prefill specific fields
          expect(response).to have_http_status(:success)
        end
      end
    end

    describe "validate_tab_parameter" do
      let(:inspection) { create(:inspection, user: user, unit: unit) }

      it "redirects with invalid tab parameter" do
        get "/inspections/#{inspection.id}/edit", params: {tab: "invalid_tab"}

        expect(response).to redirect_to(edit_inspection_path(inspection))
        expect(flash[:alert]).to be_present
      end

      it "allows valid tab parameter" do
        get "/inspections/#{inspection.id}/edit", params: {tab: "user_height"}

        expect(response).to have_http_status(:success)
      end
    end

    describe "log_inspection_event error handling" do
      it "handles logging errors gracefully" do
        # Mock Event.log to raise an error
        allow(Event).to receive(:log).and_raise(StandardError, "Database error")
        allow(Rails.logger).to receive(:error)

        # This should not raise an error
        post "/inspections", params: {
          inspection: {unit_id: unit.id}
        }

        expect(Rails.logger).to have_received(:error).with(/Failed to log inspection event/)
        # Request should still succeed
        expect(response).to have_http_status(:redirect)
      end

      it "logs system events without specific inspection" do
        allow(Event).to receive(:log_system_event)

        # CSV export logs a system event
        get "/inspections.csv"

        expect(Event).to have_received(:log_system_event).with(
          hash_including(
            user: user,
            action: "exported",
            metadata: hash_including(resource_type: "Inspection")
          )
        )
      end
    end

    describe "calculate_changes" do
      let(:inspection) { create(:inspection, user: user, unit: unit) }

      it "tracks changes correctly in update" do
        # Store original values
        original_passed = inspection.passed
        inspection.risk_assessment

        patch "/inspections/#{inspection.id}", params: {
          inspection: {
            passed: !original_passed,
            risk_assessment: "New risk"
          }
        }

        expect(response).to redirect_to(inspection_path(inspection))

        # Check the event was logged with changed data
        event = Event.for_resource(inspection).last
        expect(event.action).to eq("updated")
        expect(event.changed_data).to be_present
        expect(event.changed_data["risk_assessment"]).to be_present
        expect(event.changed_data["risk_assessment"]["to"]).to eq("New risk")
      end

      it "ignores unchanged values" do
        inspection.risk_assessment

        patch "/inspections/#{inspection.id}", params: {
          inspection: {
            risk_assessment: "New risk",
            passed: inspection.passed  # Same value
          }
        }

        expect(response).to redirect_to(inspection_path(inspection))

        # Check that only changed fields are in changed_data
        event = Event.for_resource(inspection).last
        expect(event.action).to eq("updated")
        expect(event.changed_data.keys).to include("risk_assessment")
        expect(event.changed_data.keys).not_to include("passed")
      end
    end

    describe "validate_inspection_completability" do
      context "with invalid complete inspection" do
        let(:invalid_complete_inspection) do
          # Create an inspection marked as complete but with missing data
          inspection = create(:inspection, user: user, unit: unit)
          inspection.update_column(:complete_date, Time.current) # Bypass validations
          inspection
        end

        before do
          allow_any_instance_of(Inspection).to receive(:can_mark_complete?).and_return(false)
          allow_any_instance_of(Inspection).to receive(:completion_errors).and_return(
            ["Missing inspection date", "Unit not specified"]
          )
        end

        context "in development/test environment" do
          before { allow(Rails.env).to receive(:local?).and_return(true) }

          it "raises error for invalid completion state" do
            expect {
              get "/inspections/#{invalid_complete_inspection.id}"
            }.to raise_error(StandardError, /DATA INTEGRITY ERROR/)
          end
        end

        context "in production environment" do
          before do
            allow(Rails.env).to receive(:local?).and_return(false)
            allow(Rails.logger).to receive(:error)
          end

          it "logs error but continues" do
            get "/inspections/#{invalid_complete_inspection.id}"

            expect(Rails.logger).to have_received(:error).with(/DATA INTEGRITY ERROR/)
            expect(response).to have_http_status(:success)
          end
        end
      end
    end
  end

  describe "public routes (no authentication required)" do
    let(:inspection) { create(:inspection, user: user, unit: unit) }

    describe "show action with different formats" do
      it "serves PDF via .pdf format" do
        allow(PdfGeneratorService).to receive(:generate_inspection_report).and_return(double(render: "PDF"))

        get "/inspections/#{inspection.id}.pdf"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/pdf")
      end

      it "serves JSON via .json format" do
        get "/inspections/#{inspection.id}.json"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")

        json = JSON.parse(response.body)
        expect(json).to be_present
        expect(json).to have_key("complete")
        expect(json).to have_key("urls")
      end

      it "serves QR code via .png format" do
        allow(QrCodeService).to receive(:generate_qr_code).and_return("QR PNG")

        get "/inspections/#{inspection.id}.png"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("image/png")
        expect(response.body).to eq("QR PNG")
      end

      it "returns 404 for missing inspection" do
        get "/inspections/nonexistent.pdf"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "HTML access" do
      it "shows minimal PDF viewer" do
        get "/inspections/#{inspection.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
        expect(response.body).to include("<iframe")
      end

      it "handles case-insensitive IDs" do
        get "/inspections/#{inspection.id.upcase}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
        expect(response.body).to include("<iframe")
      end
    end
  end
end
