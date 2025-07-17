require "rails_helper"

RSpec.feature "Search page", type: :feature do
  scenario "displays search form with required fields" do
    visit search_path

    # Check page title
    expect(page).to have_content(I18n.t("forms.search.header"))

    # Check form fields are present
    within "form" do
      # Check type select field
      expect(page).to have_select(I18n.t("forms.search.fields.type"),
        with_options: [
          I18n.t("forms.search.options.inspection"),
          I18n.t("forms.search.options.unit")
        ])

      # Check ID field
      expect(page).to have_field(I18n.t("forms.search.fields.id"))

      # Check submit button
      expect(page).to have_button(I18n.t("forms.search.submit"))
    end

    # Check results table is hidden initially
    expect(page).not_to have_selector("#search-results", visible: true)
  end

  scenario "can submit search form" do
    visit search_path

    within "form" do
      select I18n.t("forms.search.options.inspection"),
        from: I18n.t("forms.search.fields.type")
      fill_in I18n.t("forms.search.fields.id"), with: "ABC12345"
      click_button I18n.t("forms.search.submit")
    end

    # With js: false, the form will submit but nothing will happen
    # Just verify the form can be submitted without errors
    expect(page).to have_current_path(search_path)
  end

  scenario "displays all federated sites in results table" do
    visit search_path

    # Check that federated sites are in the DOM (even if hidden)
    Federation.sites.each do |site|
      site_name = I18n.t("search.sites.#{site[:name]}")
      expect(page.html).to include(site_name)
    end
  end
end
