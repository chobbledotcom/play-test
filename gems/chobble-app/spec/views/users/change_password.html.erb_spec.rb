require "rails_helper"

RSpec.describe "users/change_password.html.erb", type: :view do
  let(:user) { create(:chobble_app_user) }

  before do
    assign(:user, user)
    allow(view).to receive(:current_user).and_return(user)
  end

  it "renders password change form" do
    render

    expect(rendered).to have_content(I18n.t("users.titles.change_password"))
    expect(rendered).to have_field(I18n.t("users.forms.current_password"))
    expect(rendered).to have_field(I18n.t("users.forms.password"))
    expect(rendered).to have_field(I18n.t("users.forms.password_confirmation"))
    expect(rendered).to have_button(I18n.t("users.buttons.update_password"))
  end

  it "displays validation errors when present" do
    user.errors.add(:current_password, "is incorrect")
    user.errors.add(:password, "is too short")
    assign(:user, user)

    render

    expect(rendered).to include("is incorrect")
    expect(rendered).to include("is too short")
  end

  it "uses password input fields" do
    render

    expect(rendered).to have_field(I18n.t("users.forms.current_password"), type: "password")
    expect(rendered).to have_field(I18n.t("users.forms.password"), type: "password")
    expect(rendered).to have_field(I18n.t("users.forms.password_confirmation"), type: "password")
  end

  it "does not pre-fill password fields" do
    render

    # Password fields should be empty (nil or empty string)
    expect(rendered).to have_field(I18n.t("users.forms.current_password"))
    expect(rendered).to have_field(I18n.t("users.forms.password"))
    expect(rendered).to have_field(I18n.t("users.forms.password_confirmation"))

    # Verify they don't have any pre-filled values
    expect(rendered).not_to have_field(I18n.t("users.forms.current_password"), with: /\S/)
    expect(rendered).not_to have_field(I18n.t("users.forms.password"), with: /\S/)
    expect(rendered).not_to have_field(I18n.t("users.forms.password_confirmation"), with: /\S/)
  end
end
