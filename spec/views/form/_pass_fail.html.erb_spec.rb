require "rails_helper"

RSpec.describe "form/_pass_fail.html.erb", type: :view do
  let(:mock_form) { double("FormBuilder") }
  let(:field) { :status }
  let(:field_config) do
    {
      form_object: mock_form,
      i18n_base: "test.forms",
      field_label: "Status",
      field_hint: "Select pass or fail",
      field_placeholder: nil
    }
  end

  # Default render method with common setup
  def render_pass_fail(locals = {})
    render partial: "form/pass_fail", locals: {field: field}.merge(locals)
  end

  before do
    # Mock the form field setup helper
    allow(view).to receive(:form_field_setup).and_return(field_config)

    # Mock i18n translations for pass/fail labels
    allow(view).to receive(:t)
      .with("inspections.fields.pass")
      .and_return("Pass")
    allow(view).to receive(:t)
      .with("inspections.fields.fail")
      .and_return("Fail")

    # Mock form builder methods with default behavior
    allow(mock_form).to receive(:radio_button)
      .with(field, true, id: "#{field}_true")
      .and_return('<input type="radio" name="status" value="true" id="status_true" />'.html_safe)

    allow(mock_form).to receive(:radio_button)
      .with(field, false, id: "#{field}_false")
      .and_return('<input type="radio" name="status" value="false" id="status_false" />'.html_safe)

    # Set current i18n base for the partial
    view.instance_variable_set(:@_current_i18n_base, "test.forms")
  end

  describe "basic rendering" do
    it "renders a complete pass/fail radio group" do
      render_pass_fail

      expect(rendered).to have_css("div")
      expect(rendered).to have_css("label", text: "Status")
      expect(rendered).to have_css('input[type="radio"][name="status"][value="true"][id="status_true"]')
      expect(rendered).to have_css('input[type="radio"][name="status"][value="false"][id="status_false"]')
      expect(rendered).to have_css("label", text: "Pass")
      expect(rendered).to have_css("label", text: "Fail")
      expect(rendered).to have_css("small", text: "Select pass or fail")
    end

    it "nests radio buttons inside their labels" do
      render_pass_fail
      # Check that radio buttons are inside labels
      expect(rendered).to have_css("label", text: "Pass") do |label|
        expect(label).to have_css('input[type="radio"][value="true"]')
      end
      expect(rendered).to have_css("label", text: "Fail") do |label|
        expect(label).to have_css('input[type="radio"][value="false"]')
      end
    end

    it "generates proper radio button IDs for accessibility" do
      render_pass_fail

      expect(rendered).to have_css('input#status_true[type="radio"]')
      expect(rendered).to have_css('input#status_false[type="radio"]')
    end

    context "when hint is not present" do
      let(:field_config) { super().merge(field_hint: nil) }

      it "does not render the hint element" do
        render_pass_fail
        expect(rendered).not_to have_css("small")
      end
    end
  end

  describe "form object handling" do
    let(:other_form) { double("OtherFormBuilder") }

    before do
      allow(view).to receive(:form_field_setup).and_return(
        field_config.merge(form_object: other_form)
      )
      allow(other_form).to receive(:radio_button)
        .with(field, true, id: "#{field}_true")
        .and_return('<input type="radio" />'.html_safe)
      allow(other_form).to receive(:radio_button)
        .with(field, false, id: "#{field}_false")
        .and_return('<input type="radio" />'.html_safe)
    end

    it "uses the form object returned by form_field_setup" do
      render_pass_fail(form: other_form)

      expect(other_form).to have_received(:radio_button).at_least(:once)
    end
  end

  describe "different field contexts" do
    shared_examples "renders correctly for field" do |field_name|
      it "handles #{field_name} field" do
        # Mock for the new field
        allow(mock_form).to receive(:radio_button)
          .with(field_name, true, id: "#{field_name}_true")
          .and_return('<input type="radio" />'.html_safe)
        allow(mock_form).to receive(:radio_button)
          .with(field_name, false, id: "#{field_name}_false")
          .and_return('<input type="radio" />'.html_safe)

        render_pass_fail(field: field_name)
        expect(rendered).to have_css("div")
        expect(rendered).to have_css("label", text: "Status")
      end
    end

    include_examples "renders correctly for field", :passed
    include_examples "renders correctly for field", :meets_requirements
    include_examples "renders correctly for field", :satisfactory
    include_examples "renders correctly for field", :compliant
    include_examples "renders correctly for field", :approved
  end

  describe "i18n integration" do
    it "uses i18n for default pass/fail labels" do
      expect(view).to receive(:t).with("inspections.fields.pass").and_return("Pass")
      expect(view).to receive(:t).with("inspections.fields.fail").and_return("Fail")

      render_pass_fail
    end
  end

  describe "accessibility and semantic structure" do
    it "properly associates radio buttons with their labels through nesting" do
      render_pass_fail

      # Labels contain the radio buttons
      expect(rendered).to have_css("label", text: "Pass") do |label|
        expect(label).to have_css('input[type="radio"][value="true"]')
      end
      expect(rendered).to have_css("label", text: "Fail") do |label|
        expect(label).to have_css('input[type="radio"][value="false"]')
      end
    end

    it "uses boolean values for pass/fail" do
      render_pass_fail
      expect(rendered).to have_css('input[type="radio"][value="true"]')
      expect(rendered).to have_css('input[type="radio"][value="false"]')
    end

    it "includes hint for additional context when present" do
      render_pass_fail
      expect(rendered).to have_css("small", text: field_config[:field_hint])
    end
  end
end
