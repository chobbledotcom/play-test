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

  it "includes time display preference" do
    render

    expect(rendered).to have_content("Time Display Format")
    expect(rendered).to have_select("user_time_display")
  end

  it "shows current time display setting" do
    render

    expect(rendered).to have_content("Time Display Format")
  end

  it "handles time display preference for time setting" do
    user.time_display = "time"
    assign(:user, user)

    render

    expect(rendered).to have_content("Time Display Format")
  end

  it "includes navigation links" do
    render

    expect(rendered).to have_content("Change Password")
  end

  it "displays validation errors when present" do
    user.errors.add(:time_display, "is not included in the list")
    assign(:user, user)

    render

    expect(rendered).to have_content("is not included in the list")
  end

  it "shows setting descriptions" do
    render

    expect(rendered).to have_content("Time Display Format")
  end

  it "includes user preferences section" do
    render

    expect(rendered).to have_content("Your Settings")
  end
end
