require "rails_helper"

RSpec.feature "Safety Standards Tabs", type: :feature, js: true do
  before { visit safety_standards_path }

  scenario "displays tab navigation" do
    within("#safety-standard-tabs") do
      expect(page).to have_link("Anchorage", href: "#anchorage")
      expect(page).to have_link("User Capacity", href: "#user-capacity")
      expect(page).to have_link("Slides", href: "#slides")
      expect(page).to have_link("Material", href: "#material")
      expect(page).to have_link("Fan", href: "#fan")
      expect(page).to have_link("Additional", href: "#additional")
    end
  end

  scenario "shows anchorage tab by default" do
    within("#anchorage") do
      expect(page).to have_content("Calculate Required Anchors")
    end

    # Other tabs should not be visible
    expect(page).not_to have_css("#user-capacity", visible: true)
    expect(page).not_to have_css("#slides", visible: true)
  end

  scenario "navigating to slides tab" do
    click_link "Slides"

    expect(current_url).to include("#slides")

    within("#slides") do
      expect(page).to have_content(I18n.t("safety_standards.calculators.runout.title"))
      expect(page).to have_content(I18n.t("safety_standards.calculators.wall_height.title"))
      expect(page).to have_content(I18n.t("safety_standards.wall_heights.requirements_by_platform"))
    end
  end

  scenario "navigating to material tab" do
    click_link "Material"

    expect(current_url).to include("#material")

    within("#material") do
      expect(page).to have_content("Material Requirements")
      expect(page).to have_content("Fabric")
      expect(page).to have_content("Thread")
      expect(page).to have_content("Rope")
      expect(page).to have_content("Netting")
    end
  end

  scenario "navigating to fan tab" do
    click_link "Fan"

    expect(current_url).to include("#fan")

    within("#fan") do
      expect(page).to have_content("Electrical Safety Requirements")
      expect(page).to have_content("Grounding Test Weights")
    end
  end

  scenario "calculators work within tabs" do
    # Test anchor calculator in default tab
    within("#anchorage .calculator-form") do
      fill_in I18n.t("forms.safety_standards_anchors.fields.length"), with: 5.0
      fill_in I18n.t("forms.safety_standards_anchors.fields.width"), with: 5.0
      fill_in I18n.t("forms.safety_standards_anchors.fields.height"), with: 3.0
      click_button I18n.t("forms.safety_standards_anchors.submit")
    end

    within("#anchors-result") do
      expect(page).to have_content("Required anchors:")
      expect(page).to have_content("= 8")
    end

    # Navigate to slides tab and test calculator there
    click_link "Slides"

    within(".calculator-form", text: I18n.t("forms.safety_standards_slide_runout.header")) do
      fill_in I18n.t("forms.safety_standards_slide_runout.fields.platform_height"), with: 2.5
      click_button I18n.t("forms.safety_standards_slide_runout.submit")
    end

    within("#slide-runout-result") do
      expect(page).to have_content("Base runout:")
    end
  end
end
