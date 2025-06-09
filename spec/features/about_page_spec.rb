require "rails_helper"

RSpec.feature "About Page", type: :feature do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  scenario "displays information about the system" do
    visit about_path

    # Check page title
    expect(page).to have_content(I18n.t("about.title"))

    # Check all main sections are present
    expect(page).to have_content(I18n.t("about.what_it_is.title"))
    expect(page).to have_content(I18n.t("about.key_features.title"))
    expect(page).to have_content(I18n.t("about.attribution.title"))
    expect(page).to have_content(I18n.t("about.disclaimer.title"))

    # Check some specific content
    expect(page).to have_content("EN 14960:2019")
    expect(page).to have_content("inflatable playground equipment")
    expect(page).to have_content("Stefan at Chobble.com")
    expect(page).to have_content("Spencer Elliott")
    expect(page).to have_content("elliottsbouncycastlehire.co.uk")
    expect(page).to have_content("AGPLv3")
    expect(page).to have_content("not affiliated with any testing bodies")

    # Check navigation link exists
    within("nav") do
      expect(page).to have_link("About", href: about_path)
    end
  end

  scenario "navigates to about page from navigation menu" do
    visit root_path
    
    within("nav") do
      click_link "About"
    end

    expect(current_path).to eq(about_path)
    expect(page).to have_content(I18n.t("about.title"))
  end
end