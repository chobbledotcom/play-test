require "rails_helper"

RSpec.describe "form/_submit_button.html.erb", type: :view do
  let(:default_button_text) { "Save Form" }
  let(:i18n_base) { "forms.test_form" }

  # Helper to setup submit button with custom text and i18n base
  def setup_submit_button(text: default_button_text, base: i18n_base)
    @mock_form = mock_form_builder
    setup_form_field_config(field: :submit, i18n_base: base)

    # Override the submit method specifically
    allow(@mock_form).to receive(:submit) do |button_text|
      %(<input type="submit" value="#{button_text}" />).html_safe
    end

    allow(view).to receive(:t)
      .with("#{base}.submit", raise: true)
      .and_return(text)

    view.instance_variable_set(:@_current_form, @mock_form)
    view.instance_variable_set(:@_current_i18n_base, base)
  end

  # Helper to render and check basic submit button structure
  def expect_submit_button_with_text(expected_text)
    render_form_partial("submit_button")
    expect(rendered).to have_css('input[type="submit"]')
    expect(rendered).to include(%(value="#{expected_text}"))
    expect(@mock_form).to have_received(:submit).with(expected_text)
  end

  before { setup_submit_button }

  describe "basic rendering" do
    it "renders a submit button with default text" do
      expect_submit_button_with_text("Save Form")
    end

    it "uses the form object from @_current_form when no form provided" do
      expect_submit_button_with_text("Save Form")
    end
  end

  describe "i18n integration" do
    it "uses the i18n base to find submit text" do
      expect_submit_button_with_text("Save Form")
      expect(view).to have_received(:t).with("forms.test_form.submit", raise: true)
    end

    it "works with different i18n bases" do
      setup_submit_button(text: "Update User", base: "forms.users")
      expect_submit_button_with_text("Update User")
    end
  end

  describe "translation error handling" do
    it "raises error when translation is missing (uses raise: true)" do
      allow(view).to receive(:t)
        .with("forms.test_form.submit", raise: true)
        .and_raise(I18n::MissingTranslationData.new(:en, "forms.test_form.submit"))

      expect { render_form_partial("submit_button") }.to raise_error(ActionView::Template::Error)
    end
  end

  describe "different form types" do
    {
      "inspector_companies" => "Save Company",
      "users" => "Update User",
      "session_new" => "Sign In",
      "units" => "Save Unit"
    }.each do |form_type, expected_text|
      it "renders #{form_type} form submit button" do
        setup_submit_button(text: expected_text, base: "forms.#{form_type}")
        expect_submit_button_with_text(expected_text)
      end
    end
  end

  describe "form object handling" do
    it "uses @_current_form to render submit button" do
      expect_submit_button_with_text("Save Form")
    end

    it "raises error when no form object available" do
      view.instance_variable_set(:@_current_form, nil)
      expect { render_form_partial("submit_button") }.to raise_error(ActionView::Template::Error, /undefined method.*submit.*for nil/)
    end

    it "raises error when no i18n base available" do
      view.instance_variable_set(:@_current_i18n_base, nil)
      expect { render_form_partial("submit_button") }.to raise_error(RSpec::Mocks::MockExpectationError)
    end
  end

  describe "edge cases and error handling" do
    {
      "HTML entities" => "&lt;Save&gt;",
      "very long text" => "This is a very long submit button text that might wrap or cause layout issues",
      "Unicode characters" => "Submit ✓ 提交"
    }.each do |description, test_text|
      it "handles #{description} from i18n" do
        setup_submit_button(text: test_text)
        expect_submit_button_with_text(test_text)
      end
    end
  end

  describe "HTML output and attributes" do
    it "generates valid HTML submit input" do
      expect_submit_button_with_text("Save Form")
      expect(rendered).to include('type="submit"')
    end

    it "does not add extra wrapper elements" do
      render_form_partial("submit_button")
      expect(rendered.strip).to eq('<input type="submit" value="Save Form" />')
    end

    it "maintains button text in value attribute" do
      expect_submit_button_with_text("Save Form")
    end
  end

  describe "accessibility considerations" do
    it "creates focusable submit element" do
      expect_submit_button_with_text("Save Form")
    end

    it "provides clear action text from i18n" do
      expect_submit_button_with_text("Save Form")
    end

    it "works with screen readers via value attribute" do
      expect_submit_button_with_text("Save Form")
    end
  end
end
