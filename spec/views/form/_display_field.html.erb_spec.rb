require "rails_helper"

RSpec.describe "form/_display_field.html.erb", type: :view do
  let(:user) { create(:user, :without_company, name: "Test User") }
  let(:form_object) { ActionView::Helpers::FormBuilder.new(:user, user, view, {}) }

  before do
    # Set up form context like fieldset would
    assign(:_current_form, form_object)
    assign(:_current_i18n_base, "users.forms")
  end

  it "renders display field with explicit value" do
    render "form/display_field",
      field: :name,
      value: "Custom Value"

    expect(rendered).to include("<label")
    expect(rendered).to include("Name")
    expect(rendered).to include("<p>")
    expect(rendered).to include("Custom Value")
  end

  it "renders display field using model value when no value provided" do
    render "form/display_field",
      field: :name

    expect(rendered).to include("<label")
    expect(rendered).to include("Name")
    expect(rendered).to include("<p>")
    expect(rendered).to include("Test User")
  end

  it "handles nil values gracefully" do
    render "form/display_field",
      field: :name,
      value: nil

    expect(rendered).to include("<label")
    expect(rendered).to include("Name")
    expect(rendered).to include("<p>")
    # Should not crash with nil value
  end
end
