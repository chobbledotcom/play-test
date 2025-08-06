# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Error pages", type: :feature do
  around do |example|
    # Temporarily disable local request handling to test custom error pages
    original_value = Rails.application.config.consider_all_requests_local
    Rails.application.config.consider_all_requests_local = false
    example.run
  ensure
    Rails.application.config.consider_all_requests_local = original_value
  end

  scenario "404 page uses application layout for unknown routes" do
    visit "/non-existent-page-that-should-not-exist"

    expect(page.status_code).to eq(404)
    expect(page).to have_content(I18n.t("errors.not_found.title"))
    expect(page).to have_content(I18n.t("errors.not_found.message"))
  end

  scenario "404 page works for non-logged-in users" do
    # Ensure we're logged out
    visit "/logout"

    visit "/some-page-that-does-not-exist"

    expect(page.status_code).to eq(404)
    expect(page).to have_content(I18n.t("errors.not_found.title"))
    # Should not redirect to login page
    expect(page).not_to have_current_path(login_path)
  end
end
