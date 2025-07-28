require "rails_helper"

RSpec.describe "chobble_forms/_file_field.html.erb", type: :view do
  let(:form_builder) { double("form_builder") }
  let(:mock_object) { double("model") }
  let(:field) { :photo }
  let(:i18n_base) { "units.forms" }

  before do
    allow(form_builder).to receive(:object).and_return(mock_object)
    allow(form_builder).to receive(:label).and_return("Photo")
    allow(form_builder).to receive(:file_field).and_return('<input type="file" name="photo">'.html_safe)

    # Set the required instance variables for form_field_setup
    view.instance_variable_set(:@_current_form, form_builder)
    view.instance_variable_set(:@_current_i18n_base, i18n_base)

    # Mock the i18n translation
    allow(view).to receive(:t).with("#{i18n_base}.fields.#{field}", raise: true).and_return("Photo")
    allow(view).to receive(:t).with(anything, default: nil).and_return(nil)
  end

  context "when no file is attached" do
    before do
      attachment = double("attachment")
      allow(attachment).to receive(:attached?).and_return(false)
      allow(mock_object).to receive(:respond_to?).with(:photo).and_return(true)
      allow(mock_object).to receive(:photo).and_return(attachment)
    end

    it "renders the file field without preview" do
      render "chobble_forms/file_field", field: field

      expect(rendered).to include("Photo")
      expect(rendered).to include('<input type="file" name="photo">')
      expect(rendered).not_to include("file-preview")
    end

    it "uses custom accept attribute" do
      render "chobble_forms/file_field", field: field, accept: "application/pdf"

      expect(form_builder).to have_received(:file_field).with(field, accept: "application/pdf")
    end
  end

  context "when file is attached" do
    let(:attachment) { double("attachment") }
    let(:blob) { double("blob") }
    let(:service) { double("service") }

    before do
      allow(attachment).to receive(:attached?).and_return(true)
      allow(attachment).to receive(:blob).and_return(blob)
      allow(attachment).to receive(:variant).and_return("variant_image")
      allow(attachment).to receive(:filename).and_return("test.jpg")
      allow(blob).to receive(:persisted?).and_return(true)
      allow(blob).to receive(:analyzed?).and_return(true)
      allow(blob).to receive(:analyze)
      allow(blob).to receive(:metadata).and_return({"width" => 100, "height" => 100})
      allow(blob).to receive(:service).and_return(service)
      allow(blob).to receive(:key).and_return("test_key")
      allow(service).to receive(:exist?).and_return(true)
      allow(mock_object).to receive(:respond_to?).with(:photo).and_return(true)
      allow(mock_object).to receive(:photo).and_return(attachment)
    end

    context "with image file and preview enabled" do
      before do
        allow(attachment).to receive(:image?).and_return(true)
        allow(ImageProcessorService).to receive(:thumbnail).and_return("processed_image_url")
      end

      it "renders file field with image preview" do
        allow(view).to receive(:image_tag).and_return('<img src="test.jpg">'.html_safe)

        render "chobble_forms/file_field", field: field

        expect(rendered).to include("file-preview")
        expect(rendered).to include('<img src="test.jpg">')
        expect(rendered).to include("Current photo")
      end

      it "uses custom preview size" do
        allow(view).to receive(:image_tag).and_return('<img src="test.jpg" style="max-width: 150px; height: auto;">'.html_safe)

        render "chobble_forms/file_field", field: field, preview_size: 150

        expect(attachment).to have_received(:variant).with(resize_to_limit: [150, 150])
        expect(rendered).to include('<img src="test.jpg"')
      end
    end

    context "with non-image file" do
      before do
        allow(attachment).to receive(:image?).and_return(false)
        allow(attachment).to receive(:filename).and_return("document.pdf")
      end

      it "shows filename for non-image file" do
        render "chobble_forms/file_field", field: field

        expect(rendered).not_to include("<img")
        expect(rendered).to include("document.pdf")
        expect(rendered).to include("Current photo")
      end
    end
  end

  context "when model does not respond to field" do
    before do
      allow(mock_object).to receive(:respond_to?).with(:photo).and_return(false)
    end

    it "renders without errors or preview" do
      render "chobble_forms/file_field", field: field

      expect(rendered).to include("Photo")
      expect(rendered).to include('<input type="file" name="photo">')
      expect(rendered).not_to include("file-preview")
    end
  end

  context "with field hint" do
    before do
      allow(view).to receive(:form_field_setup).and_return({
        form_object: form_builder,
        field_label: "Photo",
        field_hint: "Upload an image file",
        field_placeholder: nil
      })

      attachment = double("attachment")
      allow(attachment).to receive(:attached?).and_return(false)
      allow(mock_object).to receive(:respond_to?).with(:photo).and_return(true)
      allow(mock_object).to receive(:photo).and_return(attachment)
    end

    it "displays the hint text" do
      render "chobble_forms/file_field", field: field

      expect(rendered).to include("Upload an image file")
      expect(rendered).to include("form-text")
    end
  end
end
