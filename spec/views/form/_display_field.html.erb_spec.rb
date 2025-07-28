require "rails_helper"

RSpec.describe "chobble_forms/_display_field.html.erb", type: :view do
  let(:user) { create(:user, :without_company, name: "Test User") }
  let(:form_object) { ActionView::Helpers::FormBuilder.new(:user, user, view, {}) }

  before do
    # Set up form context like fieldset would
    assign(:_current_form, form_object)
    assign(:_current_i18n_base, "forms.user_settings")
  end

  it "renders display field using model value automatically" do
    render "chobble_forms/display_field",
      field: :name

    expect(rendered).to include("<label")
    expect(rendered).to include("Name")
    expect(rendered).to include("<p>")
    expect(rendered).to include("Test User")
  end

  it "handles nil values gracefully" do
    user_with_nil_phone = create(:user, :without_company, phone: nil)
    form_object_nil = ActionView::Helpers::FormBuilder.new(:user, user_with_nil_phone, view, {})
    assign(:_current_form, form_object_nil)

    render "chobble_forms/display_field",
      field: :phone

    expect(rendered).to include("<label")
    expect(rendered).to include("Phone")
    expect(rendered).to include("<p>")
    # Should not crash with nil value
  end
end
