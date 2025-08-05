require "rails_helper"

RSpec.feature "Admin Releases", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :active_user) }

  let(:sample_releases) do
    [
      {
        name: "Version 1.2.0",
        tag_name: "v1.2.0",
        published_at: 2.days.ago,
        body: "## Changes\n- New feature X\n- Bug fix Y",
        html_url: "https://github.com/chobbledotcom/play-test/releases/v1.2.0",
        author: "developer1"
      },
      {
        name: "Version 1.1.0",
        tag_name: "v1.1.0",
        published_at: 1.week.ago,
        body: "Initial release",
        html_url: "https://github.com/chobbledotcom/play-test/releases/v1.1.0",
        author: "developer2"
      }
    ]
  end

  before do
    allow(Rails.cache).to receive(:fetch).and_yield
    allow_any_instance_of(AdminController).to receive(:fetch_github_releases)
      .and_return(sample_releases)
  end

  scenario "admin can view releases page" do
    sign_in(admin_user)
    visit admin_path

    click_link I18n.t("navigation.releases")

    expect(page).to have_content(I18n.t("admin.releases.title"))
    expect(page).to have_link(I18n.t("admin.back_to_admin"))

    # Check first release
    first_release_url = sample_releases[0][:html_url]
    expect(page).to have_link("Version 1.2.0", href: first_release_url)
    expect(page).to have_content("developer1")
    expect(page).to have_content("New feature X")
    expect(page).to have_content("Bug fix Y")

    # Check second release
    second_release_url = sample_releases[1][:html_url]
    expect(page).to have_link("Version 1.1.0", href: second_release_url)
    expect(page).to have_content("developer2")
    expect(page).to have_content("Initial release")
  end

  scenario "regular user cannot access releases page" do
    sign_in(regular_user)
    visit admin_releases_path

    admin_required_msg = I18n.t("forms.session_new.status.admin_required")
    expect(page).to have_content(admin_required_msg)
    expect(current_path).to eq(root_path)
  end

  scenario "shows message when no releases are found" do
    allow_any_instance_of(AdminController).to receive(:fetch_github_releases)
      .and_return([])

    sign_in(admin_user)
    visit admin_releases_path

    expect(page).to have_content(I18n.t("admin.releases.no_releases"))
  end

  scenario "shows error message when fetching fails" do
    allow(Rails.cache).to receive(:fetch).and_raise(StandardError, "API Error")

    sign_in(admin_user)
    visit admin_releases_path

    expect(page).to have_content(I18n.t("admin.releases.fetch_error"))
  end

  scenario "uses caching for releases data" do
    expect(Rails.cache).to receive(:fetch)
      .with("github_releases", expires_in: 1.hour)
      .and_yield

    sign_in(admin_user)
    visit admin_releases_path
  end
end
