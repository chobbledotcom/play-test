require "rails_helper"

RSpec.describe "form/_display_field.html.erb", type: :view do
  context "with required parameters" do
    it "renders basic display field" do
      render "form/display_field",
        label: "Status",
        value: "Active"

      expect(rendered).to include('class="calculated-field"')
      expect(rendered).to include("<label>Status</label>")
      expect(rendered).to include('class="calculated-value"')
      expect(rendered).to include("Active")
    end
  end

  context "with custom parameters" do
    it "uses custom CSS classes" do
      render "form/display_field",
        label: "Status",
        value: "Active",
        css_class: "custom-field",
        value_class: "custom-value"

      expect(rendered).to include('class="custom-field"')
      expect(rendered).to include('class="custom-value"')
    end

    it "includes help text when provided" do
      render "form/display_field",
        label: "Reinspection Date",
        value: "2024-12-01",
        help_text: "Automatically calculated"

      expect(rendered).to include('<small class="help-text">Automatically calculated</small>')
    end

    it "omits help text when not provided" do
      render "form/display_field",
        label: "Status",
        value: "Active"

      expect(rendered).not_to include("help-text")
      expect(rendered).not_to include("<small")
    end
  end

  context "with complex values" do
    it "handles HTML in values" do
      render "form/display_field",
        label: "Link",
        value: '<a href="/test">Test Link</a>'.html_safe

      expect(rendered).to include('<a href="/test">Test Link</a>')
    end

    it "handles multiline values" do
      multiline_value = "Line 1\nLine 2\nLine 3"

      render "form/display_field",
        label: "Description",
        value: multiline_value

      expect(rendered).to include("Line 1")
      expect(rendered).to include("Line 2")
      expect(rendered).to include("Line 3")
    end

    it "handles empty values" do
      render "form/display_field",
        label: "Optional Field",
        value: ""

      expect(rendered).to include("<label>Optional Field</label>")
      expect(rendered).to include('class="calculated-value"')
      # Should not crash with empty value
    end

    it "handles nil values" do
      render "form/display_field",
        label: "Nullable Field",
        value: nil

      expect(rendered).to include("<label>Nullable Field</label>")
      expect(rendered).to include('class="calculated-value"')
      # Should not crash with nil value
    end
  end

  context "with interpolated values" do
    it "handles ERB expressions in values" do
      render "form/display_field",
        label: "Current Time",
        value: Time.current.strftime("%Y-%m-%d")

      expect(rendered).to include('class="calculated-field"')
      expect(rendered).to include(Time.current.strftime("%Y-%m-%d"))
    end
  end

  context "accessibility" do
    it "properly associates labels" do
      render "form/display_field",
        label: "Status",
        value: "Active"

      # Labels should be present for screen readers
      expect(rendered).to include("<label>Status</label>")
    end

    it "includes semantic HTML structure" do
      render "form/display_field",
        label: "Status",
        value: "Active"

      expect(rendered).to include('<div class="calculated-field">')
      expect(rendered).to include('<p class="calculated-value">')
    end
  end

  context "error handling" do
    it "requires label parameter" do
      expect {
        render "form/display_field", value: "test"
      }.to raise_error(ActionView::Template::Error, /label is required/)
    end

    it "handles missing value parameter" do
      render "form/display_field", label: "Test"

      expect(rendered).to include("<label>Test</label>")
      expect(rendered).to include('class="calculated-value"')
    end
  end

  context "with i18n integration" do
    it "works with translated labels" do
      render "form/display_field",
        label: I18n.t("inspections.fields.status", default: "Status"),
        value: "Active"

      expect(rendered).to include("<label>Status</label>")
    end

    it "works with translated values" do
      render "form/display_field",
        label: "Status",
        value: I18n.t("inspections.status.active", default: "Active")

      expect(rendered).to include("Active")
    end

    it "works with translated help text" do
      render "form/display_field",
        label: "Status",
        value: "Active",
        help_text: I18n.t("inspections.help.status", default: "Current status")

      expect(rendered).to include("Current status")
    end
  end
end
