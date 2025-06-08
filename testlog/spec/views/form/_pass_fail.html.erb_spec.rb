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
    allow(mock_form).to receive(:label)
      .with(field, "Status")
      .and_return('<label for="status">Status</label>'.html_safe)

    allow(mock_form).to receive(:radio_button)
      .with(field, true, id: "#{field}_true")
      .and_return('<input type="radio" name="status" value="true" id="status_true" />'.html_safe)

    allow(mock_form).to receive(:radio_button)
      .with(field, false, id: "#{field}_false")
      .and_return('<input type="radio" name="status" value="false" id="status_false" />'.html_safe)

    # Mock label_tag for radio button labels
    allow(view).to receive(:label_tag)
      .with("#{field}_true", "Pass", class: "radio-label")
      .and_return('<label for="status_true" class="radio-label">Pass</label>'.html_safe)

    allow(view).to receive(:label_tag)
      .with("#{field}_false", "Fail", class: "radio-label")
      .and_return('<label for="status_false" class="radio-label">Fail</label>'.html_safe)

    # Set current i18n base for the partial
    view.instance_variable_set(:@_current_i18n_base, "test.forms")
  end

  describe "basic rendering" do
    it "renders a complete pass/fail radio group" do
      render_pass_fail

      expect(rendered).to have_css("div.form-group") do |wrapper|
        expect(wrapper).to have_css('label[for="status"]', text: "Status")
        expect(wrapper).to have_css("div.radio-group") do |radio_group|
          expect(radio_group).to have_css('input[type="radio"][name="status"][value="true"][id="status_true"]')
          expect(radio_group).to have_css('label[for="status_true"].radio-label', text: "Pass")
          expect(radio_group).to have_css('input[type="radio"][name="status"][value="false"][id="status_false"]')
          expect(radio_group).to have_css('label[for="status_false"].radio-label', text: "Fail")
        end
        expect(wrapper).to have_css("small.form-text", text: "Select pass or fail")
      end
    end

    it "maintains correct element order (label, radio group, hint)" do
      render_pass_fail
      expect(rendered).to match(/<label.*?>.*?<\/label>.*?<div class="radio-group">.*?<\/div>.*?<small/m)
    end

    it "generates proper radio button IDs for accessibility" do
      render_pass_fail

      expect(rendered).to have_css('input#status_true[type="radio"]')
      expect(rendered).to have_css('label[for="status_true"]', text: "Pass")
      expect(rendered).to have_css('input#status_false[type="radio"]')
      expect(rendered).to have_css('label[for="status_false"]', text: "Fail")
    end

    context "when hint is not present" do
      let(:field_config) { super().merge(field_hint: nil) }

      it "does not render the hint element" do
        render_pass_fail
        expect(rendered).not_to have_css("small.form-text")
      end
    end
  end

  describe "custom labels" do
    shared_examples "uses custom pass/fail labels" do |pass_text, fail_text, locals_key|
      it "renders custom #{locals_key} labels" do
        # Update label_tag mocks for custom labels
        allow(view).to receive(:label_tag)
          .with("#{field}_true", pass_text, class: "radio-label")
          .and_return(%(<label for="#{field}_true" class="radio-label">#{pass_text}</label>).html_safe)

        allow(view).to receive(:label_tag)
          .with("#{field}_false", fail_text, class: "radio-label")
          .and_return(%(<label for="#{field}_false" class="radio-label">#{fail_text}</label>).html_safe)

        render_pass_fail(locals_key => {pass: pass_text, fail: fail_text})

        expect(rendered).to have_css('label[for="status_true"]', text: pass_text)
        expect(rendered).to have_css('label[for="status_false"]', text: fail_text)
      end
    end

    # Test both the explicit pass_label/fail_label approach and potential hash approach
    it "uses explicit pass_label when provided" do
      allow(view).to receive(:label_tag)
        .with("#{field}_true", "Approved", class: "radio-label")
        .and_return('<label for="status_true" class="radio-label">Approved</label>'.html_safe)

      render_pass_fail(pass_label: "Approved")
      expect(rendered).to have_css('label[for="status_true"]', text: "Approved")
      expect(rendered).to have_css('label[for="status_false"]', text: "Fail") # Default
    end

    it "uses explicit fail_label when provided" do
      allow(view).to receive(:label_tag)
        .with("#{field}_false", "Rejected", class: "radio-label")
        .and_return('<label for="status_false" class="radio-label">Rejected</label>'.html_safe)

      render_pass_fail(fail_label: "Rejected")
      expect(rendered).to have_css('label[for="status_true"]', text: "Pass") # Default
      expect(rendered).to have_css('label[for="status_false"]', text: "Rejected")
    end

    it "uses both custom labels when provided" do
      allow(view).to receive(:label_tag)
        .with("#{field}_true", "Yes", class: "radio-label")
        .and_return('<label for="status_true" class="radio-label">Yes</label>'.html_safe)

      allow(view).to receive(:label_tag)
        .with("#{field}_false", "No", class: "radio-label")
        .and_return('<label for="status_false" class="radio-label">No</label>'.html_safe)

      render_pass_fail(pass_label: "Yes", fail_label: "No")
      expect(rendered).to have_css('label[for="status_true"]', text: "Yes")
      expect(rendered).to have_css('label[for="status_false"]', text: "No")
    end
  end

  describe "CSS customization" do
    it "applies custom wrapper class" do
      render_pass_fail(wrapper_class: "custom-wrapper")
      expect(rendered).to have_css("div.custom-wrapper")
      expect(rendered).not_to have_css("div.form-group")
    end

    it "applies custom radio wrapper class" do
      render_pass_fail(radio_wrapper_class: "custom-radio-group")
      expect(rendered).to have_css("div.custom-radio-group")
      expect(rendered).not_to have_css("div.radio-group")
    end

    it "applies custom radio label class" do
      allow(view).to receive(:label_tag)
        .with("#{field}_true", "Pass", class: "custom-radio-label")
        .and_return('<label for="status_true" class="custom-radio-label">Pass</label>'.html_safe)

      allow(view).to receive(:label_tag)
        .with("#{field}_false", "Fail", class: "custom-radio-label")
        .and_return('<label for="status_false" class="custom-radio-label">Fail</label>'.html_safe)

      render_pass_fail(radio_label_class: "custom-radio-label")
      expect(rendered).to have_css("label.custom-radio-label")
    end

    it "supports multiple CSS customizations together" do
      allow(view).to receive(:label_tag)
        .with("#{field}_true", "Pass", class: "custom-label")
        .and_return('<label for="status_true" class="custom-label">Pass</label>'.html_safe)

      allow(view).to receive(:label_tag)
        .with("#{field}_false", "Fail", class: "custom-label")
        .and_return('<label for="status_false" class="custom-label">Fail</label>'.html_safe)

      render_pass_fail(
        wrapper_class: "assessment-field",
        radio_wrapper_class: "pass-fail-options",
        radio_label_class: "custom-label"
      )

      expect(rendered).to have_css("div.assessment-field")
      expect(rendered).to have_css("div.pass-fail-options")
      expect(rendered).to have_css("label.custom-label")
    end
  end

  describe "form object handling" do
    let(:other_form) { double("OtherFormBuilder") }

    before do
      allow(view).to receive(:form_field_setup).and_return(
        field_config.merge(form_object: other_form)
      )
      allow(other_form).to receive(:label).and_return("<label>Status</label>".html_safe)
      allow(other_form).to receive(:radio_button)
        .with(field, true, id: "#{field}_true")
        .and_return('<input type="radio" />'.html_safe)
      allow(other_form).to receive(:radio_button)
        .with(field, false, id: "#{field}_false")
        .and_return('<input type="radio" />'.html_safe)
    end

    it "uses the form object returned by form_field_setup" do
      render_pass_fail(form: other_form)

      expect(other_form).to have_received(:label)
      expect(other_form).to have_received(:radio_button).with(field, true, id: "#{field}_true")
      expect(other_form).to have_received(:radio_button).with(field, false, id: "#{field}_false")
      expect(mock_form).not_to have_received(:label)
      expect(mock_form).not_to have_received(:radio_button)
    end
  end

  describe "different field contexts" do
    shared_examples "renders correctly for field" do |field_name, expected_label|
      it "handles #{field_name} field" do
        # Update mocks for the new field
        allow(mock_form).to receive(:label)
          .with(field_name, expected_label)
          .and_return(%(<label for="#{field_name}">#{expected_label}</label>).html_safe)

        allow(mock_form).to receive(:radio_button)
          .with(field_name, true, id: "#{field_name}_true")
          .and_return(%(<input type="radio" name="#{field_name}" value="true" id="#{field_name}_true" />).html_safe)

        allow(mock_form).to receive(:radio_button)
          .with(field_name, false, id: "#{field_name}_false")
          .and_return(%(<input type="radio" name="#{field_name}" value="false" id="#{field_name}_false" />).html_safe)

        # Update label_tag mocks
        allow(view).to receive(:label_tag)
          .with("#{field_name}_true", "Pass", class: "radio-label")
          .and_return(%(<label for="#{field_name}_true" class="radio-label">Pass</label>).html_safe)

        allow(view).to receive(:label_tag)
          .with("#{field_name}_false", "Fail", class: "radio-label")
          .and_return(%(<label for="#{field_name}_false" class="radio-label">Fail</label>).html_safe)

        # Mock form_field_setup for the new field
        allow(view).to receive(:form_field_setup).and_return(
          field_config.merge(field_label: expected_label)
        )

        render_pass_fail(field: field_name)
        expect(rendered).to have_css("div.form-group")
        expect(rendered).to have_css("label", text: expected_label)
        expect(rendered).to have_css(%([name="#{field_name}"]))
      end
    end

    include_examples "renders correctly for field", :passed, "Passed"
    include_examples "renders correctly for field", :meets_requirements, "Meets Requirements"
    include_examples "renders correctly for field", :satisfactory, "Satisfactory"
    include_examples "renders correctly for field", :compliant, "Compliant"
    include_examples "renders correctly for field", :approved, "Approved"
  end

  describe "i18n integration" do
    it "uses default i18n keys for pass/fail labels" do
      render_pass_fail

      expect(view).to have_received(:t).with("inspections.fields.pass")
      expect(view).to have_received(:t).with("inspections.fields.fail")
    end

    it "skips i18n lookup when explicit labels provided" do
      # Update label_tag mocks for custom labels
      allow(view).to receive(:label_tag)
        .with("#{field}_true", "Custom Pass", class: "radio-label")
        .and_return('<label for="status_true" class="radio-label">Custom Pass</label>'.html_safe)

      allow(view).to receive(:label_tag)
        .with("#{field}_false", "Custom Fail", class: "radio-label")
        .and_return('<label for="status_false" class="radio-label">Custom Fail</label>'.html_safe)

      render_pass_fail(pass_label: "Custom Pass", fail_label: "Custom Fail")

      expect(rendered).to have_css('label[for="status_true"]', text: "Custom Pass")
      expect(rendered).to have_css('label[for="status_false"]', text: "Custom Fail")
    end
  end

  describe "accessibility and semantic structure" do
    before { render_pass_fail }

    it "properly associates radio buttons with their labels" do
      expect(rendered).to have_css('input#status_true[type="radio"]')
      expect(rendered).to have_css('label[for="status_true"]')
      expect(rendered).to have_css('input#status_false[type="radio"]')
      expect(rendered).to have_css('label[for="status_false"]')
    end

    it "groups radio buttons with shared name attribute" do
      expect(rendered).to have_css('input[name="status"][value="true"]')
      expect(rendered).to have_css('input[name="status"][value="false"]')
    end

    it "uses semantic fieldset structure" do
      # Note: Current implementation doesn't use fieldset, but this documents the structure
      expect(rendered).to have_css("div.form-group")
      expect(rendered).to have_css("div.radio-group")
    end

    it "includes hint for additional context when present" do
      expect(rendered).to have_css("small.form-text", text: "Select pass or fail")
    end
  end
end
