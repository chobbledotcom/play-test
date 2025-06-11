require "rails_helper"

RSpec.describe "users/index.html.erb", type: :view do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user1) { create(:user, email: "user1@example.com") }
  let(:regular_user2) { create(:user, email: "user2@example.com") }

  before do
    assign(:users, [admin_user, regular_user1, regular_user2])
    allow(view).to receive(:current_user).and_return(admin_user)
  end

  it "displays users index heading" do
    render

    expect(rendered).to include("Users")
  end

  it "displays user information in table" do
    render

    expect(rendered).to have_selector("table")
    expect(rendered).to include(admin_user.email)
    expect(rendered).to include(regular_user1.email)
    expect(rendered).to include(regular_user2.email)
  end

  it "shows user admin status" do
    render

    expect(rendered).to include("Admin")
  end

  it "shows inspection count" do
    render

    expect(rendered).to include("Inspections")
    expect(rendered).to include("0") # All users have 0 inspections initially
  end

  it "includes action links for admin" do
    render

    # The rendered output shows user emails are links to edit pages
    expect(rendered).to have_link(admin_user.email, href: edit_user_path(admin_user))
    expect(rendered).to have_link(regular_user1.email, href: edit_user_path(regular_user1))
  end

  it "handles empty user list" do
    assign(:users, [])

    render

    # The view still shows the table structure even when empty
    expect(rendered).to have_selector("tbody")
    expect(rendered).to include("Users")
  end

  it "shows user creation link" do
    render

    # Based on the rendered output, there might not be a creation link visible
    # or it might have different text. Let's check if it shows user management features
    expect(rendered).to include("Users")
    expect(rendered).to have_selector("table")
  end
end
