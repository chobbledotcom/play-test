require "rails_helper"

RSpec.feature "Safety Standards Display", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user, length: 5, width: 4) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before do
    sign_in(user)
  end

  scenario "viewing safety standards reference page" do
    visit safety_standards_path

    expect(page).to have_content("Safety Standards Reference")
    expect(page).to have_content("EN 14960:2019 Requirements")
    expect(page).to have_content("Anchor Requirements")
    expect(page).to have_content("Wall Height Requirements")
    expect(page).to have_content("Slide Safety Requirements")
    expect(page).to have_content("Material Requirements")
  end

  scenario "safety standards link appears in navigation" do
    visit root_path

    within("nav") do
      expect(page).to have_link("Safety Standards", href: safety_standards_path)
    end
  end

  scenario "safety standards info appears in slide assessment form" do
    create(:slide_assessment,
      inspection: inspection,
      slide_platform_height: 2.5)

    visit edit_inspection_path(inspection, tab: "slide")

    within(".slide-assessment") do
      expect(page).to have_content("EN 14960:2019 Wall Height Requirements:")
      expect(page).to have_content("Walls must be at least 2.5m (equal to platform height)")

      expect(page).to have_content("EN 14960:2019 Requirement:")
      expect(page).to have_content("Minimum runout 1.25m")
      expect(page).to have_content("(50% of platform height or 300mm minimum)")
    end
  end

  scenario "safety standards info appears in user height assessment form" do
    create(:user_height_assessment,
      inspection: inspection,
      user_height: 1.5,
      containing_wall_height: 2.0,
      play_area_length: 5,
      play_area_width: 4)

    visit edit_inspection_path(inspection, tab: "user_height")

    within(".user-height-assessment") do
      expect(page).to have_content("EN 14960:2019 Height Requirements:")
      expect(page).to have_content("Containing walls must be at least 1.5m")
      expect(page).to have_content("Compliant")

      expect(page).to have_content("EN 14960:2019 Calculated Capacities:")
      expect(page).to have_content("1.0m users: 13 (1.5m² per user)")
      expect(page).to have_content("1.2m users: 10 (2.0m² per user)")
    end
  end

  scenario "safety standards info appears in anchorage assessment form" do
    create(:anchorage_assessment,
      inspection: inspection,
      num_low_anchors: 3,
      num_high_anchors: 2)

    visit edit_inspection_path(inspection, tab: "anchorage")

    within(".anchorage-assessment") do
      expect(page).to have_content("Total Anchors:")
      expect(page).to have_content("5")
      expect(page).to have_content("Required Anchors:")
      expect(page).to have_content("5")
      expect(page).to have_content("Compliance Status:")
      expect(page).to have_content("Compliant")
    end
  end
end
