require "spec_helper"

RSpec.describe ChobbleForms do
  it "has a version number" do
    expect(ChobbleForms::VERSION).not_to be nil
  end

  it "defines the Engine class" do
    expect(ChobbleForms::Engine).to be < Rails::Engine
  end

  it "defines the Helpers module" do
    expect(ChobbleForms::Helpers).to be_a(Module)
  end

  describe "Helpers module" do
    let(:dummy_class) do
      Class.new do
        include ChobbleForms::Helpers
        attr_accessor :_current_form, :_current_i18n_base, :prefill_model

        def t(key, options = {})
          "Translated: #{key}"
        end
      end
    end

    # Mock for ActiveSupport present? method
    class Object
      def present?
        !nil? && !(respond_to?(:empty?) && empty?)
      end
    end

    let(:helper) { dummy_class.new }
    let(:form) { double("form", object: model) }
    let(:model) { double("model") }

    before do
      helper._current_form = form
      helper._current_i18n_base = "test.forms"
    end

    describe "#form_field_setup" do
      it "validates form context" do
        helper._current_form = nil
        expect {
          helper.form_field_setup(:name, {})
        }.to raise_error(ArgumentError, "missing form_object")
      end

      it "validates i18n base" do
        helper._current_i18n_base = nil
        expect {
          helper.form_field_setup(:name, {})
        }.to raise_error(ArgumentError, "missing i18n_base")
      end

      it "validates allowed local assigns" do
        expect {
          helper.form_field_setup(:name, {invalid_key: "value"})
        }.to raise_error(ArgumentError, /local_assigns contains \[:invalid_key\]/)
      end
    end

    describe "#radio_button_options" do
      it "returns checked hash when prefilled and values match" do
        result = helper.radio_button_options(true, "yes", "yes")
        expect(result).to eq({checked: true})
      end

      it "returns empty hash when not prefilled" do
        result = helper.radio_button_options(false, "yes", "yes")
        expect(result).to eq({})
      end

      it "returns empty hash when values don't match" do
        result = helper.radio_button_options(true, "yes", "no")
        expect(result).to eq({})
      end
    end
  end
end
