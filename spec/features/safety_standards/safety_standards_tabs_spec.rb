# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Safety Standards Tabs", type: :feature, js: true do
  before { visit safety_standards_path }

  scenario "displays tab navigation" do
    expect_tab_links(:anchorage, :user_capacity, :slides,
      :material, :fan)
  end

  scenario "shows anchorage tab by default" do
    expect_tab_content("anchorage", "Calculate Required Anchors")

    # Other tabs should not be visible
    expect(page).not_to have_css("#user-capacity", visible: true)
    expect(page).not_to have_css("#slides", visible: true)
  end

  scenario "navigating to slides tab" do
    navigate_to_standard_tab(:slides)

    expect(current_url).to include("#slides")
    expect_slides_content
  end

  scenario "navigating to material tab" do
    navigate_to_standard_tab(:material)

    expect(current_url).to include("#material")
    expect_material_content
  end

  scenario "navigating to fan tab" do
    navigate_to_standard_tab(:fan)

    expect(current_url).to include("#fan")
    expect_fan_content
  end

  scenario "calculators work within tabs" do
    # Test anchor calculator in default tab
    fill_anchor_calculator(length: 5.0, width: 5.0, height: 3.0)
    expect_anchor_result_header(8)

    # Navigate to slides tab and test calculator there
    navigate_to_standard_tab(:slides)
    fill_slide_calculator(platform_height: 2.5)
    expect_runout_result(required_runout: 1.25)
  end
end
