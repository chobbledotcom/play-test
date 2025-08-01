# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Safety Standards Display", type: :feature do
  include InspectionTestHelpers

  let(:inspection) { create(:inspection, length: 5, width: 4, height: 3) }

  before { sign_in(inspection.user) }

  scenario "viewing safety standards reference page" do
    visit safety_standards_path

    expect_i18n_content("safety_standards.title")
    expect_i18n_content("safety_standards.subtitle")

    %w[anchor runout wall_height].each do |calculator|
      expect_calculator_title(calculator.to_sym)
    end
  end

  scenario "safety standards link appears in navigation" do
    # Ensure homepage exists
    Page.find_or_create_by!(slug: "/") do |page|
      page.link_title = "Home"
      page.content = "<h1>Welcome</h1>"
    end

    visit root_path

    # For logged-in users, navigation is in the application layout
    expect(page).to have_link(
      I18n.t("navigation.safety_standards"),
      href: safety_standards_path
    )
  end

  scenario "safety standards info appears in slide assessment form" do
    inspection.update!(has_slide: true)
    inspection.slide_assessment.update!(
      slide_platform_height: 2.5,
      slide_wall_height: 2.5,
      slide_permanent_roof: false,
      runout: 1.5
    )
    inspection.user_height_assessment.update!(
      tallest_user_height: 2.0
    )

    visit_inspection_edit(inspection)
    navigate_to_assessment_tab("slide")

    within(".safety-standards-info") do
      # Wall height requirements section
      expect(page).to have_content("Wall Height Requirements")
      expect(page).to have_content("Height range: 0.6m - 3.0m")
      expect(page).to have_content("Calculation: 2.0m (user height)")

      # Runout requirements section
      expect(page).to have_content("Runout Requirements")
      expect(page).to have_content("50% calculation: 2.5m × 0.5 = 1.25m")
      expect(page).to have_content("Minimum requirement: 0.3m (300mm)")
      runout_text = "Base runout: Maximum of 1.25m and 0.3m = 1.25m"
      expect(page).to have_content(runout_text)
    end
  end

  scenario "safety standards info appears in user height assessment form" do
    inspection.user_height_assessment.update!(
      tallest_user_height: 1.2,
      containing_wall_height: 1.3,
      play_area_length: 5,
      play_area_width: 4
    )
    inspection.structure_assessment.update!(
      platform_height: 2000
    )
    inspection.slide_assessment.update!(slide_permanent_roof: false)

    visit_inspection_edit(inspection)
    navigate_to_assessment_tab("user_height")

    within(".safety-standards-info") do
      expect(page).to have_content("Height Requirements")
      expect(page).to have_content("Height range: 0.6m - 3.0m")
      expect(page).to have_content("Calculation: 1.2m (user height)")
    end
  end

  scenario "shows permanent roof requirement for high platforms" do
    inspection.user_height_assessment.update!(
      tallest_user_height: 1.8,
      containing_wall_height: 2.3,
      play_area_length: 5,
      play_area_width: 4
    )
    inspection.structure_assessment.update!(
      platform_height: 4000
    )
    inspection.slide_assessment.update!(slide_permanent_roof: true)

    visit_inspection_edit(inspection)
    navigate_to_assessment_tab("user_height")

    within(".safety-standards-info") do
      expect(page).to have_content("Height Requirements")
      expect(page).to have_content("Height range: 3.0m - 6.0m")
      expect(page).to have_content("Alternative requirement: Permanent roof")
      expect(page).to have_content("Permanent roof: Fitted ✓")
    end
  end

  scenario "safety standards info appears in anchorage assessment form" do
    # For 5m x 4m x 3m unit:
    # Front/back: 4m x 3m = 12m² → 2 anchors each
    # Sides: 5m x 3m = 15m² → 2 anchors each
    # Total required: (2 + 2) * 2 = 8 anchors
    inspection.anchorage_assessment.update!(
      num_low_anchors: 5, num_high_anchors: 3
    )

    visit_inspection_edit(inspection)
    navigate_to_assessment_tab("anchorage")

    within(".safety-standards-info") do
      expect(page).to have_content("Anchor Requirements")
      area = "Front/back area: 4.0m (W) × 3.0m (H) = 12.0m²"
      expect(page).to have_content(area)
      expect(page).to have_content("Calculated total anchors: (2 + 2) × 2 = 8")
    end
  end
end
