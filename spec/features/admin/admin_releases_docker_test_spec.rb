require "rails_helper"

RSpec.feature "Admin Releases Docker Section", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }

  scenario "hides Docker Images section from release body" do
    # Mock the raw API response
    release_body = "## Changes\n\nNew features\n\n" \
                   "## Docker Images\n\nDocker info here"
    release_url = "https://github.com/chobbledotcom/play-test/releases/v2.0.0"

    mock_response = double("response", code: "200", body: JSON.generate([
      {
        "name" => "Version 2.0.0",
        "tag_name" => "v2.0.0",
        "published_at" => 1.day.ago.iso8601,
        "body" => release_body,
        "html_url" => release_url,
        "author" => {"login" => "developer1"}
      }
    ]))

    allow(Rails.cache).to receive(:fetch).and_yield
    allow_any_instance_of(AdminController).to receive(:make_github_api_request)
      .and_return(mock_response)

    sign_in(admin_user)
    visit admin_releases_path

    expect(page).to have_content("Changes")
    expect(page).to have_content("New features")
    expect(page).not_to have_content("Docker Images")
    expect(page).not_to have_content("Docker info here")
  end
end
