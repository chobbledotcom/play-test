require "rails_helper"

RSpec.describe "InspectionsController Coverage", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before { login_as(user) }

  describe "GET /show" do
    context "HEAD request" do
      it "returns 200 OK for HEAD request" do
        head "/inspections/#{inspection.id}"
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_empty
      end
    end

    context "JSON format" do
      it "returns inspection data as JSON using InspectionBlueprint" do
        get "/inspections/#{inspection.id}.json"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")

        json = JSON.parse(response.body)
        expect(json["id"]).to eq(inspection.id)
      end
    end
  end

  describe "PATCH /update" do
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
  end

  describe "PATCH /update_unit" do
    let(:inspection_without_unit) { create(:inspection, user: user, unit: nil) }
    let(:new_unit) { create(:unit, user: user, name: "New Test Unit") }

    context "successful unit update" do
      it "updates unit and redirects with success message" do
        patch "/inspections/#{inspection_without_unit.id}/update_unit",
          params: {unit_id: new_unit.id}

        expect(response).to redirect_to(edit_inspection_path(inspection_without_unit))
        expect(flash[:notice]).to include("New Test Unit")

        inspection_without_unit.reload
        expect(inspection_without_unit.unit).to eq(new_unit)

        # Verify event logging
        event = Event.for_resource(inspection_without_unit).last
        expect(event.action).to eq("unit_changed")
        expect(event.details).to include("New Test Unit")
      end
    end

    context "failed unit update" do
      it "handles update failure and redirects with error" do
        inspection_for_failure = create(:inspection, user: user, unit: nil)
        
        # Mock validation failure for this specific test
        allow_any_instance_of(Inspection).to receive(:save).and_return(false)
        errors_double = double(full_messages: ["Unit cannot be assigned", "Validation failed"], clear: nil)
        allow_any_instance_of(Inspection).to receive(:errors).and_return(errors_double)

        patch "/inspections/#{inspection_for_failure.id}/update_unit",
          params: {unit_id: new_unit.id}

        expect(response).to redirect_to(select_unit_inspection_path(inspection_for_failure))
        expect(flash[:alert]).to include("Unit cannot be assigned, Validation failed")
      end
    end
  end

  describe "GET /log" do
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

  describe "assessments disabled" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("HAS_ASSESSMENTS").and_return("false")
    end

    it "returns 404 when assessments are disabled" do
      get "/inspections"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "assessment params handling" do
    context "with assessment attributes" do
      it "permits assessment attributes" do
        # Test with user_height_assessment attributes
        assessment_params = {
          inspection: {
            risk_assessment: "Test",
            user_height_assessment_attributes: {
              ground_clearance: "100",
              ground_clearance_pass: "true",
              ground_clearance_comment: "Good clearance"
            }
          }
        }

        patch "/inspections/#{inspection.id}", params: assessment_params

        expect(response).to redirect_to(inspection_path(inspection))

        inspection.reload
        user_height = inspection.user_height_assessment
        expect(user_height.ground_clearance).to eq(100)
        expect(user_height.ground_clearance_pass).to be true
        expect(user_height.ground_clearance_comment).to eq("Good clearance")
      end

      it "filters out system attributes from assessment params" do
        # Try to inject system attributes - they should be filtered
        assessment_params = {
          inspection: {
            risk_assessment: "Test",
            materials_assessment_attributes: {
              fabric_pass: "true",
              inspection_id: "999999",  # Should be filtered
              created_at: "2020-01-01", # Should be filtered
              updated_at: "2020-01-01"  # Should be filtered
            }
          }
        }

        patch "/inspections/#{inspection.id}", params: assessment_params

        expect(response).to redirect_to(inspection_path(inspection))

        inspection.reload
        materials = inspection.materials_assessment
        # inspection_id should not have been changed
        expect(materials.inspection_id).to eq(inspection.id)
      end
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
        before { allow(Rails.env).to receive(:local?).and_return(false) }

        it "logs error but continues" do
          expect(Rails.logger).to receive(:error).with(/DATA INTEGRITY ERROR/)

          get "/inspections/#{invalid_complete_inspection.id}"

          expect(response).to have_http_status(:success)
        end
      end
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
      it "translates field names with comment suffix" do
        get "/inspections/#{new_inspection.id}/edit", params: {tab: "inspection"}

        # This triggers the prefill logic which uses translate_field_name
        expect(assigns(:prefilled_fields)).to be_present
      end

      it "handles pass/fail field translation" do
        # Create previous inspection with pass/fail data
        previous_inspection.user_height_assessment.update(
          ground_clearance_pass: true
        )

        get "/inspections/#{new_inspection.id}/edit", params: {tab: "user_height"}

        # Verify the prefill logic ran
        expect(assigns(:previous_inspection)).to eq(previous_inspection)
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
    it "tracks changes correctly in update" do
      allow(Event).to receive(:log)

      patch "/inspections/#{inspection.id}", params: {
        inspection: {
          passed: true,
          risk_assessment: "New risk"
        }
      }

      expect(Event).to have_received(:log).with(
        hash_including(
          action: "updated",
          changed_data: hash_including(
            "passed" => hash_including("to" => true),
            "risk_assessment" => hash_including("to" => "New risk")
          )
        )
      )
    end

    it "ignores unchanged values" do
      original_value = inspection.risk_assessment
      allow(Event).to receive(:log)

      patch "/inspections/#{inspection.id}", params: {
        inspection: {
          risk_assessment: "New risk",  # Changed value
          passed: inspection.passed  # Same value
        }
      }

      expect(Event).to have_received(:log).with(
        hash_including(
          action: "updated",
          changed_data: hash_including("risk_assessment")
        )
      )

      # Should not include passed in changed_data (since it didn't change)
      expect(Event).to have_received(:log) do |args|
        expect(args[:changed_data].keys).not_to include("passed")
      end
    end
  end

  describe "validate_tab_parameter" do
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

  describe "inactive user handling" do
    let(:inactive_user) { create(:user, active_until: Date.current - 1.day) }

    before do
      logout_user
      login_as(inactive_user)
    end

    describe "handle_inactive_user_redirect" do
      it "redirects to inspections path when no unit_id" do
        post "/inspections", params: {inspection: {risk_assessment: "test"}}

        expect(response).to redirect_to(inspections_path)
      end

      it "redirects to unit path when unit_id belongs to user" do
        inactive_unit = create(:unit, user: inactive_user)

        post "/inspections", params: {unit_id: inactive_unit.id}

        expect(response).to redirect_to(unit_path(inactive_unit))
      end

      it "redirects to inspections path when unit_id doesn't belong to user" do
        other_unit = create(:unit, user: user)

        post "/inspections", params: {unit_id: other_unit.id}

        expect(response).to redirect_to(inspections_path)
      end

      it "redirects to inspection path for edit/update actions" do
        inactive_inspection = create(:inspection, user: inactive_user, unit: create(:unit, user: inactive_user))

        get "/inspections/#{inactive_inspection.id}/edit"

        expect(response).to redirect_to(inspection_path(inactive_inspection))
      end
    end
  end
end
