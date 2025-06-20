require "rails_helper"

RSpec.feature "Safety Standards Interactive Forms", type: :feature do
  scenario "calculating anchor requirements" do
    visit safety_standards_path

    fill_anchor_form(length: 5.0, width: 5.0, height: 3.0)
    submit_anchor_form

    expect_anchor_result(8)

    within("#anchors-result") do
      expect(page).to have_content("Front/back area")
      expect(page).to have_content("5.0m (W) × 3.0m (H) = 15.0m²")
      expect(page).to have_content("Total anchors")
      expect(page).to have_content("(2 + 2) × 2 = 8")
    end
  end

  scenario "calculating user capacity" do
    visit safety_standards_path

    fill_capacity_form(length: 5.0, width: 4.0, adjustment: 2.0)
    submit_capacity_form

    expect_capacity_result(usable_area: 18.0)
    expect_capacity_details(length: 5.0, width: 4.0, adjustment: 2.0)
  end

  scenario "calculating slide runout requirements" do
    visit safety_standards_path

    fill_runout_form(height: 2.5)
    submit_runout_form

    expect_runout_result(required_runout: 1.25)

    within("#slide-runout-result") do
      expect(page).to have_content("Platform Height: 2.5m")
      expect(page).to have_content("50% of 2.5m = 1.25m, minimum 0.3m = 1.25m")
    end
  end

  scenario "calculating wall height requirements for different user heights" do
    visit safety_standards_path

    fill_wall_height_form(height: 1.0)
    submit_wall_height_form
    expect_wall_height_result("Walls must be at least 1.0m (equal to user height)")

    fill_wall_height_form(height: 1.5)
    submit_wall_height_form
    expect_wall_height_result("Walls must be at least 1.5m (equal to user height)")

    fill_wall_height_form(height: 4.0)
    submit_wall_height_form
    expect_wall_height_result("Walls must be at least 5.0m (1.25× user height)")

    fill_wall_height_form(height: 7.0)
    submit_wall_height_form

    within("#wall-height-result") do
      expect(page).to have_content("Walls must be at least 8.75m + permanent roof required")
      expect(page).to have_content("Permanent roof required")
    end
  end

  scenario "enforcing minimum runout requirements" do
    visit safety_standards_path

    fill_runout_form(height: 1.0)
    submit_runout_form

    expected_runout = SafetyStandard.calculate_required_runout(1.0)
    expect_runout_result(required_runout: expected_runout)
    expect(expected_runout).to eq(0.5)
  end

  scenario "showing calculation transparency" do
    visit safety_standards_path

    expect(page).to have_content("((Area × 114.0 × 1.5) ÷ 1600.0)")
    expect(page).to have_content("50% of platform height, minimum 300mm")
    expect(page).to have_content("Usable area ÷ space requirement per age group")

    expect(page).to have_content("For 25.0m² area: 3 anchors required")
    expect(page).to have_content("For 2.5m platform: 1.25m runout required")

    expect(page).to have_content("Ruby Source Code")
    expect(page).to have_content("Method: calculate_required_anchors")
    expect(page).to have_content("Source: app/services/safety_standard.rb")

    fill_anchor_form(length: 4.0, width: 4.0, height: 3.0)
    submit_anchor_form

    expect_anchor_result(8)

    within("#anchors-result") do
      expect(page).to have_content("Front/back area")
      expect(page).to have_content("4.0m (W) × 3.0m (H) = 12.0m²")
    end
  end

  scenario "handling invalid input gracefully" do
    visit safety_standards_path

    fill_anchor_form(length: 1.0, width: 1.0, height: 1.0)
    submit_anchor_form

    expect_anchor_result(4)
  end

  scenario "calculations match SafetyStandard model exactly" do
    test_dimensions = [[3.0, 3.0, 2.0], [5.0, 4.0, 3.0], [8.0, 6.0, 4.0]]

    test_dimensions.each do |length, width, height|
      visit safety_standards_path

      fill_anchor_form(length: length, width: width, height: height)
      submit_anchor_form

      expected = SafetyStandard.build_anchor_result(
        length: length, width: width, height: height
      )[:required_anchors]

      expect_anchor_result(expected)
    end
  end
end
