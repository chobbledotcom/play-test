require "rails_helper"

RSpec.describe "form/_pass_fail.html.erb", type: :view do
  let(:mock_form) { double("FormBuilder") }
  let(:field) { :status }
  let(:field_config) do
    {
      form_object: mock_form,
      i18n_base: "test.forms",
      field_label: "Status",
      field_hint: nil,
      field_placeholder: nil,
      value: nil,
      prefilled: false
    }
  end

  # Default render method with common setup
  def render_pass_fail(locals = {})
    render partial: "form/pass_fail", locals: {field: field}.merge(locals)
  end

  before do
    # Mock the form field setup helper
    allow(view).to receive(:form_field_setup).and_return(field_config)
    
    # Mock the radio_button_options helper
    allow(view).to receive(:radio_button_options).and_return({})
    
    # Mock i18n translations
    allow(view).to receive(:t).and_call_original
    allow(view).to receive(:t).with('shared.pass').and_return('Pass')
    allow(view).to receive(:t).with('shared.fail').and_return('Fail')
    
    # Mock form builder radio_button method
    allow(mock_form).to receive(:radio_button) do |field, value, options = {}|
      id = options[:id] || "#{field}_#{value}"
      checked = options[:checked] ? ' checked="checked"' : ''
      %(<input type="radio" name="#{field}" value="#{value}" id="#{id}"#{checked} />).html_safe
    end
  end

  describe "basic rendering" do
    it "renders a complete pass/fail radio group" do
      render_pass_fail
      
      expect(rendered).to have_css("div")
      expect(rendered).to have_css("label", text: "Status") # Field label
      expect(rendered).to have_css('input[type="radio"][name="status"][value="true"][id="status_true"]')
      expect(rendered).to have_css('input[type="radio"][name="status"][value="false"][id="status_false"]')
      expect(rendered).to have_css("label", text: "Pass")
      expect(rendered).to have_css("label", text: "Fail")
    end

    it "nests radio buttons inside their labels" do
      render_pass_fail
      
      # Check that radio buttons are inside labels
      doc = Nokogiri::HTML(rendered)
      pass_labels = doc.css('label').select { |l| l.text.include?("Pass") }
      pass_label_with_input = pass_labels.find { |l| l.css('input[type="radio"]').any? }
      expect(pass_label_with_input).not_to be_nil
      expect(pass_label_with_input.css('input[value="true"]')).not_to be_empty

      fail_labels = doc.css('label').select { |l| l.text.include?("Fail") }
      fail_label_with_input = fail_labels.find { |l| l.css('input[type="radio"]').any? }
      expect(fail_label_with_input).not_to be_nil
      expect(fail_label_with_input.css('input[value="false"]')).not_to be_empty
    end

    it "generates proper radio button IDs for accessibility" do
      render_pass_fail
      
      expect(rendered).to have_css('input#status_true[type="radio"]')
      expect(rendered).to have_css('input#status_false[type="radio"]')
    end
  end

  describe "with prefilled value" do
    it "checks the appropriate radio button when prefilled" do
      # Setup field_config with prefilled data
      allow(view).to receive(:form_field_setup).and_return(
        field_config.merge(value: true, prefilled: true)
      )
      
      # Mock radio_button_options to return checked for true
      allow(view).to receive(:radio_button_options).with(true, true, true).and_return({checked: true})
      allow(view).to receive(:radio_button_options).with(true, true, false).and_return({})
      
      render_pass_fail
      
      expect(rendered).to have_css('input[type="radio"][value="true"][checked="checked"]')
      expect(rendered).not_to have_css('input[type="radio"][value="false"][checked="checked"]')
    end

    it "adds prefilled wrapper class when field is prefilled" do
      allow(view).to receive(:form_field_setup).and_return(
        field_config.merge(value: false, prefilled: true)
      )
      
      render_pass_fail
      
      expect(rendered).to have_css('div.set-previous')
    end
  end

  describe "different field contexts" do
    shared_examples "renders correctly for field" do |field_name|
      it "handles #{field_name} field" do
        # Mock the form_field_setup method for this field
        allow(view).to receive(:form_field_setup).and_return(
          field_config.merge(field_label: field_name.to_s.humanize)
        )
        
        render partial: "form/pass_fail", locals: {field: field_name}
        
        expect(rendered).to have_css("div")
        expect(rendered).to have_css("label", text: field_name.to_s.humanize)
      end
    end

    include_examples "renders correctly for field", :passed
    include_examples "renders correctly for field", :meets_requirements
    include_examples "renders correctly for field", :satisfactory
    include_examples "renders correctly for field", :compliant
    include_examples "renders correctly for field", :approved
  end

  describe "i18n integration" do
    it "uses i18n for pass/fail labels" do
      render_pass_fail
      
      expect(rendered).to have_content("Pass")
      expect(rendered).to have_content("Fail")
    end
    
    it "calls t() for pass/fail translations" do
      expect(view).to receive(:t).with('shared.pass').and_return('Pass')
      expect(view).to receive(:t).with('shared.fail').and_return('Fail')
      
      render_pass_fail
    end
  end

  describe "accessibility and semantic structure" do
    it "properly associates radio buttons with their labels through nesting" do
      render_pass_fail
      
      # Labels contain the radio buttons
      doc = Nokogiri::HTML(rendered)
      pass_labels = doc.css('label').select { |l| l.text.include?("Pass") }
      pass_label_with_input = pass_labels.find { |l| l.css('input[type="radio"]').any? }
      expect(pass_label_with_input).not_to be_nil
      expect(pass_label_with_input.css('input[value="true"]')).not_to be_empty

      fail_labels = doc.css('label').select { |l| l.text.include?("Fail") }
      fail_label_with_input = fail_labels.find { |l| l.css('input[type="radio"]').any? }
      expect(fail_label_with_input).not_to be_nil
      expect(fail_label_with_input.css('input[value="false"]')).not_to be_empty
    end

    it "uses boolean values for pass/fail" do
      render_pass_fail
      
      expect(rendered).to have_css('input[type="radio"][value="true"]')
      expect(rendered).to have_css('input[type="radio"][value="false"]')
    end
  end
end