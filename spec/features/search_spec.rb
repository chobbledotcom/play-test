# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Search functionality", type: :feature, js: true do
  scenario "homepage search redirects to search page with query" do
    visit root_path

    expect(page).to have_css(".search-form")

    within ".search-form" do
      fill_in "id", with: "TEST1234"
      find("button[type='submit']").click
    end

    expect(page).to have_current_path("/search?id=TEST1234", wait: 5)
    expect(page).to have_field("id", with: "TEST1234")
    expect(page).to have_css("#search-results", visible: true)
  end

  scenario "accessing search page with id parameter auto-performs search" do
    visit "/search?id=ABCD5678"

    expect(page).to have_field("id", with: "ABCD5678")
    expect(page).to have_css("#search-results", visible: true)
    expect(page).to have_text("Searching...")
  end
end
