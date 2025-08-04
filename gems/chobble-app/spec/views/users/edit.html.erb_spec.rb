require "rails_helper"

RSpec.describe "users/edit.html.erb", type: :view do
  let(:admin_user) { create(:chobble_app_user, :admin) }
  let(:user_to_edit) { create(:chobble_app_user) }

  before do
    assign(:user, user_to_edit)
    allow(view).to receive(:current_user).and_return(admin_user)
  end

  it "renders edit user form" do
    render

    expect(rendered).to have_content("Edit User")
    expect(rendered).to have_field("Email")
    expect(rendered).to have_button("Update User")
  end

  it "includes admin-only fields for admin users" do
    render

    # Admin users should see name field and other admin controls
    expect(rendered).to have_field("Name")
    expect(rendered).to have_field("RPII Inspector No")

    if ENV["SIMPLE_USER_ACTIVATION"] == "true"
      # Check for activation status display instead of field
      expect(rendered).to have_content(I18n.t("users.labels.activated_at")) ||
        have_content(I18n.t("users.labels.deactivated_at"))
    else
      expect(rendered).to have_field("Active Until")
    end

    expect(rendered).to have_select("Inspection Company")
    expect(rendered).to have_button("Delete")
  end

  it "includes navigation links" do
    render

    expect(rendered).to have_button("Delete")
  end

  it "displays validation errors when present" do
    user_to_edit.errors.add(:email, "is invalid")
    assign(:user, user_to_edit)

    render

    expect(rendered).to include("is invalid")
  end

  it "preserves form values on validation failure" do
    user_to_edit.email = "invalid-email"
    assign(:user, user_to_edit)

    render

    expect(rendered).to have_content("Edit User")
  end

  it "shows password fields" do
    render

    expect(rendered).to have_content("New Password")
    expect(rendered).to have_content("Password confirmation")
  end
end
