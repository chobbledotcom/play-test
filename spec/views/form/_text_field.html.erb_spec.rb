require "rails_helper"

RSpec.describe "form/_text_field.html.erb", type: :view do
  let(:mock_form) { double("FormBuilder") }
  let(:field) { :name }
  let(:field_config) do
    {
      form_object: mock_form,
      i18n_base: "test.forms",
      field_label: "Name",
      field_hint: nil,
      field_placeholder: "Enter name"
    }
  end

  def render_text_field(locals = {})
    render partial: "form/text_field", locals: {field: field}.merge(locals)
  end

  before do
    allow(view).to receive(:form_field_setup).and_return(field_config)

    allow(mock_form).to receive(:label)
      .with(anything, anything)
      .and_return('<label for="name">Name</label>'.html_safe)

    allow(mock_form).to receive(:text_field)
      .with(anything, anything)
      .and_return('<input type="text" name="name" id="name" />'.html_safe)

    view.instance_variable_set(:@_current_i18n_base, "test.forms")
  end

  describe "basic rendering" do
    it "renders a label and text field" do
      render_text_field

      expect(rendered).to have_css('label[for="name"]', text: "Name")
      expect(rendered).to have_css('input[type="text"][name="name"][id="name"]')
    end

    it "maintains correct element order (label before input)" do
      render_text_field
      expect(rendered).to match(/<label.*?>.*?<\/label>.*?<input/m)
    end
  end

  describe "field type variations" do
    shared_examples "renders correct field type" do |field_type, input_type|
      it "renders #{field_type} as #{input_type} input" do
        # Mock the specific field type method
        allow(mock_form).to receive(field_type)
          .with(field, anything)
          .and_return(%(<input type="#{input_type}" name="#{field}" id="#{field}" />).html_safe)

        render_text_field(type: field_type)
        expect(rendered).to have_css(%(input[type="#{input_type}"]))
      end
    end

    include_examples "renders correct field type", :email_field, "email"
    include_examples "renders correct field type", :url_field, "url"
    include_examples "renders correct field type", :tel_field, "tel"
    include_examples "renders correct field type", :number_field, "number"
    include_examples "renders correct field type", :password_field, "password"
    include_examples "renders correct field type", :search_field, "search"
    include_examples "renders correct field type", :date_field, "date"
    include_examples "renders correct field type", :time_field, "time"
    include_examples "renders correct field type", :datetime_field, "datetime-local"
    include_examples "renders correct field type", :color_field, "color"
    include_examples "renders correct field type", :file_field, "file"
  end

  describe "field attributes" do
    context "when required" do
      it "adds required attribute" do
        allow(mock_form).to receive(:text_field)
          .with(field, hash_including(required: true))
          .and_return('<input type="text" required="required" />'.html_safe)

        render_text_field(required: true)
        expect(rendered).to have_css('input[required="required"]')
      end
    end

    context "with placeholder" do
      it "does not pass placeholder to field (text_field partial doesn't support it)" do
        render_text_field
        expect(rendered).not_to include("placeholder=")
      end
    end

    context "with accept attribute (for file fields)" do
      it "adds accept attribute to file input" do
        allow(mock_form).to receive(:file_field)
          .with(field, hash_including(accept: "image/*"))
          .and_return('<input type="file" accept="image/*" />'.html_safe)

        render_text_field(type: :file_field, accept: "image/*")
        expect(rendered).to have_css('input[type="file"][accept="image/*"]')
      end
    end

    context "with additional HTML attributes" do
      it "does not pass through data attributes (not supported by partial)" do
        render_text_field(data: {validate: "presence"})
        expect(rendered).not_to include("data-validate")
      end

      it "does not pass through class attribute (not supported by partial)" do
        render_text_field(class: "form-control custom-input")
        expect(rendered).not_to include('class="form-control')
      end
    end
  end

  describe "form object handling" do
    let(:other_form) { double("OtherFormBuilder") }

    before do
      allow(view).to receive(:form_field_setup).and_return(
        field_config.merge(form_object: other_form)
      )
      allow(other_form).to receive(:label).and_return("<label>Name</label>".html_safe)
      allow(other_form).to receive(:text_field).and_return('<input type="text" />'.html_safe)
    end

    it "uses the form object returned by form_field_setup" do
      render_text_field(form: other_form)

      expect(other_form).to have_received(:label)
      expect(other_form).to have_received(:text_field)
      expect(mock_form).not_to have_received(:label)
      expect(mock_form).not_to have_received(:text_field)
    end
  end

  describe "error handling" do
    context "when field has errors" do
      it "does not handle error classes (not supported by partial)" do
        render_text_field
        expect(rendered).not_to include("field-with-errors")
      end
    end
  end
end
