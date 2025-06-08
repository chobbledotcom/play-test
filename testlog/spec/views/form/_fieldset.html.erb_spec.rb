require "rails_helper"

RSpec.describe "form/_fieldset.html.erb", type: :view do
  let(:base_i18n_key) { "test.forms" }

  # Helper method to test fieldset functionality via wrapper template
  def render_fieldset_test(locals = {}, content = "Sample field content")
    assign(:locals, locals)
    assign(:content, content)
    render template: "test_fieldset_wrapper"
  end

  before do
    # Set current i18n base for fallback
    view.instance_variable_set(:@_current_i18n_base, base_i18n_key)
  end

  describe "basic rendering" do
    it "renders a semantic fieldset element with default legend" do
      render_fieldset_test

      expect(rendered).to have_css("fieldset.form-section") do |fieldset|
        expect(fieldset).to have_css("legend", text: "Section")
      end
      expect(rendered).to include("Sample field content")
    end

    it "yields content inside fieldset" do
      render_fieldset_test({}, "Custom form content")

      expect(rendered).to have_css("fieldset")
      expect(rendered).to include("Custom form content")
    end

    it "maintains correct element order" do
      render_fieldset_test({}, "Content here")
      expect(rendered).to match(/<fieldset.*?><legend.*?>.*?<\/legend>.*Content here.*<\/fieldset>/m)
    end
  end

  describe "legend text generation" do
    context "with explicit legend text" do
      it "uses provided legend text directly" do
        render_fieldset_test({ legend: "Custom Legend" }, "Content")

        expect(rendered).to have_css("fieldset legend", text: "Custom Legend")
      end

      it "handles empty legend text by not rendering legend" do
        render_fieldset_test({ legend: "" }, "Content")

        expect(rendered).not_to have_css("legend")
        expect(rendered).to have_css("fieldset")
      end

      it "handles nil legend text by not rendering legend" do
        render_fieldset_test({ legend: nil }, "Content")

        expect(rendered).not_to have_css("legend")
        expect(rendered).to have_css("fieldset")
      end
    end

    context "with legend_key and i18n lookup" do
      it "looks up legend text using i18n key" do
        allow(view).to receive(:t)
          .with("test.sections.safety_checks", default: "Safety Checks")
          .and_return("Safety Checks")

        content = render(partial: "form/fieldset", locals: {
          legend_key: "safety_checks",
          i18n_base: "test.forms"
        }) { "Content" }

        expect(content).to have_css("fieldset legend", text: "Safety Checks")
        expect(view).to have_received(:t).with("test.sections.safety_checks", default: "Safety Checks")
      end

      it "strips .fields suffix from i18n_base for sections lookup" do
        allow(view).to receive(:t)
          .with("inspections.assessments.slide.sections.structure", default: "Structure")
          .and_return("Structure Checks")

        content = render(partial: "form/fieldset", locals: {
          legend_key: "structure",
          i18n_base: "inspections.assessments.slide.fields"
        }) { "Content" }

        expect(content).to have_css("fieldset legend", text: "Structure Checks")
      end

      it "falls back to @_current_i18n_base when i18n_base not provided" do
        allow(view).to receive(:t)
          .with("test.sections.equipment", default: "Equipment")
          .and_return("Equipment Details")

        content = render(partial: "form/fieldset", locals: {legend_key: "equipment"}) { "Content" }

        expect(content).to have_css("fieldset legend", text: "Equipment Details")
      end
    end

    context "with legend_key but no i18n_base" do
      before do
        view.instance_variable_set(:@_current_i18n_base, nil)
      end

      it "humanizes legend_key when no i18n_base available" do
        content = render(partial: "form/fieldset", locals: {legend_key: "safety_requirements"}) { "Content" }

        expect(content).to have_css("fieldset legend", text: "Safety requirements")
      end

      it "handles symbol legend_key" do
        content = render(partial: "form/fieldset", locals: {legend_key: :equipment_details}) { "Content" }

        expect(content).to have_css("fieldset legend", text: "Equipment details")
      end
    end
  end

  describe "CSS customization" do
    it "applies custom CSS class to fieldset" do
      content = render(partial: "form/fieldset", locals: {css_class: "assessment-section"}) { "Content" }

      expect(content).to have_css("fieldset.assessment-section")
      expect(content).not_to have_css("fieldset.form-section")
    end

    it "supports multiple CSS classes" do
      content = render(partial: "form/fieldset", locals: {css_class: "form-section highlight bordered"}) { "Content" }

      expect(content).to have_css("fieldset.form-section.highlight.bordered")
    end

    it "uses default CSS class when none provided" do
      content = render(partial: "form/fieldset") { "Content" }

      expect(content).to have_css("fieldset.form-section")
    end
  end

  describe "content yielding" do
    it "preserves HTML markup in yielded content" do
      html_content = '<div class="form-field"><label>Test</label><input type="text" /></div>'

      content = render(partial: "form/fieldset") { html_content.html_safe }

      expect(content).to have_css("fieldset") do |fieldset|
        expect(fieldset).to have_css("div.form-field")
        expect(fieldset).to have_css("label", text: "Test")
        expect(fieldset).to have_css("input[type='text']")
      end
    end

    it "handles empty content" do
      content = render(partial: "form/fieldset") { "" }

      expect(content).to have_css("fieldset legend", text: "Section")
      expect(content).to have_css("fieldset")
    end
  end

  describe "real-world usage scenarios" do
    shared_examples "fieldset for assessment section" do |section_key, expected_legend, i18n_base|
      it "renders #{section_key} section correctly" do
        # Mock the translation
        sections_base = i18n_base.sub(/\.fields$/, "")
        allow(view).to receive(:t)
          .with("#{sections_base}.sections.#{section_key}", default: section_key.to_s.humanize)
          .and_return(expected_legend)

        content = render(partial: "form/fieldset", locals: {
          legend_key: section_key,
          i18n_base: i18n_base
        }) { "Assessment fields for #{section_key}" }

        expect(content).to have_css("fieldset.form-section") do |fieldset|
          expect(fieldset).to have_css("legend", text: expected_legend)
          expect(fieldset).to include("Assessment fields for #{section_key}")
        end
      end
    end

    include_examples "fieldset for assessment section", "structure", "Structure Assessment", "inspections.assessments.slide.fields"
    include_examples "fieldset for assessment section", "safety", "Safety Requirements", "inspections.assessments.user_height.fields"
    include_examples "fieldset for assessment section", "materials", "Materials Inspection", "inspections.assessments.materials.fields"
    include_examples "fieldset for assessment section", "documentation", "Documentation", "inspector_companies.forms.fields"
  end

  describe "edge cases and error handling" do
    it "handles missing i18n translation gracefully" do
      allow(view).to receive(:t)
        .with("test.sections.nonexistent", default: "Nonexistent")
        .and_return("Nonexistent")

      content = render(partial: "form/fieldset", locals: {
        legend_key: "nonexistent",
        i18n_base: "test.forms"
      }) { "Content" }

      expect(content).to have_css("fieldset legend", text: "Nonexistent")
    end

    it "handles nil legend_key" do
      content = render(partial: "form/fieldset", locals: {legend_key: nil}) { "Content" }

      expect(content).to have_css("fieldset legend", text: "Section")
    end

    it "handles complex i18n_base with multiple dots" do
      allow(view).to receive(:t)
        .with("app.admin.users.sections.permissions", default: "Permissions")
        .and_return("User Permissions")

      content = render(partial: "form/fieldset", locals: {
        legend_key: "permissions",
        i18n_base: "app.admin.users.fields"
      }) { "Content" }

      expect(content).to have_css("fieldset legend", text: "User Permissions")
    end

    it "preserves original i18n_base when no .fields suffix present" do
      allow(view).to receive(:t)
        .with("simple.sections.basic", default: "Basic")
        .and_return("Basic Section")

      content = render(partial: "form/fieldset", locals: {
        legend_key: "basic",
        i18n_base: "simple"
      }) { "Content" }

      expect(content).to have_css("fieldset legend", text: "Basic Section")
    end
  end

  describe "accessibility and semantic structure" do
    it "uses proper semantic HTML5 fieldset structure" do
      content = render(partial: "form/fieldset", locals: {legend: "Accessibility Test"}) { "Content" }

      expect(content).to have_css("fieldset")
      expect(content).to have_css("fieldset > legend")
    end

    it "associates legend with fieldset content" do
      html_content = '<input type="text" name="test_field" />'
      content = render(partial: "form/fieldset", locals: {legend: "Form Section"}) { html_content.html_safe }

      # The legend should be the first child of fieldset for proper association
      expect(content).to match(/<fieldset[^>]*><legend[^>]*>Form Section<\/legend>.*<input[^>]*>.*<\/fieldset>/m)
    end

    it "supports ARIA attributes through CSS classes" do
      content = render(partial: "form/fieldset", locals: {
        css_class: "form-section required"
      }) { "Required fields section" }

      expect(content).to have_css("fieldset.form-section.required")
    end
  end
end
