# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Search page", type: :feature do
  scenario "displays search form with search box matching homepage style" do
    visit search_path

    # Check that the search box is present with correct attributes
    within "#search" do
      expect(page).to have_field(type: "text", name: "id")
      expect(page).to have_button(type: "submit")
    end

    # Check results table is hidden initially
    expect(page).not_to have_selector("#search-results", visible: true)
  end

  scenario "can submit search form" do
    visit search_path

    within "#search" do
      fill_in "id", with: "ABC12345"
      click_button
    end

    # Form submission includes the ID parameter
    expect(page).to have_current_path(search_path(id: "ABC12345"))
  end

  scenario "results table has correct columns" do
    visit search_path

    # Check table headers (table is hidden but present in DOM)
    site_text = I18n.t("search.results.site")
    type_text = I18n.t("search.results.type")
    status_text = I18n.t("search.results.status")
    action_text = I18n.t("search.results.action")

    expect(page).to have_selector("#search-results th",
      text: site_text, visible: false)
    expect(page).to have_selector("#search-results th",
      text: type_text, visible: false)
    expect(page).to have_selector("#search-results th",
      text: status_text, visible: false)
    expect(page).to have_selector("#search-results th",
      text: action_text, visible: false)
  end
end
