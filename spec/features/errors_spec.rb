# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Error pages", type: :feature do
  context "when simulating production error handling" do
    around do |example|
      # Temporarily configure Rails to handle errors like production
      # This is necessary because in development/test, Rails shows debug pages
      original_local = Rails.application.config.consider_all_requests_local
      original_exceptions = Rails.application.config.action_dispatch.show_exceptions

      # These settings make Rails use the exceptions_app (our custom error pages)
      Rails.application.config.consider_all_requests_local = false
      Rails.application.config.action_dispatch.show_exceptions = true

      example.run
    ensure
      Rails.application.config.consider_all_requests_local = original_local
      Rails.application.config.action_dispatch.show_exceptions = original_exceptions
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

  context "when visiting the direct 404 route" do
    # This tests the route that would be used by the exceptions_app
    scenario "404 route displays error page without authentication" do
      visit "/404"

      expect(page.status_code).to eq(404)
      expect(page).to have_content(I18n.t("errors.not_found.title"))
      expect(page).to have_content(I18n.t("errors.not_found.message"))
    end
  end
end
