require "rails_helper"

class TextFieldTestModel
  include ActiveModel::Model
  attr_accessor :name, :email, :website, :phone, :age, :password,
    :search_term, :birth_date, :appointment_time, :meeting_datetime,
    :favorite_color, :document

  def persisted? = false
end

RSpec.describe "form/_text_field.html.erb", type: :view do
  let(:test_model) { TextFieldTestModel.new }
  let(:field) { :name }

  before do
    view.form_with(model: test_model, url: "/", local: true) do |f|
      @_current_form = f
      ""
    end
    @_current_i18n_base = "test.forms"

    I18n.backend.store_translations(:en, {
      test: {
        forms: {
          fields: {
            name: "Name",
            email: "Email",
            website: "Website",
            phone: "Phone",
            age: "Age",
            password: "Password",
            search_term: "Search",
            birth_date: "Birth Date",
            appointment_time: "Appointment Time",
            meeting_datetime: "Meeting Date/Time",
            favorite_color: "Favorite Color",
            document: "Document"
          }
        }
      }
    })
  end

  def render_text_field(locals = {})
    render partial: "form/text_field", locals: {field:}.merge(locals)
  end

  describe "basic rendering" do
    it "renders a label and text field" do
      render_text_field

      expect(rendered).to have_css('label[id="name"]')
      input_selector = 'label input[type="text"][name="text_field_test_model[name]"]'
      expect(rendered).to have_css(input_selector)
    end

    it "maintains correct element order" do
      render_text_field
      expect(rendered).to have_css('label input[type="text"]')
    end
  end

  describe "field type variations" do
    shared_examples "renders correct field type" do |field_type, input_type, field_name|
      it "renders #{field_type} as #{input_type} input" do
        locals = {field: field_name, type: field_type}
        render partial: "form/text_field", locals: locals
        expect(rendered).to have_css(%(label input[type="#{input_type}"]))
      end
    end

    include_examples "renders correct field type", :email_field, "email", :email
    include_examples "renders correct field type", :url_field, "url", :website
    include_examples "renders correct field type", :telephone_field, "tel", :phone
    include_examples "renders correct field type", :number_field, "number", :age
    include_examples "renders correct field type", :password_field, "password", :password
    include_examples "renders correct field type", :search_field, "search", :search_term
    include_examples "renders correct field type", :date_field, "date", :birth_date
    include_examples "renders correct field type", :time_field, "time", :appointment_time
    datetime_examples = ["datetime-local", :meeting_datetime]
    include_examples "renders correct field type", :datetime_field, *datetime_examples
    include_examples "renders correct field type", :color_field, "color", :favorite_color
    include_examples "renders correct field type", :file_field, "file", :document
  end

  describe "field attributes" do
    context "when required" do
      it "adds required attribute" do
        render_text_field(required: true)
        expect(rendered).to have_css('label input[required="required"]')
      end
    end

    context "with placeholder" do
      it "does not pass placeholder to field" do
        render_text_field
        expect(rendered).not_to include("placeholder=")
      end
    end

    context "with accept attribute" do
      it "adds accept attribute to file input" do
        locals = {field: :document, type: :file_field, accept: "image/*"}
        render partial: "form/text_field", locals: locals
        expect(rendered).to have_css('label input[type="file"][accept="image/*"]')
      end
    end

    context "with additional HTML attributes" do
      it "form_field_setup raises error for data parameter" do
        expect {
          render_text_field(data: {validate: "presence"})
        }.to raise_error(ActionView::Template::Error, /local_assigns contains \[:data\]/)
      end

      it "form_field_setup raises error for class parameter" do
        expect {
          render_text_field(class: "form-control custom-input")
        }.to raise_error(ActionView::Template::Error, /local_assigns contains \[:class\]/)
      end
    end
  end

  describe "form object handling" do
    it "uses the form object from @_current_form" do
      render_text_field
      expected_name = 'input[name="text_field_test_model[name]"]'
      expect(rendered).to have_css(expected_name)
    end
  end

  describe "error handling" do
    context "when field has errors" do
      it "does not handle error classes" do
        render_text_field
        expect(rendered).not_to include("field-with-errors")
      end
    end
  end

  describe "help text" do
    it "form_field_setup raises error for help_text parameter" do
      expect {
        render_text_field(help_text: "Enter your full name")
      }.to raise_error(ActionView::Template::Error, /local_assigns contains \[:help_text\]/)
    end

    it "does not render help text element when not provided" do
      render_text_field
      expect(rendered).not_to have_css("small.help-text")
    end
  end
end
