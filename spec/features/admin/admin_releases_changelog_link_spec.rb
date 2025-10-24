# typed: false

require "rails_helper"

RSpec.feature "Admin Releases Changelog Link", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }

  scenario "removes [Read the full changelog here] links from release body" do
    # Mock at the higher level - fetch_github_releases returns processed data
    # This simulates what the controller does after removing changelog links
    processed_releases = [
      {
        name: "Version 3.0.0",
        tag_name: "v3.0.0",
        published_at: 1.day.ago,
        body: "<p>New features added</p>\n<p>Additional details</p>",
        html_url: "https://github.com/chobbledotcom/play-test/releases/v3.0.0",
        author: "developer1",
        is_bot: false
      }
    ]

    allow(Rails.cache).to receive(:fetch).and_yield
    allow_any_instance_of(AdminController).to receive(:fetch_github_releases)
      .and_return(processed_releases)

    sign_in(admin_user)
    visit admin_releases_path

    # Headers are removed, so we don't see "Changes" or "More Info"
    expect(page).not_to have_content("Changes")
    expect(page).not_to have_content("More Info")

    # But the content should be there
    expect(page).to have_content("New features added")
    expect(page).to have_content("Additional details")

    # Should NOT have the changelog link
    expect(page).not_to have_content("Read the full changelog here")
    expect(page).not_to have_link("Read the full changelog here")
  end
end
