require "rails_helper"

RSpec.feature "Admin Releases Changelog Link", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }

  scenario "removes [Read the full changelog here] links from release body" do
    # Mock the raw API response with changelog link
    changelog_link = "[Read the full changelog here]" \
                     "(https://example.com/changelog)"
    release_body = "## Changes\n\nNew features added\n\n" \
                   "#{changelog_link}\n\n" \
                   "## More Info\n\nAdditional details"

    mock_response = double("response", code: "200", body: JSON.generate([
      {
        "name" => "Version 3.0.0",
        "tag_name" => "v3.0.0",
        "published_at" => 1.day.ago.iso8601,
        "body" => release_body,
        "html_url" => "https://github.com/chobbledotcom/play-test/" \
                      "releases/v3.0.0",
        "author" => {"login" => "developer1"}
      }
    ]))

    allow(Rails.cache).to receive(:fetch).and_yield
    allow_any_instance_of(AdminController).to receive(:make_github_api_request)
      .and_return(mock_response)

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
