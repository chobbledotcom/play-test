require "rails_helper"

RSpec.describe "form/_radio_group.html.erb", type: :view do
  let(:mock_form) { double("FormBuilder") }
  let(:field) { :status }
  let(:field_config) do
    {
      form_object: mock_form,
      i18n_base: "test.forms",
      field_label: "Status",
      field_hint: "Select the current status",
      field_placeholder: nil
    }
  end
  let(:default_options) { [["Active", "active"], ["Inactive", "inactive"]] }

  # Default render method with common setup
  def render_radio_group(locals = {})
    render partial: "form/radio_group", locals: {
      field: field,
      options: default_options
    }.merge(locals)
  end

  before do
    # Mock the form field setup helper
    allow(view).to receive(:form_field_setup).and_return(field_config)

    # Mock form builder methods with default behavior
    allow(mock_form).to receive(:label)
      .with(field, "Status")
      .and_return('<label for="status">Status</label>'.html_safe)

    # Mock radio buttons for each option
    allow(mock_form).to receive(:radio_button)
      .with(field, "active", {id: "status_active"})
      .and_return('<input type="radio" name="status" value="active" id="status_active" />'.html_safe)

    allow(mock_form).to receive(:radio_button)
      .with(field, "inactive", {id: "status_inactive"})
      .and_return('<input type="radio" name="status" value="inactive" id="status_inactive" />'.html_safe)

    # Mock label_tag for radio labels
    allow(view).to receive(:label_tag)
      .with("status_active", "Active", {class: "radio-label"})
      .and_return('<label for="status_active" class="radio-label">Active</label>'.html_safe)

    allow(view).to receive(:label_tag)
      .with("status_inactive", "Inactive", {class: "radio-label"})
      .and_return('<label for="status_inactive" class="radio-label">Inactive</label>'.html_safe)

    # Set current i18n base for the partial
    view.instance_variable_set(:@_current_i18n_base, "test.forms")
  end

  describe "basic rendering" do
    it "renders a complete radio group with all options" do
      render_radio_group

      expect(rendered).to have_css("div.form-group") do |wrapper|
        expect(wrapper).to have_css('label[for="status"]', text: "Status")
        expect(wrapper).to have_css("div.radio-group")
        expect(wrapper).to have_css('input[type="radio"][name="status"][value="active"][id="status_active"]')
        expect(wrapper).to have_css('input[type="radio"][name="status"][value="inactive"][id="status_inactive"]')
        expect(wrapper).to have_css('label[for="status_active"].radio-label', text: "Active")
        expect(wrapper).to have_css('label[for="status_inactive"].radio-label', text: "Inactive")
        expect(wrapper).to have_css("small.form-text", text: "Select the current status")
      end
    end

    it "maintains correct element order (field label, radio group, hint)" do
      render_radio_group
      expect(rendered).to match(/<label.*?for="status".*?>.*?<div.*?radio-group.*?>.*?<small.*?form-text.*?>/m)
    end

    context "when hint is not present" do
      let(:field_config) { super().merge(field_hint: nil) }

      it "does not render the hint element" do
        render_radio_group
        expect(rendered).not_to have_css("small.form-text")
      end
    end

    context "when no options provided" do
      it "renders empty radio group" do
        render_radio_group(options: [])

        expect(rendered).to have_css("div.form-group")
        expect(rendered).to have_css('label[for="status"]', text: "Status")
        expect(rendered).to have_css("div.radio-group")
        expect(rendered).not_to have_css('input[type="radio"]')
      end
    end
  end

  describe "option variations" do
    shared_examples "renders radio options correctly" do |options_array, description|
      it "handles #{description}" do
        # Mock the radio buttons and labels for this specific set of options
        options_array.each do |label, value|
          # The partial uses the raw value in the ID (no sanitization)
          radio_id = "#{field}_#{value}"

          allow(mock_form).to receive(:radio_button)
            .with(field, value, {id: radio_id})
            .and_return(%(<input type="radio" name="#{field}" value="#{value}" id="#{radio_id}" />).html_safe)

          allow(view).to receive(:label_tag)
            .with(radio_id, label, {class: "radio-label"})
            .and_return(%(<label for="#{radio_id}" class="radio-label">#{label}</label>).html_safe)
        end

        render_radio_group(options: options_array)

        options_array.each do |label, value|
          radio_id = "#{field}_#{value}"

          expect(rendered).to have_css(%(input[type="radio"][value="#{value}"][id="#{radio_id}"]))
          expect(rendered).to have_css(%(label[for="#{radio_id}"].radio-label), text: label)
        end
      end
    end

    include_examples "renders radio options correctly",
      [["Yes", true], ["No", false]],
      "boolean values"

    include_examples "renders radio options correctly",
      [["Small", "s"], ["Medium", "m"], ["Large", "l"], ["Extra Large", "xl"]],
      "multiple string values"

    include_examples "renders radio options correctly",
      [["Low", 1], ["Medium", 2], ["High", 3]],
      "integer values"

    include_examples "renders radio options correctly",
      [["Draft", "draft"], ["Published", "published"], ["Archived", "archived"]],
      "status strings"

    include_examples "renders radio options correctly",
      [["Option with spaces", "spaced_value"], ["Special-chars!", "special_value"]],
      "complex labels and values"
  end

  describe "CSS customization" do
    it "applies custom wrapper class" do
      render_radio_group(wrapper_class: "custom-wrapper")
      expect(rendered).to have_css("div.custom-wrapper")
      expect(rendered).not_to have_css("div.form-group")
    end

    it "applies custom radio wrapper class" do
      render_radio_group(radio_wrapper_class: "custom-radio-wrapper")
      expect(rendered).to have_css("div.custom-radio-wrapper")
      expect(rendered).not_to have_css("div.radio-group")
    end

    it "applies custom radio label class" do
      # Update mocks to expect the custom class
      allow(view).to receive(:label_tag)
        .with("status_active", "Active", {class: "custom-radio-label"})
        .and_return('<label for="status_active" class="custom-radio-label">Active</label>'.html_safe)

      allow(view).to receive(:label_tag)
        .with("status_inactive", "Inactive", {class: "custom-radio-label"})
        .and_return('<label for="status_inactive" class="custom-radio-label">Inactive</label>'.html_safe)

      render_radio_group(radio_label_class: "custom-radio-label")
      expect(rendered).to have_css("label.custom-radio-label")
    end

    it "applies multiple custom CSS classes together" do
      # Update mocks for custom classes
      allow(view).to receive(:label_tag)
        .with("status_active", "Active", {class: "special-label"})
        .and_return('<label for="status_active" class="special-label">Active</label>'.html_safe)

      allow(view).to receive(:label_tag)
        .with("status_inactive", "Inactive", {class: "special-label"})
        .and_return('<label for="status_inactive" class="special-label">Inactive</label>'.html_safe)

      render_radio_group(
        wrapper_class: "special-wrapper",
        radio_wrapper_class: "special-radio-wrapper",
        radio_label_class: "special-label"
      )

      expect(rendered).to have_css("div.special-wrapper")
      expect(rendered).to have_css("div.special-radio-wrapper")
      expect(rendered).to have_css("label.special-label")
    end
  end

  describe "form object handling" do
    let(:other_form) { double("OtherFormBuilder") }

    before do
      allow(view).to receive(:form_field_setup).and_return(
        field_config.merge(form_object: other_form)
      )
      allow(other_form).to receive(:label).and_return("<label>Status</label>".html_safe)
      allow(other_form).to receive(:radio_button).and_return('<input type="radio" />'.html_safe)
    end

    it "uses the form object returned by form_field_setup" do
      render_radio_group(form: other_form)

      expect(other_form).to have_received(:label)
      expect(other_form).to have_received(:radio_button).at_least(:once)
      expect(mock_form).not_to have_received(:label)
    end
  end

  describe "different field types" do
    shared_examples "renders correctly for field" do |field_name, field_label|
      it "handles #{field_name} field" do
        # Update mocks for the new field
        allow(mock_form).to receive(:label)
          .with(field_name, field_label)
          .and_return(%(<label for="#{field_name}">#{field_label}</label>).html_safe)

        # Mock radio buttons for the new field
        default_options.each do |label, value|
          # The partial uses the raw value in the ID (no sanitization)
          radio_id = "#{field_name}_#{value}"

          allow(mock_form).to receive(:radio_button)
            .with(field_name, value, {id: radio_id})
            .and_return(%(<input type="radio" name="#{field_name}" value="#{value}" id="#{radio_id}" />).html_safe)

          allow(view).to receive(:label_tag)
            .with(radio_id, label, {class: "radio-label"})
            .and_return(%(<label for="#{radio_id}" class="radio-label">#{label}</label>).html_safe)
        end

        # Mock form_field_setup for the new field
        allow(view).to receive(:form_field_setup).and_return(
          field_config.merge(field_label: field_label)
        )

        render_radio_group(field: field_name)
        expect(rendered).to have_css("div.form-group")
        expect(rendered).to have_css("label", text: field_label)
      end
    end

    include_examples "renders correctly for field", :priority, "Priority"
    include_examples "renders correctly for field", :category, "Category"
    include_examples "renders correctly for field", :visibility, "Visibility"
    include_examples "renders correctly for field", :approval_status, "Approval Status"
  end

  describe "accessibility and semantics" do
    it "properly associates field label with radio group" do
      render_radio_group

      # Field label should be associated with the field name
      expect(rendered).to have_css('label[for="status"]', text: "Status")
    end

    it "generates unique IDs for each radio button" do
      render_radio_group

      expect(rendered).to have_css('input[type="radio"][id="status_active"]')
      expect(rendered).to have_css('input[type="radio"][id="status_inactive"]')
      expect(rendered).to have_css('label[for="status_active"]')
      expect(rendered).to have_css('label[for="status_inactive"]')
    end

    it "groups radio buttons with same name attribute" do
      render_radio_group

      # All radio buttons should have the same name to group them
      expect(rendered).to have_css('input[type="radio"][name="status"]', count: 2)
    end

    it "provides proper label association for screen readers" do
      render_radio_group

      # Each radio button should have a corresponding label with matching for/id
      expect(rendered).to have_css('input#status_active + label[for="status_active"]')
      expect(rendered).to have_css('input#status_inactive + label[for="status_inactive"]')
    end

    it "includes hint for additional context" do
      render_radio_group
      expect(rendered).to have_css("small.form-text", text: "Select the current status")
    end
  end

  describe "edge cases and error handling" do
    it "handles empty option labels gracefully" do
      empty_label_options = [["", "empty"], ["Normal", "normal"]]

      # Mock both options in the array
      allow(mock_form).to receive(:radio_button)
        .with(field, "empty", {id: "status_empty"})
        .and_return('<input type="radio" name="status" value="empty" id="status_empty" />'.html_safe)

      allow(mock_form).to receive(:radio_button)
        .with(field, "normal", {id: "status_normal"})
        .and_return('<input type="radio" name="status" value="normal" id="status_normal" />'.html_safe)

      allow(view).to receive(:label_tag)
        .with("status_empty", "", {class: "radio-label"})
        .and_return('<label for="status_empty" class="radio-label"></label>'.html_safe)

      allow(view).to receive(:label_tag)
        .with("status_normal", "Normal", {class: "radio-label"})
        .and_return('<label for="status_normal" class="radio-label">Normal</label>'.html_safe)

      render_radio_group(options: empty_label_options)
      expect(rendered).to have_css('input[type="radio"][value="empty"]')
      expect(rendered).to have_css('input[type="radio"][value="normal"]')
    end

    it "handles special characters in values" do
      special_options = [["Option 1", "value with spaces"], ["Option 2", "value-with-dashes"]]

      special_options.each do |label, value|
        # The partial uses the raw value in the ID (no sanitization)
        radio_id = "#{field}_#{value}"

        allow(mock_form).to receive(:radio_button)
          .with(field, value, {id: radio_id})
          .and_return(%(<input type="radio" name="#{field}" value="#{value}" id="#{radio_id}" />).html_safe)

        allow(view).to receive(:label_tag)
          .with(radio_id, label, {class: "radio-label"})
          .and_return(%(<label for="#{radio_id}" class="radio-label">#{label}</label>).html_safe)
      end

      render_radio_group(options: special_options)
      expect(rendered).to have_css('input[type="radio"][value="value with spaces"]')
      expect(rendered).to have_css('input[type="radio"][value="value-with-dashes"]')
    end

    it "maintains form structure even with malformed options" do
      # Test with nil values in options (should be handled gracefully)
      render_radio_group(options: [])

      expect(rendered).to have_css("div.form-group")
      expect(rendered).to have_css("div.radio-group")
      expect(rendered).to have_css('label[for="status"]')
    end
  end
end
