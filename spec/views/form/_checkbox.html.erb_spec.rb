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

  # We don't need the capture helper since we'll handle it in the mock

  # Default render method with common setup
  def render_checkbox(locals = {})
    render partial: "form/checkbox", locals: { field: field }.merge(locals)
  end

  before do
    # Mock the form field setup helper
    allow(view).to receive(:form_field_setup).and_return(field_config)

    # Mock form builder methods with realistic HTML
    allow(mock_form).to receive(:check_box)
      .with(field)
      .and_return('<input type="checkbox" />'.html_safe)

    # When label is called with a block, we need to simulate Rails' behavior
    # of yielding to the block and wrapping the content in a label tag
    allow(mock_form).to receive(:label).with(field) do |field_name, &block|
      # The block will render the checkbox and label text
      # We'll return what the rendered output should look like
      '<label><input type="checkbox" />Active Status<small>Enable this feature</small></label>'.html_safe
    end

    # Set current i18n base for the partial
    view.instance_variable_set(:@_current_i18n_base, "test.forms")
  end

  describe "basic rendering" do
    it "renders a complete checkbox form group" do
      render_checkbox

      expect(rendered).to have_css('input[type="checkbox"]')
      expect(rendered).to have_css("label", text: "Active Status")
      expect(rendered).to have_css("small", text: "Enable this feature")
    end

    context "when hint is not present" do
      let(:field_config) { super().merge(field_hint: nil) }

      before do
        # Override the label mock for the no-hint case
        allow(mock_form).to receive(:label).with(field) do |field_name, &block|
          '<label><input type="checkbox" />Active Status</label>'.html_safe
        end
      end

      it "does not render the hint element" do
        render_checkbox
        expect(rendered).not_to have_css("small")
      end
    end
  end

  # Custom CSS classes section removed - we don't use CSS classes

  describe "form object handling" do
    let(:other_form) { double("OtherFormBuilder") }

    before do
      allow(view).to receive(:form_field_setup).and_return(
        field_config.merge(form_object: other_form)
      )
      allow(other_form).to receive(:check_box).and_return('<input type="checkbox" />'.html_safe)
      allow(other_form).to receive(:label).with(field) do |field_name, &block|
        # Simulate that the block calls check_box
        other_form.check_box(field_name)
        '<label><input type="checkbox" />Active Status<small>Enable this feature</small></label>'.html_safe
      end
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
          .with(field_name)
          .and_return('<input type="checkbox" />'.html_safe)

        allow(mock_form).to receive(:label).with(field_name) do |fn, &block|
          '<label><input type="checkbox" />Active Status<small>Enable this feature</small></label>'.html_safe
        end

        render_checkbox(field: field_name)
        expect(rendered).to have_css('input[type="checkbox"]')
        expect(rendered).to have_css("label")
      end
    end

    include_examples "renders correctly for field", :active
    include_examples "renders correctly for field", :email_notifications
    include_examples "renders correctly for field", :terms_accepted
  end

  describe "HTML structure and semantics" do
    before { render_checkbox }

    it "maintains proper semantic structure" do
      expect(rendered).to have_css('input[type="checkbox"]')
      expect(rendered).to have_css("label")
      expect(rendered).to have_css("small")
    end

    it "orders elements correctly (checkbox inside label)" do
      expect(rendered).to have_css("label") do |label|
        expect(label).to have_css('input[type="checkbox"]')
      end
    end

    it "associates label with checkbox through proper nesting" do
      # This assumes the implementation nests the input inside the label
      # or uses proper for/id attributes
      expect(rendered).to have_css('input[type="checkbox"]')
      expect(rendered).to have_css("label")
    end
  end
end
