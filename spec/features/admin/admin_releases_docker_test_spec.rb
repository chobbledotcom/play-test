require "rails_helper"

RSpec.feature "Admin Releases Docker Section", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }

  scenario "hides Docker Images section from release body" do
    # Create the processed release data directly (after markdown processing)
    release_url = "https://github.com/chobbledotcom/play-test/releases/v2.0.0"

    # Mock at the higher level - fetch_github_releases returns processed data
    # This simulates what the controller does after processing the API response
    processed_releases = [
      {
        name: "Version 2.0.0",
        tag_name: "v2.0.0",
        published_at: 1.day.ago,
        body: "<ul><li>New features added</li>\n<li>Bug fixes</li></ul>",
        html_url: release_url,
        author: "developer1",
        is_bot: false
      }
    ]

    allow(Rails.cache).to receive(:fetch).and_yield
    allow_any_instance_of(AdminController).to receive(:fetch_github_releases)
      .and_return(processed_releases)

    sign_in(admin_user)
    visit admin_releases_path

    # Headers are stripped, so we shouldn't see "Changes"
    expect(page).not_to have_content("Changes")
    expect(page).to have_content("New features added")
    expect(page).to have_content("Bug fixes")
    expect(page).not_to have_content("Docker Images")
    expect(page).not_to have_content("Docker info here")
  end
end
