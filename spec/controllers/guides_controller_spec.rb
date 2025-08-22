require "rails_helper"

RSpec.describe GuidesController, type: :controller do
  describe "GET #index" do
    before do
      # Mock the response to avoid template rendering
      allow(controller).to receive(:respond_to) do |&block|
        mock_responder = double("responder")
        allow(mock_responder).to receive(:html)
        block.call(mock_responder) if block
      end
    end
    
    it "assigns guides to @guides" do
      # Mock the file system
      allow(Dir).to receive(:glob).and_return([])
      
      get :index
      expect(assigns(:guides)).to eq([])
    end
    
    it "collects guides from metadata files" do
      metadata_path = "/public/guide_screenshots/test_guide/metadata.json"
      metadata = {
        "screenshots" => [{"filename" => "test.png", "caption" => "Test"}],
        "updated_at" => "2024-01-15T10:00:00Z"
      }
      
      allow(Dir).to receive(:glob).and_return([metadata_path])
      allow(File).to receive(:read).with(metadata_path).and_return(metadata.to_json)
      allow_any_instance_of(Pathname).to receive(:relative_path_from).and_return(
        instance_double(Pathname, dirname: instance_double(Pathname, to_s: "test_guide"))
      )
      
      get :index
      guides = assigns(:guides)
      expect(guides.length).to eq(1)
      expect(guides.first[:title]).to eq("Test guide")
    end
    
    it "sorts guides by title" do
      metadata1 = {
        "screenshots" => [{"filename" => "test.png", "caption" => "Test"}],
        "updated_at" => "2024-01-15T10:00:00Z"
      }
      metadata2 = metadata1.dup
      
      allow(Dir).to receive(:glob).and_return([
        "/public/guide_screenshots/zebra_guide/metadata.json",
        "/public/guide_screenshots/alpha_guide/metadata.json"
      ])
      allow(File).to receive(:read).and_return(metadata1.to_json)
      
      # First call returns zebra_guide, second returns alpha_guide
      zebra_path = instance_double(Pathname, dirname: instance_double(Pathname, to_s: "zebra_guide"))
      alpha_path = instance_double(Pathname, dirname: instance_double(Pathname, to_s: "alpha_guide"))
      allow_any_instance_of(Pathname).to receive(:relative_path_from).and_return(zebra_path, alpha_path)
      
      get :index
      guides = assigns(:guides)
      expect(guides.length).to eq(2)
      expect(guides.first[:title]).to eq("Alpha guide")
      expect(guides.last[:title]).to eq("Zebra guide")
    end
  end
  
  describe "GET #show" do
    let(:guide_path) { "test_guide" }
    
    before do
      # Mock the response to avoid template rendering
      allow(controller).to receive(:respond_to) do |&block|
        mock_responder = double("responder")
        allow(mock_responder).to receive(:html)
        block.call(mock_responder) if block
      end
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
      end
      
      it "redirects to guides path when metadata doesn't exist" do
        get :show, params: { path: guide_path }
        expect(response).to redirect_to(guides_path)
      end
      
      it "sets flash alert when guide not found" do
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