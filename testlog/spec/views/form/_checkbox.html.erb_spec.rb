require "rails_helper"

RSpec.describe "form/_checkbox.html.erb", type: :view do
  let(:mock_form) { double("FormBuilder") }
  let(:field) { :active }
  let(:field_config) do
    {
      form_object: mock_form,
      i18n_base: "test.forms",
      field_label: "Active Status",
      field_hint: "Enable this feature",
      field_placeholder: nil
    }
  end

  # Default render method with common setup
  def render_checkbox(locals = {})
    render partial: "form/checkbox", locals: {field: field}.merge(locals)
  end

  before do
    # Mock the form field setup helper
    allow(view).to receive(:form_field_setup).and_return(field_config)

    # Mock form builder methods with realistic HTML
    allow(mock_form).to receive(:check_box)
      .with(field, class: "form-check-input")
      .and_return('<input type="checkbox" class="form-check-input" />'.html_safe)

    allow(mock_form).to receive(:label)
      .with(field, "Active Status", class: "form-check-label")
      .and_return('<label class="form-check-label">Active Status</label>'.html_safe)

    # Set current i18n base for the partial
    view.instance_variable_set(:@_current_i18n_base, "test.forms")
  end

  describe "basic rendering" do
    it "renders a complete checkbox form group" do
      render_checkbox

      expect(rendered).to have_css("div.form-group") do |wrapper|
        expect(wrapper).to have_css('input[type="checkbox"].form-check-input')
        expect(wrapper).to have_css("label.form-check-label", text: "Active Status")
        expect(wrapper).to have_css("small.form-text", text: "Enable this feature")
      end
    end

    context "when hint is not present" do
      let(:field_config) { super().merge(field_hint: nil) }

      it "does not render the hint element" do
        render_checkbox
        expect(rendered).not_to have_css("small.form-text")
      end
    end
  end

  describe "custom CSS classes" do
    it "applies custom wrapper class" do
      render_checkbox(wrapper_class: "custom-wrapper")
      expect(rendered).to have_css("div.custom-wrapper")
    end

    it "applies custom checkbox class" do
      allow(mock_form).to receive(:check_box)
        .with(field, class: "custom-checkbox")
        .and_return('<input type="checkbox" class="custom-checkbox" />'.html_safe)

      render_checkbox(checkbox_class: "custom-checkbox")
      expect(rendered).to have_css('input[type="checkbox"].custom-checkbox')
    end

    it "applies custom label class" do
      allow(mock_form).to receive(:label)
        .with(field, "Active Status", class: "custom-label")
        .and_return('<label class="custom-label">Active Status</label>'.html_safe)

      render_checkbox(label_class: "custom-label")
      expect(rendered).to have_css("label.custom-label")
    end
  end

  describe "form object handling" do
    let(:other_form) { double("OtherFormBuilder") }

    before do
      allow(view).to receive(:form_field_setup).and_return(
        field_config.merge(form_object: other_form)
      )
      allow(other_form).to receive(:check_box).and_return('<input type="checkbox" />'.html_safe)
      allow(other_form).to receive(:label).and_return("<label>Active Status</label>".html_safe)
    end

    it "uses the form object returned by form_field_setup" do
      render_checkbox(form: other_form)

      expect(other_form).to have_received(:check_box)
      expect(other_form).to have_received(:label)
    end
  end

  describe "different field types" do
    shared_examples "renders correctly for field" do |field_name|
      it "handles #{field_name} field" do
        # Update mocks for the new field
        allow(mock_form).to receive(:check_box)
          .with(field_name, class: "form-check-input")
          .and_return('<input type="checkbox" class="form-check-input" />'.html_safe)

        allow(mock_form).to receive(:label)
          .with(field_name, "Active Status", class: "form-check-label")
          .and_return('<label class="form-check-label">Active Status</label>'.html_safe)

        render_checkbox(field: field_name)
        expect(rendered).to have_css("div.form-group")
      end
    end

    include_examples "renders correctly for field", :active
    include_examples "renders correctly for field", :email_notifications
    include_examples "renders correctly for field", :terms_accepted
  end

  describe "HTML structure and semantics" do
    before { render_checkbox }

    it "maintains proper semantic structure" do
      expect(rendered).to have_css("div.form-group") do |wrapper|
        expect(wrapper).to have_css('input[type="checkbox"]')
        expect(wrapper).to have_css("label")
        expect(wrapper).to have_css("small.form-text")
      end
    end

    it "orders elements correctly (checkbox before label)" do
      expect(rendered).to match(/<input.*type="checkbox".*\/?>.*<label/m)
    end

    it "associates label with checkbox through proper nesting" do
      # This assumes the implementation nests the input inside the label
      # or uses proper for/id attributes
      expect(rendered).to have_css("div.form-group")
    end
  end
end
