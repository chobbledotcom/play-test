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

    # Mock radio buttons for each option
    allow(mock_form).to receive(:radio_button)
      .with(field, "active", {id: "status_active"})
      .and_return('<input type="radio" name="status" value="active" id="status_active" />'.html_safe)

    allow(mock_form).to receive(:radio_button)
      .with(field, "inactive", {id: "status_inactive"})
      .and_return('<input type="radio" name="status" value="inactive" id="status_inactive" />'.html_safe)

    # Set current i18n base for the partial
    view.instance_variable_set(:@_current_i18n_base, "test.forms")
  end

  describe "basic rendering" do
    it "renders a complete radio group with all options" do
      render_radio_group

      expect(rendered).to have_css("div")
      expect(rendered).to have_css("label", text: "Status")
      expect(rendered).to have_css('input[type="radio"][name="status"][value="active"][id="status_active"]')
      expect(rendered).to have_css('input[type="radio"][name="status"][value="inactive"][id="status_inactive"]')
      expect(rendered).to have_css("label", text: "Active")
      expect(rendered).to have_css("label", text: "Inactive")
      expect(rendered).to have_css("small", text: "Select the current status")
    end

    it "nests radio buttons inside their labels" do
      render_radio_group
      # Check that radio buttons are inside labels (not the field label, but the option labels)
      expect(rendered).to have_css("label", text: "Active") do |label|
        expect(label).to have_css('input[type="radio"]')
      end
      expect(rendered).to have_css("label", text: "Inactive") do |label|
        expect(label).to have_css('input[type="radio"]')
      end
    end

    context "when hint is not present" do
      let(:field_config) { super().merge(field_hint: nil) }

      it "does not render the hint element" do
        render_radio_group
        expect(rendered).not_to have_css("small")
      end
    end

    context "when no options provided" do
      it "renders empty radio group" do
        render_radio_group(options: [])

        expect(rendered).to have_css("div")
        expect(rendered).to have_css("label", text: "Status")
        expect(rendered).not_to have_css('input[type="radio"]')
      end
    end
  end

  describe "option variations" do
    shared_examples "renders radio options correctly" do |options_array, description|
      it "handles #{description}" do
        # Mock the radio buttons for this specific set of options
        options_array.each do |label, value|
          radio_id = "#{field}_#{value}"
          allow(mock_form).to receive(:radio_button)
            .with(field, value, {id: radio_id})
            .and_return(%(<input type="radio" name="#{field}" value="#{value}" id="#{radio_id}" />).html_safe)
        end

        render_radio_group(options: options_array)

        options_array.each do |label, value|
          radio_id = "#{field}_#{value}"
          expect(rendered).to have_css(%(input[type="radio"][name="#{field}"][value="#{value}"][id="#{radio_id}"]))
          expect(rendered).to have_css("label", text: label)
        end
      end
    end

    include_examples "renders radio options correctly", [["Yes", true], ["No", false]], "boolean values"
    include_examples "renders radio options correctly", [["Small", "s"], ["Medium", "m"], ["Large", "l"]], "multiple string values"
    include_examples "renders radio options correctly", [["One", 1], ["Two", 2], ["Three", 3]], "integer values"
    include_examples "renders radio options correctly", [["Draft", "draft"], ["Published", "published"], ["Archived", "archived"]], "status strings"
  end

  describe "form object handling" do
    let(:other_form) { double("OtherFormBuilder") }

    before do
      allow(view).to receive(:form_field_setup).and_return(
        field_config.merge(form_object: other_form)
      )
      allow(other_form).to receive(:radio_button)
        .with(field, "active", {id: "status_active"})
        .and_return('<input type="radio" />'.html_safe)
      allow(other_form).to receive(:radio_button)
        .with(field, "inactive", {id: "status_inactive"})
        .and_return('<input type="radio" />'.html_safe)
    end

    it "uses the form object returned by form_field_setup" do
      render_radio_group(form: other_form)

      expect(other_form).to have_received(:radio_button).at_least(:once)
    end
  end

  describe "different field types" do
    shared_examples "renders correctly for field" do |field_name|
      it "handles #{field_name} field" do
        # Mock for the new field
        allow(mock_form).to receive(:radio_button).with(field_name, anything, anything)
          .and_return('<input type="radio" />'.html_safe)

        render_radio_group(field: field_name)
        expect(rendered).to have_css("div")
        expect(rendered).to have_css("label", text: "Status")
      end
    end

    include_examples "renders correctly for field", :priority
    include_examples "renders correctly for field", :category
    include_examples "renders correctly for field", :visibility
    include_examples "renders correctly for field", :approval_status
  end

  describe "accessibility and semantics" do
    it "generates unique IDs for each radio button" do
      render_radio_group

      expect(rendered).to have_css("#status_active")
      expect(rendered).to have_css("#status_inactive")

      # Ensure IDs are unique
      doc = Nokogiri::HTML(rendered)
      ids = doc.css("[id]").map { |el| el["id"] }
      expect(ids).to eq(ids.uniq)
    end

    it "provides proper label association through nesting" do
      render_radio_group
      # Option labels contain the radio buttons
      expect(rendered).to have_css("label", text: "Active") do |label|
        expect(label).to have_css('input[type="radio"][value="active"]')
      end
      expect(rendered).to have_css("label", text: "Inactive") do |label|
        expect(label).to have_css('input[type="radio"][value="inactive"]')
      end
    end

    it "includes hint for additional context" do
      render_radio_group
      expect(rendered).to have_css("small", text: field_config[:field_hint])
    end
  end

  describe "edge cases and error handling" do
    it "handles options with nil values" do
      allow(mock_form).to receive(:radio_button)
        .with(field, nil, {id: "status_"})
        .and_return('<input type="radio" name="status" value="" id="status_" />'.html_safe)

      render_radio_group(options: [["None", nil]])
      expect(rendered).to have_css('input[type="radio"][value=""]')
    end

    it "handles options with empty string values" do
      allow(mock_form).to receive(:radio_button)
        .with(field, "", {id: "status_"})
        .and_return('<input type="radio" name="status" value="" id="status_" />'.html_safe)

      render_radio_group(options: [["Empty", ""]])
      expect(rendered).to have_css('input[type="radio"][value=""]')
    end

    it "handles options with special characters in labels" do
      special_options = [["Label & Special", "special"], ['Label "Quoted"', "quoted"]]

      special_options.each do |label, value|
        allow(mock_form).to receive(:radio_button)
          .with(field, value, {id: "status_#{value}"})
          .and_return(%(<input type="radio" name="status" value="#{value}" id="status_#{value}" />).html_safe)
      end

      render_radio_group(options: special_options)
      expect(rendered).to include("Label &amp; Special")
      expect(rendered).to include("Label &quot;Quoted&quot;")
    end
  end
end
