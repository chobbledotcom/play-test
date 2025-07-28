require "spec_helper"
require "action_view"
require "chobble/forms/helpers"

RSpec.describe ChobbleForms::Helpers do
  # Create a test class that includes the helpers
  let(:helper_class) do
    Class.new do
      include ChobbleForms::Helpers
      include ActionView::Helpers::NumberHelper
      include ActionView::Helpers::TranslationHelper

      attr_accessor :_current_form, :_current_i18n_base, :previous_inspection

      def initialize
        @_current_form = nil
        @_current_i18n_base = nil
        @previous_inspection = nil
      end
    end
  end

  let(:helper) { helper_class.new }
  let(:mock_form) { double("FormBuilder", object: nil) }
  let(:field) { :name }
  let(:local_assigns) { {} }
  let(:result) { helper.form_field_setup(field, local_assigns) }

  def mock_translations(label_key, label_value, hint_value = nil, placeholder_value = nil)
    allow(helper).to receive(:t).with(label_key, raise: true).and_return(label_value)
    allow(helper).to receive(:t).with(/hints\.#{field}/, default: nil).and_return(hint_value)
    allow(helper).to receive(:t).with(/placeholders\.#{field}/, default: nil).and_return(placeholder_value)
  end

  describe "#form_field_setup" do
    shared_examples "detects form object and i18n base" do |expected_i18n_base|
      it "detects form object correctly" do
        expect(result[:form_object]).to eq(mock_form)
      end

      it "sets correct i18n base" do
        expect(result[:i18n_base]).to eq(expected_i18n_base)
      end
    end

    shared_examples "uses correct label key and value" do |label_key, label_value|
      before { mock_translations(label_key, label_value) }

      it "generates correct label" do
        expect(result[:field_label]).to eq(label_value)
      end
    end

    context "with proper setup using instance variables" do
      before do
        helper._current_form = mock_form
        helper._current_i18n_base = "inspector_companies.forms"
      end

      include_examples "detects form object and i18n base", "inspector_companies.forms"
      include_examples "uses correct label key and value", "inspector_companies.forms.fields.name", "Company Name"
    end

    context "when form is passed in local_assigns" do
      let(:local_assigns) { {form: mock_form} }

      before do
        helper._current_form = mock_form
        helper._current_i18n_base = "forms.test"
      end

      it "raises ArgumentError about disallowed keys" do
        expect { result }.to raise_error(ArgumentError, "local_assigns contains [:form]")
      end
    end

    context "when i18n_base is passed in local_assigns" do
      let(:local_assigns) { {i18n_base: "inspections.fields"} }

      before do
        helper._current_form = mock_form
        helper._current_i18n_base = "forms.test"
      end

      it "raises ArgumentError about disallowed keys" do
        expect { result }.to raise_error(ArgumentError, "local_assigns contains [:i18n_base]")
      end
    end

    context "when both form and i18n_base are passed in local_assigns" do
      let(:local_assigns) { {form: mock_form, i18n_base: "inspections.fields"} }

      before do
        helper._current_form = mock_form
        helper._current_i18n_base = "forms.test"
      end

      it "raises ArgumentError about disallowed keys" do
        expect { result }.to raise_error(ArgumentError, "local_assigns contains [:form, :i18n_base]")
      end
    end

    context "when label is passed in local_assigns" do
      let(:local_assigns) { {label: "Custom Label"} }

      before do
        helper._current_form = mock_form
        helper._current_i18n_base = "inspector_companies.forms"
      end

      it "raises ArgumentError about disallowed keys" do
        expect { result }.to raise_error(ArgumentError, "local_assigns contains [:label]")
      end
    end

    context "hint and placeholder handling" do
      before do
        helper._current_form = mock_form
        helper._current_i18n_base = "inspector_companies.forms"
      end

      it "looks up hints and placeholders when present" do
        mock_translations("inspector_companies.forms.fields.name", "Company Name", "Enter company name", "e.g. Acme Corp")

        expect(result[:field_hint]).to eq("Enter company name")
        expect(result[:field_placeholder]).to eq("e.g. Acme Corp")
      end

      it "returns nil for missing hints and placeholders" do
        mock_translations("inspector_companies.forms.fields.name", "Company Name", nil, nil)

        expect(result[:field_hint]).to be_nil
        expect(result[:field_placeholder]).to be_nil
      end
    end

    context "without @_current_i18n_base" do
      before do
        helper._current_form = mock_form
        helper._current_i18n_base = nil
      end

      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, "missing i18n_base")
      end
    end

    context "without @_current_form" do
      before do
        helper._current_form = nil
        helper._current_i18n_base = "forms.test"
      end

      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, "missing form_object")
      end
    end

    context "with missing i18n translation" do
      before do
        helper._current_form = mock_form
        helper._current_i18n_base = "forms.test"
        allow(helper).to receive(:t).with("forms.test.fields.name", raise: true).and_raise(I18n::MissingTranslationData.new(:en, "forms.test.fields.name"))
      end

      it "raises I18n::MissingTranslationData for missing label" do
        expect { result }.to raise_error(I18n::MissingTranslationData)
      end
    end

    context "with allowed local_assigns keys" do
      let(:local_assigns) { {min: 0, max: 100, step: 5, required: true} }

      before do
        helper._current_form = mock_form
        helper._current_i18n_base = "forms.test"
        mock_translations("forms.test.fields.name", "Test Name")
      end

      it "does not raise error for allowed keys" do
        expect { result }.not_to raise_error
      end
    end

    context "with mixed allowed and disallowed keys" do
      let(:local_assigns) { {min: 0, max: 100, form: mock_form} }

      before do
        helper._current_form = mock_form
        helper._current_i18n_base = "forms.test"
      end

      it "raises error only for disallowed keys" do
        expect { result }.to raise_error(ArgumentError, "local_assigns contains [:form]")
      end
    end

    context "with multiple disallowed keys including label" do
      let(:local_assigns) { {label: "Custom", i18n_base: "test", form: mock_form} }

      before do
        helper._current_form = mock_form
        helper._current_i18n_base = "forms.test"
      end

      it "raises error listing all disallowed keys" do
        expect { result }.to raise_error(ArgumentError, "local_assigns contains [:label, :i18n_base, :form]")
      end
    end
  end
end
