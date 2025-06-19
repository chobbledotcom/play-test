require "rails_helper"

RSpec.feature "Safety Standards Interactive Forms", type: :feature do
  scenario "calculating anchor requirements" do
    visit safety_standards_path

    within(".calculator-form", text: I18n.t("forms.safety_standards_anchors.header")) do
      fill_in I18n.t("forms.safety_standards_anchors.fields.length"), with: "5.0"
      fill_in I18n.t("forms.safety_standards_anchors.fields.width"), with: "5.0"
      fill_in I18n.t("forms.safety_standards_anchors.fields.height"), with: "3.0"
      click_button I18n.t("forms.safety_standards_anchors.submit")
    end

    expect(page).to have_content(I18n.t("safety_standards.calculators.anchor.result_title"))
    expect(page).to have_content("8") # Total required anchors

    # Check the breakdown is displayed
    expect(page).to have_content("Front/back area")
    expect(page).to have_content("5.0m (W) × 3.0m (H) = 15.0m²")
    expect(page).to have_content("Total anchors")
    expect(page).to have_content("(2 + 2) × 2 = 8")
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

    expected_runout = SafetyStandard.calculate_required_runout(2.5)
    expect(page).to have_content("Required Runout: #{expected_runout}m")
    expect(page).to have_content("50% of 2.5m = 1.25m, minimum 0.3m = #{expected_runout}m")
  end

  scenario "calculating wall height requirements for different user heights" do
    visit safety_standards_path

    within(".calculator-form", text: "Calculate Wall Height Requirements") do
      fill_in "User Height (m):", with: "0.5"
      click_button "Calculate Wall Height"
    end

    expect(page).to have_content("Result:")
    expect(page).to have_content("User Height: 0.5m")
    expect(page).to have_content("No containing walls required")

    within(".calculator-form", text: "Calculate Wall Height Requirements") do
      fill_in "User Height (m):", with: "1.5"
      click_button "Calculate Wall Height"
    end

    expect(page).to have_content("User Height: 1.5m")
    expect(page).to have_content("Walls must be at least 1.5m (equal to user height)")

    within(".calculator-form", text: "Calculate Wall Height Requirements") do
      fill_in "User Height (m):", with: "4.0"
      click_button "Calculate Wall Height"
    end

    expect(page).to have_content("User Height: 4.0m")
    expect(page).to have_content("Walls must be at least 5.0m (1.25× user height)")

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

    expected_runout = SafetyStandard.calculate_required_runout(0.5)
    expect(page).to have_content("Required Runout: #{expected_runout}m")
    expect(expected_runout).to eq(0.3) # Verify model enforces minimum
  end

  scenario "showing calculation transparency" do
    visit safety_standards_path

    expect(page).to have_content("((Area × 114.0 × 1.5) ÷ 1600.0)")
    expect(page).to have_content("50% of platform height, minimum 300mm")
    expect(page).to have_content("Usable area ÷ space requirement per age group")

    expect(page).to have_content("For 25.0m² area: 3 anchors required")
    expect(page).to have_content("For 2.5m platform: 1.25m runout required")

    expect(page).to have_content("View Ruby Source Code")
    expect(page).to have_content("Method: calculate_required_anchors")
    expect(page).to have_content("Source: app/services/safety_standard.rb")

    within(".calculator-form", text: I18n.t("forms.safety_standards_anchors.header")) do
      fill_in I18n.t("forms.safety_standards_anchors.fields.length"), with: "4.0"
      fill_in I18n.t("forms.safety_standards_anchors.fields.width"), with: "4.0"
      fill_in I18n.t("forms.safety_standards_anchors.fields.height"), with: "3.0"
      click_button I18n.t("forms.safety_standards_anchors.submit")
    end

    # For 4x4x3m unit: front/back = 4x3=12m², sides = 4x3=12m²
    # Each side: (12 * 114 * 1.5) / 1600 = 1.2825 → 2
    # Total: 2 * 4 = 8
    expect(page).to have_content("8")
    expect(page).to have_content("Front/back area")
    expect(page).to have_content("4.0m (W) × 3.0m (H) = 12.0m²")
  end

  scenario "preserving form values after calculation" do
    visit safety_standards_path

    within(".calculator-form", text: "Calculate User Capacity") do
      fill_in "Length (m):", with: "6.5"
      fill_in "Width (m):", with: "3.2"
      fill_in "Negative Adjustment (m²):", with: "1.5"
      click_button "Calculate Capacity"
    end

    within(".calculator-form", text: "Calculate User Capacity") do
      expect(find_field("Length (m):").value).to eq("6.5")
      expect(find_field("Width (m):").value).to eq("3.2")
      expect(find_field("Negative Adjustment (m²):").value).to eq("1.5")
    end
  end

  scenario "handling invalid input gracefully" do
    visit safety_standards_path

    within(".calculator-form", text: I18n.t("forms.safety_standards_anchors.header")) do
      fill_in I18n.t("forms.safety_standards_anchors.fields.length"), with: "0"
      fill_in I18n.t("forms.safety_standards_anchors.fields.width"), with: "0"
      fill_in I18n.t("forms.safety_standards_anchors.fields.height"), with: "0"
      click_button I18n.t("forms.safety_standards_anchors.submit")
    end

    expect(page).to have_content("Error:")
    expect(page).to have_content(I18n.t("safety_standards.errors.invalid_dimensions"))

    within(".calculator-form", text: "Calculate User Capacity") do
      fill_in "Length (m):", with: "0"
      fill_in "Width (m):", with: "4.0"
      click_button "Calculate Capacity"
    end

    expect(page).to have_content("Error:")
    expect(page).to have_content("Please enter valid dimensions greater than 0")
  end

  scenario "calculations match SafetyStandard model exactly" do
    test_dimensions = [[3.0, 3.0, 2.0], [5.0, 4.0, 3.0], [8.0, 6.0, 4.0]]

    test_dimensions.each do |length, width, height|
      visit safety_standards_path

      within(".calculator-form", text: I18n.t("forms.safety_standards_anchors.header")) do
        fill_in I18n.t("forms.safety_standards_anchors.fields.length"), with: length.to_s
        fill_in I18n.t("forms.safety_standards_anchors.fields.width"), with: width.to_s
        fill_in I18n.t("forms.safety_standards_anchors.fields.height"), with: height.to_s
        click_button I18n.t("forms.safety_standards_anchors.submit")
      end

      expected = SafetyStandard.build_anchor_result(length: length, width: width, height: height)[:required_anchors]
      expect(page).to have_content("Required Anchors: #{expected}"),
        "Unit #{length}x#{width}x#{height}m should require #{expected} anchors according to SafetyStandard model"
    end
  end
end
