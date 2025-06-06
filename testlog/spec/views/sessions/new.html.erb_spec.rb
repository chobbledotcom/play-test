require "rails_helper"

RSpec.describe "sessions/new.html.erb", type: :view do
  it "renders login form" do
    render

    expect(rendered).to have_content(I18n.t("session.login.title"))
    expect(rendered).to have_field(I18n.t("session.login.email_label"))
    expect(rendered).to have_field(I18n.t("session.login.password_label"))
    expect(rendered).to have_button(I18n.t("session.login.submit"))
  end

  it "displays login heading" do
    render

    expect(rendered).to have_content(I18n.t("session.login.title"))
  end

  it "includes remember me checkbox" do
    render

    expect(rendered).to have_content(I18n.t("session.login.remember_me"))
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
