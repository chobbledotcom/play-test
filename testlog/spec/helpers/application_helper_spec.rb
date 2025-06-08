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

    context "when current_user has date time_display preference" do
      let(:user) { double("User", time_display: "date") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "formats datetime with date only" do
        expect(helper.render_time(test_datetime)).to eq("Jun 06, 2025")
      end
    end

    context "when current_user has time time_display preference" do
      let(:user) { double("User", time_display: "time") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "formats datetime with date and time" do
        expect(helper.render_time(test_datetime)).to eq("Jun 06, 2025 - 14:30")
      end
    end

    context "when current_user has invalid time_display preference" do
      let(:user) { double("User", time_display: "invalid") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "falls back to default date format" do
        expect(helper.render_time(test_datetime)).to eq("Jun 06, 2025")
      end
    end

    context "when current_user has nil time_display preference" do
      let(:user) { double("User", time_display: nil) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "falls back to default date format" do
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

      it "returns full datetime" do
        result = helper.date_for_form(test_datetime)
        expect(result).to eq(test_datetime)
        expect(result).to be_a(Time)
      end
    end

    context "when current_user has date time_display preference" do
      let(:user) { double("User", time_display: "date") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "returns date only" do
        result = helper.date_for_form(test_datetime)
        expect(result).to eq(test_datetime.to_date)
        expect(result).to be_a(Date)
      end
    end

    context "when current_user has time time_display preference" do
      let(:user) { double("User", time_display: "time") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "returns full datetime" do
        result = helper.date_for_form(test_datetime)
        expect(result).to eq(test_datetime)
        expect(result).to be_a(Time)
      end
    end

    context "when current_user has invalid time_display preference" do
      let(:user) { double("User", time_display: "invalid") }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "returns full datetime" do
        result = helper.date_for_form(test_datetime)
        expect(result).to eq(test_datetime)
        expect(result).to be_a(Time)
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

  describe "TIME_FORMATS constant" do
    it "has correct date format" do
      expect(ApplicationHelper::TIME_FORMATS["date"]).to eq("%b %d, %Y")
    end

    it "has correct time format" do
      expect(ApplicationHelper::TIME_FORMATS["time"]).to eq("%b %d, %Y - %H:%M")
    end
  end

  describe "#form_field_setup" do
    let(:mock_form) { double("FormBuilder") }
    let(:field) { :name }
    let(:local_assigns) { {form: mock_form} }
    let(:result) { helper.form_field_setup(field, local_assigns) }

    before do
      helper.instance_variable_set(:@_current_form, mock_form)
    end

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

    context "with inspector_companies controller" do
      let(:local_assigns) { {form: mock_form, i18n_base: "inspector_companies.forms"} }

      include_examples "detects form object and i18n base", "inspector_companies.forms"
      include_examples "uses correct label key and value", "inspector_companies.forms.name", "Company Name"
    end

    context "with inspections controller and tab context" do
      let(:local_assigns) { {form: mock_form, i18n_base: "inspections.assessments.user_height.fields"} }

      include_examples "detects form object and i18n base", "inspections.assessments.user_height.fields"
      include_examples "uses correct label key and value", "inspections.assessments.user_height.fields.name", "Assessment Name"
    end

    context "with inspections controller but no tab" do
      let(:local_assigns) { {form: mock_form, i18n_base: "inspections.fields"} }

      include_examples "detects form object and i18n base", "inspections.fields"
      include_examples "uses correct label key and value", "inspections.fields.name", "Inspection Name"
    end

    context "with explicit label override" do
      let(:local_assigns) { {form: mock_form, label: "Custom Label", i18n_base: "inspector_companies.forms"} }

      it "uses explicit label instead of i18n lookup" do
        expect(result[:field_label]).to eq("Custom Label")
      end
    end

    context "with custom i18n_base override" do
      let(:local_assigns) { {form: mock_form, i18n_base: "custom.base"} }

      include_examples "detects form object and i18n base", "custom.base"
      include_examples "uses correct label key and value", "custom.base.name", "Custom Name"
    end

    context "without params context (view specs)" do
      let(:local_assigns) { {form: mock_form, i18n_base: "inspector_companies.forms"} }

      include_examples "detects form object and i18n base", "inspector_companies.forms"
      include_examples "uses correct label key and value", "inspector_companies.forms.name", "Company Name"
    end

    context "with @_current_form fallback" do
      let(:local_assigns) { {i18n_base: "test.forms"} }

      before do
        helper.instance_variable_set(:@_current_i18n_base, "test.forms")
        allow(helper).to receive(:t).with("test.forms.name", raise: true).and_return("Test Name")
        allow(helper).to receive(:t).with("test.hints.name", default: nil).and_return(nil)
        allow(helper).to receive(:t).with("test.placeholders.name", default: nil).and_return(nil)
      end

      it "uses @_current_form when no form passed in local_assigns" do
        expect(result[:form_object]).to eq(mock_form)
      end
    end

    context "hint and placeholder handling" do
      let(:local_assigns) { {form: mock_form, i18n_base: "inspector_companies.forms"} }

      it "looks up hints and placeholders when present" do
        mock_translations("inspector_companies.forms.name", "Company Name", "Enter company name", "e.g. Acme Corp")

        expect(result[:field_hint]).to eq("Enter company name")
        expect(result[:field_placeholder]).to eq("e.g. Acme Corp")
      end

      it "returns nil for missing hints and placeholders" do
        mock_translations("inspector_companies.forms.name", "Company Name", nil, nil)

        expect(result[:field_hint]).to be_nil
        expect(result[:field_placeholder]).to be_nil
      end
    end

    context "without i18n_base" do
      let(:local_assigns) { {form: mock_form} }

      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, "i18n_base is required for form field setup")
      end
    end

    context "with i18n_base from @_current_i18n_base" do
      let(:local_assigns) { {form: mock_form} }

      before do
        helper.instance_variable_set(:@_current_i18n_base, "units.forms")
        mock_translations("units.forms.name", "Unit Name")
      end

      it "uses @_current_i18n_base when i18n_base not in local_assigns" do
        setup = helper.form_field_setup(field, local_assigns, i18n_base: "units.forms")
        expect(setup[:i18n_base]).to eq("units.forms")
        expect(setup[:field_label]).to eq("Unit Name")
      end
    end

    context "with explicit hints and placeholders" do
      let(:local_assigns) { {form: mock_form, i18n_base: "test.forms", hint: "Custom hint", placeholder: "Custom placeholder"} }

      before do
        allow(helper).to receive(:t).with("test.forms.name", raise: true).and_return("Field Name")
      end

      it "uses explicit hint and placeholder over i18n lookups" do
        expect(result[:field_hint]).to eq("Custom hint")
        expect(result[:field_placeholder]).to eq("Custom placeholder")
      end
    end

    context "with missing i18n translation" do
      let(:local_assigns) { {form: mock_form, i18n_base: "test.forms"} }

      before do
        allow(helper).to receive(:t).with("test.forms.name", raise: true).and_raise(I18n::MissingTranslationData.new(:en, "test.forms.name"))
      end

      it "raises I18n::MissingTranslationData for missing label" do
        expect { result }.to raise_error(I18n::MissingTranslationData)
      end
    end

    context "with explicit label override for missing translation" do
      let(:local_assigns) { {form: mock_form, i18n_base: "test.forms", label: "Custom Label"} }

      it "uses explicit label and doesn't check i18n" do
        # Should not call t with raise: true when label is explicitly provided
        expect(helper).not_to receive(:t).with(anything, hash_including(raise: true))
        expect(result[:field_label]).to eq("Custom Label")
      end
    end
  end
end
