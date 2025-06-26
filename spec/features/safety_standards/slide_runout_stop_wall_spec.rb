require "rails_helper"

RSpec.feature "Slide Runout with Stop-wall", type: :feature do
  scenario "calculating runout without stop-wall" do
    visit safety_standards_path

    # Fill form without checking stop-wall
    within ".calculator-form", text: "Calculate Required Runout Length" do
      fill_in "Platform Height (m)", with: "2.0"
      click_button "Calculate Runout"
    end

    # Should calculate 50% of 2m = 1m
    within "#slide-runout-result" do
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.required_runout_result")}: 1.0m")
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.calculation_label")}: 2.0m × 0.5 = 1.0m")
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.minimum_label")}: 0.3m (300mm)")
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.base_runout_label")}: #{I18n.t("safety_standards.calculators.runout.maximum_of")} 1.0m #{I18n.t("safety_standards.calculators.runout.and")} 0.3m = 1.0m")
    end
  end

  scenario "calculating runout with stop-wall" do
    visit safety_standards_path

    # Fill form and check stop-wall
    within ".calculator-form", text: "Calculate Required Runout Length" do
      fill_in "Platform Height (m)", with: "2.0"
      check "Stop-wall fitted at end of runout"
      click_button "Calculate Runout"
    end

    # Should calculate 50% of 2m = 1m + 0.5m = 1.5m
    within "#slide-runout-result" do
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.required_runout_result")}: 1.5m")
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.calculation_label")}: 2.0m × 0.5 = 1.0m")
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.minimum_label")}: 0.3m (300mm)")
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.base_runout_label")}: #{I18n.t("safety_standards.calculators.runout.maximum_of")} 1.0m #{I18n.t("safety_standards.calculators.runout.and")} 0.3m = 1.0m")
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.stop_wall_addition_label")}: 1.0m + 0.5m = 1.5m")
    end
  end

  scenario "stop-wall adds to minimum runout" do
    visit safety_standards_path

    # Test with height that would give less than minimum
    within ".calculator-form", text: "Calculate Required Runout Length" do
      fill_in "Platform Height (m)", with: "0.5"
      check "Stop-wall fitted at end of runout"
      click_button "Calculate Runout"
    end

    # Should calculate 50% of 0.5m = 0.25m, but minimum 0.3m + 0.5m = 0.8m
    within "#slide-runout-result" do
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.required_runout_result")}: 0.8m")
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.calculation_label")}: 0.5m × 0.5 = 0.25m")
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.minimum_label")}: 0.3m (300mm)")
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.base_runout_label")}: #{I18n.t("safety_standards.calculators.runout.maximum_of")} 0.25m #{I18n.t("safety_standards.calculators.runout.and")} 0.3m = 0.3m")
      expect(page).to have_content("#{I18n.t("safety_standards.calculators.runout.stop_wall_addition_label")}: 0.3m + 0.5m = 0.8m")
    end
  end
end
