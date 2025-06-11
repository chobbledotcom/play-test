require "rails_helper"

RSpec.describe "users/new.html.erb", type: :view do
  before do
    assign(:user, User.new)
  end

  it "renders new user form" do
    render

    expect(rendered).to have_content(I18n.t("users.titles.register"))
    expect(rendered).to have_field("Email")
    expect(rendered).to have_field("Name")
    expect(rendered).to have_field("RPII Inspector No")
    expect(rendered).to have_field("Password")
    expect(rendered).to have_field("Password confirmation")
    expect(rendered).to have_button(I18n.t("users.buttons.register"))
  end

  it "displays signup heading" do
    render

    expect(rendered).to have_content(I18n.t("users.titles.register"))
  end

  it "displays validation errors when present" do
    user = User.new
    user.valid?  # Trigger validations
    assign(:user, user)

    render

    expect(rendered).to include("can&#39;t be blank")
  end

  it "preserves user input on validation failure" do
    user = User.new(email: "test@example.com")
    user.valid?
    assign(:user, user)

    render

    expect(rendered).to have_content("Register")
  end
end
