require "rails_helper"

RSpec.describe "form/_pass_fail.html.erb", type: :view do
  let(:mock_form) { double("FormBuilder") }
  let(:field) { :status }

  # Default render method with common setup
  def render_pass_fail(locals = {})
    render partial: "form/pass_fail", locals: {field: field}.merge(locals)
  end

  before do
    # Set the form context as form_context would
    view.instance_variable_set(:@_current_form, mock_form)

    # Mock i18n translations for pass/fail labels
    allow(view).to receive(:t)
      .with("shared.pass")
      .and_return("Pass")
    allow(view).to receive(:t)
      .with("shared.fail")
      .and_return("Fail")

    # Mock form builder methods with default behavior
    allow(mock_form).to receive(:radio_button)
      .with(field, true, id: "#{field}_true")
      .and_return('<input type="radio" name="status" value="true" id="status_true" />'.html_safe)

    allow(mock_form).to receive(:radio_button)
      .with(field, false, id: "#{field}_false")
      .and_return('<input type="radio" name="status" value="false" id="status_false" />'.html_safe)
  end

  describe "basic rendering" do
    it "renders a complete pass/fail radio group" do
      render_pass_fail

      expect(rendered).to have_css("div")
      expect(rendered).to have_css("label", text: "#{I18n.t("shared.pass")}/#{I18n.t("shared.fail")}")
      expect(rendered).to have_css('input[type="radio"][name="status"][value="true"][id="status_true"]')
      expect(rendered).to have_css('input[type="radio"][name="status"][value="false"][id="status_false"]')
      expect(rendered).to have_css("label", text: I18n.t("shared.pass"))
      expect(rendered).to have_css("label", text: I18n.t("shared.fail"))
    end

    it "nests radio buttons inside their labels" do
      render_pass_fail
      # Check that radio buttons are inside labels
      within("div") do
        labels_with_pass = all("label", text: I18n.t("shared.pass"))
        pass_label = labels_with_pass.find { |l| l.has_css?('input[type="radio"]') }
        expect(pass_label).to have_css('input[type="radio"][value="true"]')

        labels_with_fail = all("label", text: I18n.t("shared.fail"))
        fail_label = labels_with_fail.find { |l| l.has_css?('input[type="radio"]') }
        expect(fail_label).to have_css('input[type="radio"][value="false"]')
      end
    end

    it "generates proper radio button IDs for accessibility" do
      render_pass_fail

      expect(rendered).to have_css('input#status_true[type="radio"]')
      expect(rendered).to have_css('input#status_false[type="radio"]')
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
        expect(rendered).to have_css("label", text: "#{I18n.t("shared.pass")}/#{I18n.t("shared.fail")}")
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
      expect(view).to receive(:t).with("shared.pass").and_return("Pass")
      expect(view).to receive(:t).with("shared.fail").and_return("Fail")

      render_pass_fail
    end
  end

  describe "accessibility and semantic structure" do
    it "properly associates radio buttons with their labels through nesting" do
      render_pass_fail

      # Labels contain the radio buttons
      within("div") do
        labels_with_pass = all("label", text: I18n.t("shared.pass"))
        pass_label = labels_with_pass.find { |l| l.has_css?('input[type="radio"]') }
        expect(pass_label).to have_css('input[type="radio"][value="true"]')

        labels_with_fail = all("label", text: I18n.t("shared.fail"))
        fail_label = labels_with_fail.find { |l| l.has_css?('input[type="radio"]') }
        expect(fail_label).to have_css('input[type="radio"][value="false"]')
      end
    end

    it "uses boolean values for pass/fail" do
      render_pass_fail
      expect(rendered).to have_css('input[type="radio"][value="true"]')
      expect(rendered).to have_css('input[type="radio"][value="false"]')
    end

    it "includes hint for additional context when present" do
      render_pass_fail
    end
  end
end
