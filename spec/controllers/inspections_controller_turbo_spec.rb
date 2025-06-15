require "rails_helper"

RSpec.describe InspectionsController, type: :controller do
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user: user) }

  before do
    # Simulate logged in user for controller specs
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:logged_in?).and_return(true)
  end

  describe "PATCH #update with Turbo Stream format" do
    context "turbo stream response format" do
      before do
        request.headers["Accept"] = "text/vnd.turbo-stream.html"
      end

      it "renders turbo stream response without calling undefined methods" do
        # This test ensures we don't call methods like content_tag that aren't available
        expect {
          patch :update, params: {id: inspection.id, inspection: {comments: "Test"}}
        }.not_to raise_error
      end

      it "uses helpers to access helper methods" do
        # Verify that the controller still has access to helpers
        expect(controller.helpers).to respond_to(:inspection_tabs)

        patch :update, params: {id: inspection.id, inspection: {comments: "Test"}}

        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "renders proper turbo stream elements" do
        patch :update, params: {id: inspection.id, inspection: {comments: "Updated"}}

        expect(response.body).to include("<turbo-stream")
        expect(response.body).to include("action=\"replace\"")
        expect(response.body).to include("target=\"inspection_progress_#{inspection.id}\"")
      end

      it "handles validation errors gracefully" do
        # Force a validation error by making the inspection invalid
        inspection.update!(complete_date: nil)

        # Try to clear a required field
        patch :update, params: {id: inspection.id, inspection: {inspection_location: ""}}

        expect(response.content_type).to include("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end
    end

    context "helper method availability" do
      it "doesn't have direct access to view helper methods" do
        # This documents that controllers don't have direct access to methods like content_tag
        expect(controller).not_to respond_to(:content_tag)
        expect(controller).not_to respond_to(:turbo_frame_tag)
      end

      it "accesses helper methods through helpers proxy" do
        expect(controller.helpers).to respond_to(:inspection_tabs)
      end
    end
  end

  describe "Turbo Stream rendering patterns" do
    before do
      request.headers["Accept"] = "text/vnd.turbo-stream.html"
    end

    it "uses html: parameter for inline HTML" do
      patch :update, params: {id: inspection.id, inspection: {comments: "Test"}}

      # Should use html: parameter, not blocks (HTML is escaped in template)
      expect(response.body).to match(/(&lt;span class=&#39;value&#39;&gt;|<span class='value'>)/)
      expect(response.body).to match(/(In Progress|Complete)/)
    end

    it "uses partial: parameter for rendering partials" do
      # Keep inspection as draft so we can update it
      patch :update, params: {id: inspection.id, inspection: {comments: "Test"}}

      # Should render the mark complete section partial
      expect(response.body).to include("mark_complete_section_#{inspection.id}")
    end
  end

  describe "Multiple format support" do
    it "responds to HTML format" do
      patch :update, params: {id: inspection.id, inspection: {comments: "HTML update"}}

      expect(response).to redirect_to(inspection_path(inspection))
    end

    it "responds to JSON format" do
      request.headers["Accept"] = "application/json"

      patch :update, params: {id: inspection.id, inspection: {comments: "JSON update"}}

      expect(response.content_type).to include("application/json")
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("success")
    end

    it "responds to Turbo Stream format" do
      request.headers["Accept"] = "text/vnd.turbo-stream.html"

      patch :update, params: {id: inspection.id, inspection: {comments: "Turbo update"}}

      expect(response.content_type).to include("text/vnd.turbo-stream.html")
    end
  end
end
