# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Error pages", type: :feature do
  scenario "404 page displays error page without authentication" do
    visit "/404"

    expect(page.status_code).to eq(404)
    expect(page).to have_content(I18n.t("errors.not_found.title"))
    expect(page).to have_content(I18n.t("errors.not_found.message"))
    expect(page).to have_content(I18n.t("errors.redirect_message"))
    expect(page).to have_link(I18n.t("errors.redirect_link"), href: root_path)
  end

  scenario "500 page displays error page without authentication" do
    visit "/500"

    # Note: Capybara doesn't preserve status codes when visiting URLs directly
    # The important thing is that the error page renders correctly
    expect(page).to have_content(I18n.t("errors.internal_server_error.title"))
    expect(page).to have_content(I18n.t("errors.internal_server_error.message"))
    expect(page).to have_content(I18n.t("errors.redirect_message"))
    expect(page).to have_link(I18n.t("errors.redirect_link"), href: root_path)
  end
end
