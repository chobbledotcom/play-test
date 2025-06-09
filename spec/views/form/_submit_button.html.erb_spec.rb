require "rails_helper"

RSpec.describe "form/_submit_button.html.erb", type: :view do
  let(:mock_form) { double("FormBuilder") }
  let(:default_button_text) { "Submit" }

  # Default render method with common setup
  def render_submit_button(locals = {})
    render partial: "form/submit_button", locals: locals
  end

  before do
    # Mock form builder submit method with flexible argument matching
    allow(mock_form).to receive(:submit) do |text|
      %(<input type="submit" value="#{text}" />).html_safe
    end

    # Mock the translation lookup
    allow(view).to receive(:t)
      .with("buttons.submit", default: "Submit")
      .and_return(default_button_text)

    # Set current form for fallback
    view.instance_variable_set(:@_current_form, mock_form)
  end

  describe "basic rendering" do
    it "renders a submit button with default text" do
      render_submit_button

      expect(rendered).to have_css('input[type="submit"][value="Submit"]')
      expect(mock_form).to have_received(:submit).with("Submit")
    end

    it "uses the form object from @_current_form when no form provided" do
      render_submit_button

      expect(mock_form).to have_received(:submit)
    end
  end

  describe "custom button text" do
    it "uses explicit text when provided" do
      render_submit_button(text: "Save Changes")

      expect(rendered).to have_css('input[type="submit"][value="Save Changes"]')
      expect(mock_form).to have_received(:submit).with("Save Changes")
    end

    it "does not call translation when explicit text provided" do
      render_submit_button(text: "Custom Text")

      # Should not call t() for translation lookup when text is explicit
      expect(view).not_to have_received(:t).with("buttons.submit", default: "Submit")
    end

    shared_examples "renders button with text" do |button_text, description|
      it "renders #{description}" do
        render_submit_button(text: button_text)

        expect(rendered).to have_css(%(input[type="submit"][value="#{button_text}"]))
        expect(mock_form).to have_received(:submit).with(button_text)
      end
    end

    include_examples "renders button with text", "Create User", "create action text"
    include_examples "renders button with text", "Update Profile", "update action text"
    include_examples "renders button with text", "Delete Item", "delete action text"
    include_examples "renders button with text", "Save & Continue", "text with special characters"
    include_examples "renders button with text", "Submit Application", "longer descriptive text"
    include_examples "renders button with text", "Go!", "short exclamatory text"
  end

  describe "i18n translation behavior" do
    context "when no explicit text provided" do
      it "looks up translation for buttons.submit" do
        render_submit_button

        expect(view).to have_received(:t).with("buttons.submit", default: "Submit")
      end

      it "uses default value when translation missing" do
        # Mock a missing translation scenario
        allow(view).to receive(:t)
          .with("buttons.submit", default: "Submit")
          .and_return("Submit") # Returns the default

        render_submit_button

        expect(mock_form).to have_received(:submit).with("Submit")
      end

      it "uses translated text when available" do
        allow(view).to receive(:t)
          .with("buttons.submit", default: "Submit")
          .and_return("Enviar") # Spanish translation

        render_submit_button

        expect(rendered).to have_css('input[type="submit"][value="Enviar"]')
        expect(mock_form).to have_received(:submit).with("Enviar")
      end
    end

    context "with different locale contexts" do
      shared_examples "uses correct translation" do |translation_key, expected_text|
        it "translates #{translation_key} to '#{expected_text}'" do
          allow(view).to receive(:t)
            .with("buttons.submit", default: "Submit")
            .and_return(expected_text)

          render_submit_button

          expect(rendered).to have_css(%(input[type="submit"][value="#{expected_text}"]))
        end
      end

      include_examples "uses correct translation", "buttons.submit", "Submit"
      include_examples "uses correct translation", "buttons.submit", "Save"
      include_examples "uses correct translation", "buttons.submit", "Send"
      include_examples "uses correct translation", "buttons.submit", "Continue"
    end
  end

  describe "form object handling" do
    let(:other_form) { double("OtherFormBuilder") }

    context "with explicit form object" do
      before do
        allow(other_form).to receive(:submit) do |text|
          %(<input type="submit" value="#{text}" />).html_safe
        end
      end

      it "uses the provided form object instead of @_current_form" do
        render_submit_button(form: other_form)

        expect(other_form).to have_received(:submit)
        expect(mock_form).not_to have_received(:submit)
      end

      it "uses explicit form with custom text" do
        render_submit_button(form: other_form, text: "Custom Submit")

        expect(other_form).to have_received(:submit).with("Custom Submit")
        expect(rendered).to have_css('input[type="submit"][value="Custom Submit"]')
      end
    end

    context "when no form object available" do
      before do
        view.instance_variable_set(:@_current_form, nil)
      end

      it "raises an error when no form object provided" do
        expect { render_submit_button }.to raise_error(ActionView::Template::Error, /undefined method.*submit.*for nil/)
      end

      it "works when explicit form object provided" do
        allow(other_form).to receive(:submit) do |text|
          %(<input type="submit" value="#{text}" />).html_safe
        end

        expect { render_submit_button(form: other_form) }.not_to raise_error
        expect(other_form).to have_received(:submit)
      end
    end
  end

  describe "edge cases and error handling" do
    it "handles empty string text" do
      render_submit_button(text: "")

      expect(rendered).to have_css('input[type="submit"][value=""]')
      expect(mock_form).to have_received(:submit).with("")
    end

    it "handles nil text gracefully" do
      # When text is nil, it should fall back to translation
      render_submit_button(text: nil)

      expect(view).to have_received(:t).with("buttons.submit", default: "Submit")
      expect(mock_form).to have_received(:submit).with("Submit")
    end

    it "handles text with HTML entities" do
      html_text = "&lt;Save&gt;"
      render_submit_button(text: html_text)

      expect(rendered).to have_css('input[type="submit"]')
      expect(rendered).to include('value="&lt;Save&gt;"')
    end

    it "handles very long text" do
      long_text = "This is a very long submit button text that might wrap or cause layout issues"
      render_submit_button(text: long_text)

      expect(rendered).to have_css('input[type="submit"]')
      expect(mock_form).to have_received(:submit).with(long_text)
    end

    it "handles Unicode characters" do
      unicode_text = "Submit ✓ 提交"
      render_submit_button(text: unicode_text)

      expect(rendered).to have_css('input[type="submit"]')
      expect(mock_form).to have_received(:submit).with(unicode_text)
    end
  end

  describe "HTML output and attributes" do
    it "generates valid HTML submit input" do
      render_submit_button

      expect(rendered).to have_css('input[type="submit"]')
      expect(rendered).to include('type="submit"')
      expect(rendered).to include('value="Submit"')
    end

    it "does not add extra wrapper elements" do
      render_submit_button

      # Should only contain the input element, no extra divs or wrappers
      expect(rendered.strip).to eq('<input type="submit" value="Submit" />')
    end

    it "maintains button text in value attribute" do
      render_submit_button(text: "Test Button")

      expect(rendered).to include('value="Test Button"')
    end
  end

  describe "accessibility considerations" do
    it "creates focusable submit element" do
      render_submit_button

      # Submit buttons are naturally focusable and accessible
      expect(rendered).to have_css('input[type="submit"]')
    end

    it "provides clear action text" do
      render_submit_button(text: "Submit Form")

      expect(rendered).to include('value="Submit Form"')
    end

    it "works with screen readers via value attribute" do
      render_submit_button(text: "Save User Profile")

      # Screen readers will announce the value attribute
      expect(rendered).to include('value="Save User Profile"')
    end
  end
end
