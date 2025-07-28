require "rails_helper"

RSpec.describe "chobble_forms/_errors.html.erb", type: :view do
  let(:mock_model) { double("Model") }
  let(:error_double) { double("Error") }

  # Default render method with common setup
  def render_errors(locals = {})
    render partial: "chobble_forms/errors", locals: {model: mock_model}.merge(locals)
  end

  before do
    # Mock model class and name
    allow(mock_model).to receive(:class).and_return(double("ModelClass", model_name: double("ModelName", singular: "test_model")))
    # Mock i18n methods with flexible arguments
    allow(view).to receive(:t).and_call_original
    allow(view).to receive(:pluralize).and_call_original

    # Set up form context that errors partial expects
    view.instance_variable_set(:@_current_i18n_base, "forms.inspection")

    # Add i18n translations for form errors (this should exist in real forms)
    I18n.backend.store_translations(:en, {
      forms: {
        inspections: {
          errors: {
            header: {
              one: "Could not save inspection because there is 1 error:",
              other: "Could not save inspection because there are %{count} errors:"
            }
          }
        }
      }
    })
  end

  describe "basic rendering" do
    context "when model has no errors" do
      before do
        allow(mock_model).to receive(:errors).and_return(double("Errors", any?: false, count: 0))
      end

      it "renders nothing" do
        render_errors
        expect(rendered.strip).to be_empty
      end
    end

    context "when model has errors" do
      before do
        errors_mock = double("Errors", any?: true, count: 1)
        allow(errors_mock).to receive(:each).and_yield(error_double)
        allow(mock_model).to receive(:errors).and_return(errors_mock)
        allow(error_double).to receive(:full_message).and_return("Name can't be blank")
      end

      it "renders error section with proper accessibility attributes" do
        render_errors

        expect(rendered).to have_css('aside.form-errors[role="alert"]')
        expect(rendered).to have_css("h3")
        expect(rendered).to have_css("ul")
        expect(rendered).to have_css("li", text: "Name can't be blank")
      end

      it "iterates through all error messages" do
        render_errors
        expect(error_double).to have_received(:full_message)
        expect(rendered).to include("Name can&#39;t be blank")
      end
    end
  end

  describe "header text generation" do
    before do
      errors_mock = double("Errors", any?: true, count: 2)
      allow(errors_mock).to receive(:each).and_yield(error_double).and_yield(error_double)
      allow(mock_model).to receive(:errors).and_return(errors_mock)
      allow(error_double).to receive(:full_message).and_return("Error message")
    end

    context "with custom header text" do
      it "uses provided header text" do
        render_errors(header: "Custom error header")
        expect(rendered).to have_css("h3", text: "Custom error header")
      end
    end

    context "with model-specific i18n lookup" do
      it "attempts model-specific translation first" do
        allow(view).to receive(:t)
          .with("forms.inspection.errors.header", hash_including(count: 2, raise: true))
          .and_return("Test Model Error Header")

        render_errors
        expect(rendered).to have_css("h3", text: "Test Model Error Header")
      end

      it "falls back to generic errors.header translation" do
        allow(view).to receive(:t)
          .with("forms.inspection.errors.header", hash_including(count: 2, raise: true))
          .and_return("Generic Error Header")

        render_errors
        expect(rendered).to have_css("h3", text: "Generic Error Header")
      end

      it "raises error when translation is missing (no fallback)" do
        allow(view).to receive(:t)
          .with("forms.inspection.errors.header", hash_including(count: 2, raise: true))
          .and_raise(I18n::MissingTranslationData.new(:en, "forms.inspection.errors.header"))

        expect { render_errors }.to raise_error(ActionView::Template::Error)
      end
    end
  end

  describe "multiple errors handling" do
    let(:error1) { double("Error1", full_message: "Name can't be blank") }
    let(:error2) { double("Error2", full_message: "Email is invalid") }
    let(:error3) { double("Error3", full_message: "Password is too short") }

    before do
      errors_mock = double("Errors", any?: true, count: 3)
      allow(errors_mock).to receive(:each).and_yield(error1).and_yield(error2).and_yield(error3)
      allow(mock_model).to receive(:errors).and_return(errors_mock)
      allow(view).to receive(:t).with(anything, hash_including(:count)).and_return("3 errors")
    end

    it "renders all error messages in a list" do
      render_errors

      expect(rendered).to have_css("ul")
      expect(rendered).to have_css("li", text: "Name can't be blank")
      expect(rendered).to have_css("li", text: "Email is invalid")
      expect(rendered).to have_css("li", text: "Password is too short")
    end

    it "calls full_message on each error" do
      render_errors

      expect(error1).to have_received(:full_message)
      expect(error2).to have_received(:full_message)
      expect(error3).to have_received(:full_message)
    end
  end

  describe "different model types" do
    shared_examples "renders errors for model" do |model_class_name|
      let(:mock_model) { double("Model") }

      before do
        allow(mock_model).to receive(:class).and_return(
          double("ModelClass", model_name: double("ModelName", singular: model_class_name))
        )
        errors_mock = double("Errors", any?: true, count: 1)
        allow(errors_mock).to receive(:each).and_yield(error_double)
        allow(mock_model).to receive(:errors).and_return(errors_mock)
        allow(error_double).to receive(:full_message).and_return("Test error")
        allow(view).to receive(:t).with(anything, hash_including(:count)).and_return("1 error")
      end

      it "works with #{model_class_name} model" do
        render_errors
        expect(rendered).to have_css("aside.form-errors")
        expect(rendered).to include("Test error")
      end
    end

    include_examples "renders errors for model", "user"
    include_examples "renders errors for model", "inspection"
    include_examples "renders errors for model", "inspector_company"
    include_examples "renders errors for model", "unit"
    include_examples "renders errors for model", "custom_model"
  end

  describe "parameter validation" do
    it "raises error when no model provided" do
      expect { render partial: "chobble_forms/errors", locals: {} }.to raise_error(ActionView::Template::Error, "model object is required for form errors")
    end

    it "raises error when model is nil" do
      expect { render partial: "chobble_forms/errors", locals: {model: nil} }.to raise_error(ActionView::Template::Error, "model object is required for form errors")
    end

    it "accepts model via 'object' parameter for compatibility" do
      allow(mock_model).to receive(:errors).and_return(double("Errors", any?: false, count: 0))

      expect { render partial: "chobble_forms/errors", locals: {object: mock_model} }.not_to raise_error
    end
  end

  describe "accessibility features" do
    before do
      errors_mock = double("Errors", any?: true, count: 1)
      allow(errors_mock).to receive(:each).and_yield(error_double)
      allow(mock_model).to receive(:errors).and_return(errors_mock)
      allow(error_double).to receive(:full_message).and_return("Error message")
      allow(view).to receive(:t).with(anything, hash_including(:count)).and_return("1 error")
    end

    it "includes role='alert' for screen readers" do
      render_errors
      expect(rendered).to have_css('aside[role="alert"]')
    end

    it "uses semantic HTML structure" do
      render_errors

      expect(rendered).to have_css("aside.form-errors")
      expect(rendered).to have_css("h3")  # Heading for context
      expect(rendered).to have_css("ul")  # Unordered list for errors
      expect(rendered).to have_css("li")  # List items for each error
    end

    it "provides clear error context with heading" do
      render_errors
      expect(rendered).to have_css("h3")
    end
  end

  describe "edge cases and error handling" do
    it "handles empty error messages gracefully" do
      errors_mock = double("Errors", any?: true, count: 1)
      allow(errors_mock).to receive(:each).and_yield(error_double)
      allow(mock_model).to receive(:errors).and_return(errors_mock)
      allow(error_double).to receive(:full_message).and_return("")
      allow(view).to receive(:t).with(anything, hash_including(:count)).and_return("1 error")

      render_errors
      expect(rendered).to have_css("li", text: "")
    end

    it "handles HTML in error messages" do
      errors_mock = double("Errors", any?: true, count: 1)
      allow(errors_mock).to receive(:each).and_yield(error_double)
      allow(mock_model).to receive(:errors).and_return(errors_mock)
      allow(error_double).to receive(:full_message).and_return("Name <script>alert('xss')</script>")
      allow(view).to receive(:t).with(anything, hash_including(:count)).and_return("1 error")

      render_errors
      expect(rendered).to include("Name &lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
    end

    it "handles Unicode error messages" do
      errors_mock = double("Errors", any?: true, count: 1)
      allow(errors_mock).to receive(:each).and_yield(error_double)
      allow(mock_model).to receive(:errors).and_return(errors_mock)
      allow(error_double).to receive(:full_message).and_return("名前が入力されていません")
      allow(view).to receive(:t).with(anything, hash_including(:count)).and_return("1 error")

      render_errors
      expect(rendered).to include("名前が入力されていません")
    end
  end
end
