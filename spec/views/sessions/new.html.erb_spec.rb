require "rails_helper"

RSpec.describe "sessions/new.html.erb", type: :view do
  it "renders login form" do
    render

    # Use helper to verify entire form matches i18n structure
    expect_standard_form_structure("forms.session_new")
  end

  it "displays login heading" do
    render

    expect(rendered).to have_content(I18n.t("forms.session_new.header"))
  end

  it "includes remember me checkbox" do
    render

    expect(rendered).to have_content(I18n.t("forms.session_new.fields.remember_me"))
    expect(rendered).to have_field(type: "checkbox")
  end

  it "uses email input type" do
    render

    expect(rendered).to include('type="email"')
  end

  it "uses password input type" do
    render

    expect(rendered).to include('type="password"')
  end

  it "includes form structure" do
    render

    expect(rendered).to include("login")
    expect(rendered).to include("submit")
  end
end
