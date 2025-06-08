require "rails_helper"

RSpec.feature "Safety Standards Interactive Forms", type: :feature do
  scenario "calculating anchor requirements" do
    visit safety_standards_path

    within(".calculator-form", text: I18n.t("safety_standards_reference.calculators.anchor.title")) do
      fill_in I18n.t("safety_standards_reference.calculators.anchor.area_label"), with: "25.0"
      click_button I18n.t("safety_standards_reference.calculators.anchor.submit")
    end

    expect(page).to have_content(I18n.t("safety_standards_reference.calculators.anchor.result_title"))
    expect(page).to have_content("25.0m²")

    # Get expected result from SafetyStandard model
    expected_anchors = SafetyStandard.calculate_required_anchors(25.0)
    expect(page).to have_content(expected_anchors.to_s)
    expect(page).to have_content("((25.0² × 114) ÷ 1600) × 1.5 = #{expected_anchors}")
  end

  scenario "calculating user capacity" do
    visit safety_standards_path

    within(".calculator-form", text: "Calculate User Capacity") do
      fill_in "Length (m):", with: "5.0"
      fill_in "Width (m):", with: "4.0"
      fill_in "Negative Adjustment (m²):", with: "2.0"
      click_button "Calculate Capacity"
    end

    expect(page).to have_content("Result:")
    expect(page).to have_content("Dimensions: 5.0m × 4.0m")
    expect(page).to have_content("Total Area: 20.0m²")
    expect(page).to have_content("Negative Adjustment: -2.0m²")
    expect(page).to have_content("Usable Area: 18.0m²")

    # Get expected results from SafetyStandard model
    expected_capacity = SafetyStandard.calculate_user_capacity(5.0, 4.0, 2.0)
    expect(page).to have_content("1.0m users: #{expected_capacity[:users_1000mm]} (young children)")
    expect(page).to have_content("1.2m users: #{expected_capacity[:users_1200mm]} (children)")
    expect(page).to have_content("1.5m users: #{expected_capacity[:users_1500mm]} (adolescents)")
    expect(page).to have_content("1.8m users: #{expected_capacity[:users_1800mm]} (adults)")
  end

  scenario "calculating slide runout requirements" do
    visit safety_standards_path

    within(".calculator-form", text: "Calculate Required Runout Length") do
      fill_in "Platform Height (m):", with: "2.5"
      click_button "Calculate Runout"
    end

    expect(page).to have_content("Result:")
    expect(page).to have_content("Platform Height: 2.5m")

    # Get expected result from SafetyStandard model
    expected_runout = SafetyStandard.calculate_required_runout(2.5)
    expect(page).to have_content("Required Runout: #{expected_runout}m")
    expect(page).to have_content("50% of 2.5m = 1.25m, minimum 0.3m = #{expected_runout}m")
  end

  scenario "calculating wall height requirements for different user heights" do
    visit safety_standards_path

    # Test case 1: Under 0.6m - no walls required
    within(".calculator-form", text: "Calculate Wall Height Requirements") do
      fill_in "User Height (m):", with: "0.5"
      click_button "Calculate Wall Height"
    end

    expect(page).to have_content("Result:")
    expect(page).to have_content("User Height: 0.5m")
    expect(page).to have_content("No containing walls required")

    # Test case 2: 1.5m - walls equal to user height
    within(".calculator-form", text: "Calculate Wall Height Requirements") do
      fill_in "User Height (m):", with: "1.5"
      click_button "Calculate Wall Height"
    end

    expect(page).to have_content("User Height: 1.5m")
    expect(page).to have_content("Walls must be at least 1.5m (equal to user height)")

    # Test case 3: 4.0m - walls 1.25x user height
    within(".calculator-form", text: "Calculate Wall Height Requirements") do
      fill_in "User Height (m):", with: "4.0"
      click_button "Calculate Wall Height"
    end

    expect(page).to have_content("User Height: 4.0m")
    expect(page).to have_content("Walls must be at least 5.0m (1.25× user height)")

    # Test case 4: 7.0m - walls + permanent roof
    within(".calculator-form", text: "Calculate Wall Height Requirements") do
      fill_in "User Height (m):", with: "7.0"
      click_button "Calculate Wall Height"
    end

    expect(page).to have_content("User Height: 7.0m")
    expect(page).to have_content("Walls must be at least 8.75m + permanent roof required")
    expect(page).to have_content("Permanent roof required")
  end

  scenario "enforcing minimum runout requirements" do
    visit safety_standards_path

    within(".calculator-form", text: "Calculate Required Runout Length") do
      fill_in "Platform Height (m):", with: "0.5"
      click_button "Calculate Runout"
    end

    # Should enforce minimum 0.3m runout
    expected_runout = SafetyStandard.calculate_required_runout(0.5)
    expect(page).to have_content("Required Runout: #{expected_runout}m")
    expect(expected_runout).to eq(0.3) # Verify model enforces minimum
  end

  scenario "showing calculation transparency" do
    visit safety_standards_path

    # Check that unified formulas are shown before any calculation
    expect(page).to have_content("((Area² × 114.0) ÷ 1600.0) × 1.5 safety factor")
    expect(page).to have_content("50% of platform height, minimum 300mm")
    expect(page).to have_content("Usable area ÷ space requirement per age group")

    # Check that generated examples are shown
    expect(page).to have_content("For 25.0m² area: 67 anchors required")
    expect(page).to have_content("For 2.5m platform: 1.25m runout required")

    # Check that Ruby source code is available
    expect(page).to have_content("View Ruby Source Code")
    expect(page).to have_content("Method: calculate_required_anchors")
    expect(page).to have_content("Source: app/models/safety_standard.rb")

    # Perform calculation and verify breakdown is shown
    within(".calculator-form", text: "Calculate Required Anchors") do
      fill_in "Area (m²):", with: "16.0"
      click_button "Calculate Anchors"
    end

    expected_anchors = SafetyStandard.calculate_required_anchors(16.0)
    expect(page).to have_content("((16.0² × 114) ÷ 1600) × 1.5 = #{expected_anchors}")
  end

  scenario "preserving form values after calculation" do
    visit safety_standards_path

    within(".calculator-form", text: "Calculate User Capacity") do
      fill_in "Length (m):", with: "6.5"
      fill_in "Width (m):", with: "3.2"
      fill_in "Negative Adjustment (m²):", with: "1.5"
      click_button "Calculate Capacity"
    end

    # Values should be preserved in form fields
    within(".calculator-form", text: "Calculate User Capacity") do
      expect(find_field("Length (m):").value).to eq("6.5")
      expect(find_field("Width (m):").value).to eq("3.2")
      expect(find_field("Negative Adjustment (m²):").value).to eq("1.5")
    end
  end

  scenario "handling invalid input gracefully" do
    visit safety_standards_path

    # Test invalid area
    within(".calculator-form", text: "Calculate Required Anchors") do
      fill_in "Area (m²):", with: "0"
      click_button "Calculate Anchors"
    end

    expect(page).to have_content("Error:")
    expect(page).to have_content("Please enter a valid area greater than 0")

    # Test invalid dimensions
    within(".calculator-form", text: "Calculate User Capacity") do
      fill_in "Length (m):", with: "0"
      fill_in "Width (m):", with: "4.0"
      click_button "Calculate Capacity"
    end

    expect(page).to have_content("Error:")
    expect(page).to have_content("Please enter valid dimensions greater than 0")
  end

  scenario "calculations match SafetyStandard model exactly" do
    # Test various anchor area calculations
    test_areas = [1.0, 5.5, 16.0, 25.0, 50.0]

    test_areas.each do |area|
      visit safety_standards_path

      within(".calculator-form", text: "Calculate Required Anchors") do
        fill_in "Area (m²):", with: area.to_s
        click_button "Calculate Anchors"
      end

      expected = SafetyStandard.calculate_required_anchors(area)
      expect(page).to have_content("Required Anchors: #{expected}"),
        "Area #{area}m² should require #{expected} anchors according to SafetyStandard model"
    end
  end

  scenario "demonstrates EN 14960:2019 compliance" do
    visit safety_standards_path

    # Verify EN 14960:2019 is prominently mentioned
    expect(page).to have_content("EN 14960:2019 Requirements for Inflatable Play Equipment")

    # Check that standard references are included throughout
    expect(page).to have_content("1850 Newtons minimum") # Fabric strength
    expect(page).to have_content("18mm - 45mm") # Rope diameter
    expect(page).to have_content("1600 Newton pull strength minimum") # Anchor strength
    expect(page).to have_content("1.2m minimum from equipment edge") # Blower distance
  end
end
