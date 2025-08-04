require "rails_helper"

RSpec.describe "users/change_settings.html.erb", type: :view do
  let(:user) { create(:user) }

  before do
    assign(:user, user)
    allow(view).to receive(:current_user).and_return(user)
  end

  it "renders settings change form" do
    render

    expect(rendered).to have_content("Your Settings")
    expect(rendered).to have_button("Update Settings")
  end

  it "includes navigation links" do
    render

    expect(rendered).to have_content("Change Password")
  end

  it "displays validation errors when present" do
    user.errors.add(:theme, "is not included in the list")
    assign(:user, user)

    render

    expect(rendered).to have_content("is not included in the list")
  end

  it "includes user preferences section" do
    render

    expect(rendered).to have_content("Your Settings")
  end

  it "displays name as read-only for users without company" do
    user.update!(inspection_company: nil)
    assign(:user, user)

    render

    # Name should be displayed but not editable
    expect(rendered).to have_content(user.name)
    expect(rendered).not_to have_field("user_name")
    expect(rendered).not_to have_field("Name")
  end

  it "displays all contact details as read-only for users with company" do
    company = create(:inspector_company)
    user.update!(inspection_company: company)
    assign(:user, user)

    render

    # All contact details should be read-only
    expect(rendered).to have_content(user.name)
    expect(rendered).not_to have_field("user_name")
    expect(rendered).not_to have_field("user_phone")
    expect(rendered).not_to have_field("user_address")
    expect(rendered).to have_content("These details are inherited from your company")
  end
end
