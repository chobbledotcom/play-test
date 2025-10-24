# typed: false

require "rails_helper"

RSpec.feature "About Page", type: :feature do
  let(:user) { create(:user) }

  before do
    # Clean up any existing pages to avoid conflicts
    Page.where(slug: ["about", "/"]).destroy_all

    sign_in(user)
    # Create about page
    create(:page, slug: "about", content: <<~HTML
      <h1>About play-test</h1>
      <h2>What is play-test?</h2>
      <p>EN 14960:2019 inflatable playground equipment</p>
      <h2>Key Features</h2>
      <h2>Attribution & Licensing</h2>
      <p>Stefan at Chobble.com Spencer Elliott
      elliottsbouncycastlehire.co.uk AGPLv3</p>
      <h2>Disclaimer</h2>
      <p>not affiliated with any testing bodies</p>
    HTML
    )
    # Create homepage for navigation test
    create(:page, slug: "/", content: "<h1>Home</h1>")
  end

  scenario "displays all required sections and content" do
    visit "/pages/about"

    expect(page).to have_content("About play-test")
    expect(page).to have_content("What is play-test?")
    expect(page).to have_content("Key Features")
    expect(page).to have_content("Attribution & Licensing")
    expect(page).to have_content("Disclaimer")

    expect(page).to have_content("EN 14960:2019")
    expect(page).to have_content("inflatable playground equipment")
    expect(page).to have_content("Stefan at Chobble.com")
    expect(page).to have_content("Spencer Elliott")
    expect(page).to have_content("elliottsbouncycastlehire.co.uk")
    expect(page).to have_content("AGPLv3")
    expect(page).to have_content("not affiliated with any testing bodies")

    within("nav") do
      expect(page).to have_link("About", href: "/pages/about")
    end
  end

  scenario "navigates from root to about page" do
    visit root_path

    within("nav") do
      click_link "About"
    end

    expect(current_path).to eq("/pages/about")
    expect(page).to have_content("About play-test")
  end
end
