require "rails_helper"

RSpec.feature "Safety Standards Display", type: :feature do
  include InspectionTestHelpers

  let(:inspection) { create(:inspection, length: 5, width: 4, height: 3) }

  before { sign_in(inspection.user) }

  scenario "viewing safety standards reference page" do
    visit safety_standards_path

    expect(page).to have_content(I18n.t("safety_standards.title"))
    expect(page).to have_content(I18n.t("safety_standards.subtitle"))

    %w[anchor user_capacity runout wall_height].each do |calculator|
      expect(page).to have_content(I18n.t("safety_standards.calculators.#{calculator}.title"))
    end
  end

  scenario "safety standards link appears in navigation" do
    visit root_path

    within("nav") do
      expect(page).to have_link(I18n.t("navigation.safety_standards"), href: safety_standards_path)
    end
  end

  scenario "safety standards info appears in slide assessment form" do
    inspection.update!(has_slide: true)
    inspection.slide_assessment.update!(slide_platform_height: 2.5)

    visit_inspection_edit(inspection)
    click_link I18n.t("forms.slide.header")

    within(".safety-standards-info") do
      expect_safety_standard(:slide_requirements, :wall_height_requirements)
      expect_safety_standard(:slide_requirements, :walls_equal_height, height: 2.5)
      expect_safety_standard(:slide_requirements, :minimum_runout)
      expect(page).to have_content("1.25m")
    end
  end

  scenario "safety standards info appears in user height assessment form" do
    inspection.user_height_assessment.update!(
      tallest_user_height: 1.2,
      containing_wall_height: 1.3,
      play_area_length: 5,
      play_area_width: 4
    )

    visit_inspection_edit(inspection)
    click_link I18n.t("forms.user_height.header")

    within(".safety-standards-info") do
      expect_safety_standard(:user_height, :height_requirements)
      expect_safety_standard(:user_height, :walls_equal_user_height, height: 1.2)
      expect(page).to have_content(I18n.t("shared.pass"))
      expect_safety_standard(:user_height, :calculated_capacities)
    end
  end

  scenario "safety standards info appears in anchorage assessment form" do
    # For 5m x 4m x 3m unit:
    # Front/back: 4m x 3m = 12m² → 2 anchors each
    # Sides: 5m x 3m = 15m² → 2 anchors each
    # Total required: (2 + 2) * 2 = 8 anchors
    inspection.anchorage_assessment.update!(num_low_anchors: 5, num_high_anchors: 3)

    visit_inspection_edit(inspection)
    click_link I18n.t("forms.anchorage.header")

    within(".safety-standards-info") do
      expect_safety_standard(:anchor_requirements, :total_anchors)
      expect(page).to have_content("8") # 5 + 3
      expect_safety_standard(:anchor_requirements, :required)
      expect(page).to have_content("8") # Required anchors
    end
  end
end
