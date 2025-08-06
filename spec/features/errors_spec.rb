# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Error pages", type: :feature do
  scenario "404 page uses application layout" do
    visit "/non-existent-page-that-should-not-exist"

    expect(page.status_code).to eq(404)
    expect(page).to have_content(I18n.t("errors.not_found.title"))
    expect(page).to have_content(I18n.t("errors.not_found.message"))
  end
end
