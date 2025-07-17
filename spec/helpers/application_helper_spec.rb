require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  let(:test_datetime) { Time.zone.parse("2025-06-06 14:30:45") }

  describe "#render_time" do
    context "when datetime is nil" do
      it "returns nil" do
        expect(helper.render_time(nil)).to be_nil
      end
    end

    context "when current_user is nil" do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it "uses default date format" do
        expect(helper.render_time(test_datetime)).to eq("Jun 06, 2025")
      end
    end

    context "when current_user is present" do
      let(:user) { double("User") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "formats datetime with date only" do
        expect(helper.render_time(test_datetime)).to eq("Jun 06, 2025")
      end
    end
  end

  describe "#date_for_form" do
    context "when datetime is nil" do
      it "returns nil" do
        expect(helper.date_for_form(nil)).to be_nil
      end
    end

    context "when current_user is nil" do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it "returns date only" do
        result = helper.date_for_form(test_datetime)
        expect(result).to eq(test_datetime.to_date)
        expect(result).to be_a(Date)
      end
    end

    context "when current_user is present" do
      let(:user) { double("User") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "returns date only" do
        result = helper.date_for_form(test_datetime)
        expect(result).to eq(test_datetime.to_date)
        expect(result).to be_a(Date)
      end
    end
  end

  describe "#scrollable_table" do
    it "creates a scrollable table container with default options" do
      result = helper.scrollable_table do
        content_tag(:tr, "test content")
      end

      expect(result).to include('<div class="table-container">')
      expect(result).to include("<table>")
      expect(result).to include("<tr>test content</tr>")
      expect(result).to include("</table>")
      expect(result).to include("</div>")
    end

    it "creates a scrollable table container with custom HTML options" do
      result = helper.scrollable_table(class: "custom-table", id: "my-table") do
        content_tag(:tr, "test content")
      end

      expect(result).to include('<div class="table-container">')
      expect(result).to include('<table class="custom-table" id="my-table">')
      expect(result).to include("<tr>test content</tr>")
      expect(result).to include("</table>")
      expect(result).to include("</div>")
    end

    it "handles empty table content" do
      result = helper.scrollable_table do
        ""
      end

      expect(result).to include('<div class="table-container">')
      expect(result).to include("<table>")
      expect(result).to include("</table>")
      expect(result).to include("</div>")
    end

    it "passes through multiple HTML options" do
      result = helper.scrollable_table(
        :class => "table table-striped",
        :id => "data-table",
        "data-sortable" => "true"
      ) do
        content_tag(:thead, content_tag(:tr, content_tag(:th, "Header")))
      end

      expect(result).to include('class="table table-striped"')
      expect(result).to include('id="data-table"')
      expect(result).to include('data-sortable="true"')
      expect(result).to include("<th>Header</th>")
    end
  end

  describe "#form_field_setup" do
    let(:mock_form) { double("FormBuilder", object: nil) }
    let(:field) { :name }
    let(:local_assigns) { {} }
    let(:result) { helper.form_field_setup(field, local_assigns) }

    def mock_translations(label_key, label_value, hint_value = nil, placeholder_value = nil)
      allow(helper).to receive(:t).with(label_key, raise: true).and_return(label_value)
      allow(helper).to receive(:t).with(/hints\.#{field}/, default: nil).and_return(hint_value)
      allow(helper).to receive(:t).with(/placeholders\.#{field}/, default: nil).and_return(placeholder_value)
    end

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
        helper.instance_variable_set(:@_current_form, mock_form)
        helper.instance_variable_set(:@_current_i18n_base, "inspector_companies.forms")
      end

      include_examples "detects form object and i18n base", "inspector_companies.forms"
      include_examples "uses correct label key and value", "inspector_companies.forms.fields.name", "Company Name"
    end

    context "when form is passed in local_assigns" do
      let(:local_assigns) { {form: mock_form} }

      before do
        helper.instance_variable_set(:@_current_form, mock_form)
        helper.instance_variable_set(:@_current_i18n_base, "forms.test")
      end

      it "raises ArgumentError about disallowed keys" do
        expect { result }.to raise_error(ArgumentError, "local_assigns contains [:form]")
      end
    end

    context "when i18n_base is passed in local_assigns" do
      let(:local_assigns) { {i18n_base: "inspections.fields"} }

      before do
        helper.instance_variable_set(:@_current_form, mock_form)
        helper.instance_variable_set(:@_current_i18n_base, "forms.test")
      end

      it "raises ArgumentError about disallowed keys" do
        expect { result }.to raise_error(ArgumentError, "local_assigns contains [:i18n_base]")
      end
    end

    context "when both form and i18n_base are passed in local_assigns" do
      let(:local_assigns) { {form: mock_form, i18n_base: "inspections.fields"} }

      before do
        helper.instance_variable_set(:@_current_form, mock_form)
        helper.instance_variable_set(:@_current_i18n_base, "forms.test")
      end

      it "raises ArgumentError about disallowed keys" do
        expect { result }.to raise_error(ArgumentError, "local_assigns contains [:form, :i18n_base]")
      end
    end

    context "when label is passed in local_assigns" do
      let(:local_assigns) { {label: "Custom Label"} }

      before do
        helper.instance_variable_set(:@_current_form, mock_form)
        helper.instance_variable_set(:@_current_i18n_base, "inspector_companies.forms")
      end

      it "raises ArgumentError about disallowed keys" do
        expect { result }.to raise_error(ArgumentError, "local_assigns contains [:label]")
      end
    end

    context "hint and placeholder handling" do
      before do
        helper.instance_variable_set(:@_current_form, mock_form)
        helper.instance_variable_set(:@_current_i18n_base, "inspector_companies.forms")
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
        helper.instance_variable_set(:@_current_form, mock_form)
        helper.instance_variable_set(:@_current_i18n_base, nil)
      end

      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, "missing i18n_base")
      end
    end

    context "without @_current_form" do
      before do
        helper.instance_variable_set(:@_current_form, nil)
        helper.instance_variable_set(:@_current_i18n_base, "forms.test")
      end

      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, "missing form_object")
      end
    end

    context "with missing i18n translation" do
      before do
        helper.instance_variable_set(:@_current_form, mock_form)
        helper.instance_variable_set(:@_current_i18n_base, "forms.test")
        allow(helper).to receive(:t).with("forms.test.fields.name", raise: true).and_raise(I18n::MissingTranslationData.new(:en, "forms.test.fields.name"))
      end

      it "raises I18n::MissingTranslationData for missing label" do
        expect { result }.to raise_error(I18n::MissingTranslationData)
      end
    end

    context "with allowed local_assigns keys" do
      let(:local_assigns) { {min: 0, max: 100, step: 5, required: true} }

      before do
        helper.instance_variable_set(:@_current_form, mock_form)
        helper.instance_variable_set(:@_current_i18n_base, "forms.test")
        mock_translations("forms.test.fields.name", "Test Name")
      end

      it "does not raise error for allowed keys" do
        expect { result }.not_to raise_error
      end
    end

    context "with mixed allowed and disallowed keys" do
      let(:local_assigns) { {min: 0, max: 100, form: mock_form} }

      before do
        helper.instance_variable_set(:@_current_form, mock_form)
        helper.instance_variable_set(:@_current_i18n_base, "forms.test")
      end

      it "raises error only for disallowed keys" do
        expect { result }.to raise_error(ArgumentError, "local_assigns contains [:form]")
      end
    end

    context "with multiple disallowed keys including label" do
      let(:local_assigns) { {label: "Custom", i18n_base: "test", form: mock_form} }

      before do
        helper.instance_variable_set(:@_current_form, mock_form)
        helper.instance_variable_set(:@_current_i18n_base, "forms.test")
      end

      it "raises error listing all disallowed keys" do
        expect { result }.to raise_error(ArgumentError, "local_assigns contains [:label, :i18n_base, :form]")
      end
    end
  end

  describe "#format_numeric_value" do
    context "with numeric values" do
      it "removes trailing zeros from decimal values" do
        expect(helper.format_numeric_value(5.0)).to eq("5")
        expect(helper.format_numeric_value(5.10)).to eq("5.1")
        expect(helper.format_numeric_value(5.012000)).to eq("5.012")
        expect(helper.format_numeric_value(-3.50)).to eq("-3.5")
      end

      it "preserves significant digits" do
        expect(helper.format_numeric_value(5.123)).to eq("5.123")
        expect(helper.format_numeric_value(0.5)).to eq("0.5")
        expect(helper.format_numeric_value(-0.25)).to eq("-0.25")
      end

      it "handles integers" do
        expect(helper.format_numeric_value(5)).to eq("5")
        expect(helper.format_numeric_value(-10)).to eq("-10")
        expect(helper.format_numeric_value(0)).to eq("0")
      end
    end

    context "with string values" do
      it "formats valid numeric strings" do
        expect(helper.format_numeric_value("5.0")).to eq("5")
        expect(helper.format_numeric_value("5.012000")).to eq("5.012")
        expect(helper.format_numeric_value("-3.50")).to eq("-3.5")
        expect(helper.format_numeric_value("0.5")).to eq("0.5")
      end

      it "handles integer strings" do
        expect(helper.format_numeric_value("5")).to eq("5")
        expect(helper.format_numeric_value("-10")).to eq("-10")
      end

      it "returns non-numeric strings unchanged" do
        expect(helper.format_numeric_value("not a number")).to eq("not a number")
        expect(helper.format_numeric_value("abc123")).to eq("abc123")
        expect(helper.format_numeric_value("")).to eq("")
      end
    end

    context "with nil and other types" do
      it "returns nil unchanged" do
        expect(helper.format_numeric_value(nil)).to eq(nil)
      end

      it "returns other types unchanged" do
        expect(helper.format_numeric_value(true)).to eq(true)
        expect(helper.format_numeric_value(false)).to eq(false)
        expect(helper.format_numeric_value([])).to eq([])
        expect(helper.format_numeric_value({})).to eq({})
      end
    end

    context "with edge cases" do
      it "handles very small numbers" do
        expect(helper.format_numeric_value(0.001)).to eq("0.001")
        expect(helper.format_numeric_value(0.0010)).to eq("0.001")
      end

      it "handles very large numbers" do
        expect(helper.format_numeric_value(1000000.0)).to eq("1000000")
        expect(helper.format_numeric_value(1000000.50)).to eq("1000000.5")
      end

      it "handles scientific notation conversion" do
        # Ruby may convert very large/small numbers to scientific notation
        # Our formatter should handle the string representation correctly
        large_num = 1e10
        expect(helper.format_numeric_value(large_num)).to be_a(String)
      end
    end
  end
end
