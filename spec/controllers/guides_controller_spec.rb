require "rails_helper"

RSpec.describe GuidesController, type: :controller do
  describe "GET #index" do
    it "calls collect_guides and assigns result to @guides" do
      # Test the controller logic directly
      controller = GuidesController.new
      test_guides = [{title: "Test Guide", path: "test"}]
      allow(controller).to receive(:collect_guides).and_return(test_guides)
      
      # Simulate what the index action does
      controller.index
      expect(controller.instance_variable_get(:@guides)).to eq(test_guides)
    end
  end
  
  describe "#collect_guides" do
    it "collects and sorts guides from metadata files" do
      controller = GuidesController.new
      
      # Mock file system
      allow(Dir).to receive(:glob).and_return([
        "/path/zebra_guide/metadata.json",
        "/path/alpha_guide/metadata.json"
      ])
      
      metadata = {
        "screenshots" => [{"filename" => "test.png", "caption" => "Test"}],
        "updated_at" => "2024-01-15T10:00:00Z"
      }
      allow(File).to receive(:read).and_return(metadata.to_json)
      
      # Mock Pathname operations - first path is zebra, second is alpha
      # But they should be sorted alphabetically after collection
      allow_any_instance_of(Pathname).to receive(:relative_path_from) do |path|
        if path.to_s.include?("zebra")
          instance_double(Pathname, dirname: instance_double(Pathname, to_s: "zebra_guide"))
        else
          instance_double(Pathname, dirname: instance_double(Pathname, to_s: "alpha_guide"))
        end
      end
      
      guides = controller.send(:collect_guides)
      expect(guides.length).to eq(2)
      # After sorting by title, alpha should come first
      expect(guides.first[:title]).to eq("Alpha guide")
      expect(guides.last[:title]).to eq("Zebra guide")
    end
    
    it "returns empty array when no guides exist" do
      controller = GuidesController.new
      allow(Dir).to receive(:glob).and_return([])
      
      guides = controller.send(:collect_guides)
      expect(guides).to eq([])
    end
  end
  
  describe "GET #show" do
    let(:guide_path) { "test_guide" }
    
    before do
      # Skip n_plus_one_detection and stub render/redirect to avoid template rendering issues
      allow(controller).to receive(:n_plus_one_detection).and_yield
      allow(controller).to receive(:render)
      allow(controller).to receive(:redirect_to)
    end
    
    context "when metadata file exists" do
      let(:metadata) do
        {
          "screenshots" => [{"filename" => "test.png", "caption" => "Test"}],
          "updated_at" => "2024-01-15T10:00:00Z"
        }
      end
      
      before do
        metadata_file = instance_double(Pathname)
        allow(metadata_file).to receive(:exist?).and_return(true)
        allow(metadata_file).to receive(:read).and_return(metadata.to_json)
        allow(Rails).to receive_message_chain(:public_path, :join).and_return(
          instance_double(Pathname, join: metadata_file)
        )
      end
      
      it "assigns guide data when metadata exists" do
        get :show, params: { path: guide_path }
        expect(assigns(:guide_data)).to eq(metadata)
      end
      
      it "assigns guide path" do
        get :show, params: { path: guide_path }
        expect(assigns(:guide_path)).to eq(guide_path)
      end
      
      it "assigns humanized guide title" do
        get :show, params: { path: guide_path }
        expect(assigns(:guide_title)).to eq("Test guide")
      end
    end
    
    context "when metadata file does not exist" do
      before do
        metadata_file = instance_double(Pathname)
        allow(metadata_file).to receive(:exist?).and_return(false)
        allow(Rails).to receive_message_chain(:public_path, :join).and_return(
          instance_double(Pathname, join: metadata_file)
        )
        # Don't stub redirect_to for these tests
        allow(controller).to receive(:render)
      end
      
      it "redirects to guides path when metadata doesn't exist" do
        allow(controller).to receive(:redirect_to).and_call_original
        get :show, params: { path: guide_path }
        expect(response).to redirect_to(guides_path)
      end
      
      it "sets flash alert when guide not found" do
        allow(controller).to receive(:redirect_to).and_call_original
        get :show, params: { path: guide_path }
        expect(flash[:alert]).to eq(I18n.t("guides.messages.not_found"))
      end
    end
  end
  
  describe "private methods" do
    describe "#guide_screenshots_root" do
      it "returns the correct path" do
        controller = GuidesController.new
        expected_path = Rails.public_path.join("guide_screenshots")
        expect(controller.send(:guide_screenshots_root)).to eq(expected_path)
      end
    end
    
    describe "#humanize_guide_title" do
      it "removes _spec suffix and humanizes" do
        controller = GuidesController.new
        expect(controller.send(:humanize_guide_title, "test_workflow_spec")).to eq("Test workflow")
      end
      
      it "handles nested paths" do
        controller = GuidesController.new
        expect(controller.send(:humanize_guide_title, "features/admin/user_management")).to eq("User management")
      end
    end
  end
end