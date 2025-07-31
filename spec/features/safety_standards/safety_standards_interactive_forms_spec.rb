require "rails_helper"

RSpec.feature "Safety Standards Interactive Forms", type: :feature do
  scenario "calculating anchor requirements" do
    visit safety_standards_path

    fill_anchor_form(length: 5.0, width: 5.0, height: 3.0)
    submit_anchor_form

    expect_anchor_result(8)
    expect_anchor_breakdown(width: 5.0, height: 3.0, area: 15.0)

    within_result(:anchors) do
      key = "safety_standards.calculators.anchor.total_anchors_label"
      expect_i18n_content(key)
      expect(page).to have_content("(2 + 2) × 2 = 8")
    end
  end

  scenario "calculating slide runout requirements" do
    visit safety_standards_path

    fill_runout_form(platform_height: 2.5)
    submit_runout_form

    expect_runout_result(required_runout: 1.25)
    expect_runout_breakdown(platform_height: 2.5, calculated: 1.25)
  end

  scenario "wall height requirements for different platform heights" do
    visit safety_standards_path

    # Platform < 0.6m: No walls required
    fill_wall_height_form(platform_height: 0.5, user_height: 1.5)
    submit_wall_height_form
    expect_no_walls_required

    # Platform 0.6-3.0m: Walls equal to user height
    fill_wall_height_form(platform_height: 2.0, user_height: 1.5)
    submit_wall_height_form
    expect_wall_height_breakdown(
      height: 1.5,
      range: "0.6m - 3.0m",
      calculation: "1.5m (user height)"
    )

    # Platform 3.0-6.0m: Walls 1.25× user height
    fill_wall_height_form(platform_height: 4.0, user_height: 2.0)
    submit_wall_height_form
    expect_wall_height_breakdown(
      height: 2.5,
      range: "3.0m - 6.0m",
      calculation: "2.0m × 1.25 = 2.5m"
    )

    # Platform > 6.0m: Walls 1.25× user height + roof required
    fill_wall_height_form(platform_height: 7.0, user_height: 2.0)
    submit_wall_height_form
    expect_wall_height_breakdown(
      height: 2.5,
      range: "Over 6.0m",
      calculation: "2.0m × 1.25 = 2.5m",
      roof: true
    )
  end

  scenario "enforcing minimum runout requirements" do
    visit safety_standards_path

    fill_runout_form(platform_height: 1.0)
    submit_runout_form

    calculator = EN14960::Calculators::SlideCalculator
    expected_runout = calculator.calculate_required_runout(1.0)
    expect_runout_result(required_runout: expected_runout.value)
    expect(expected_runout.value).to eq(0.5)
  end

  scenario "showing calculation transparency" do
    visit safety_standards_path

    expect_calculation_transparency

    fill_anchor_form(length: 4.0, width: 4.0, height: 3.0)
    submit_anchor_form

    expect_anchor_result(8)
    expect_anchor_breakdown(width: 4.0, height: 3.0, area: 12.0)
  end

  scenario "handling invalid input gracefully" do
    visit safety_standards_path

    fill_anchor_form(length: 1.0, width: 1.0, height: 1.0)
    submit_anchor_form

    # EN 14960 requires minimum 6 anchors
    expect_anchor_result(6)
  end

  scenario "calculations match EN14960 model exactly" do
    test_dimensions = [[3.0, 3.0, 2.0], [5.0, 4.0, 3.0], [8.0, 6.0, 4.0]]

    test_dimensions.each do |length, width, height|
      visit safety_standards_path
      fill_anchor_form(length: length, width: width, height: height)
      submit_anchor_form

      expected = EN14960::Calculators::AnchorCalculator.calculate(
        length: length, width: width, height: height
      ).value

      expect_anchor_result(expected)
    end
  end
end
