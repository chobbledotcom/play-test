require "rails_helper"

RSpec.feature "Unified Safety Standards Breakdown Display", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before do
    sign_in(user)
  end

  scenario "slide assessment shows runout compliance status" do
    inspection.update!(has_slide: true)
    inspection.slide_assessment.update!(
      slide_platform_height: 3.0,
      slide_wall_height: 2.0,
      slide_permanent_roof: false,
      runout: 1.0 # Less than required 1.5m
    )
    inspection.user_height_assessment.update!(
      tallest_user_height: 1.8
    )

    visit edit_inspection_path(inspection, tab: :slide)

    within(".safety-standards-info") do
      # Check runout section
      expect(page).to have_content("Runout Requirements")
      expect(page).to have_content("Required Runout: 1.5m")
      expect(page).to have_content("Fail")
      expect(page).to have_content("Non-Compliant (Requires 1.5m minimum)")
    end
  end

  scenario "user height and slide assessments use same breakdown format" do
    inspection.update!(has_slide: true)
    inspection.user_height_assessment.update!(
      tallest_user_height: 1.8,
      containing_wall_height: 2.3
    )
    inspection.structure_assessment.update!(
      platform_height: 4000
    )
    inspection.slide_assessment.update!(
      slide_platform_height: 4.0,
      slide_wall_height: 2.3,
      slide_permanent_roof: true
    )

    # Check user height tab
    visit edit_inspection_path(inspection, tab: :user_height)
    within(".safety-standards-info") do
      expect(page).to have_content("Height Requirements")
      expect(page).to have_content("Breakdown")
      expect(page).to have_css("ul li", count: 4) # Should have 4 breakdown items
    end

    # Check slide tab
    visit edit_inspection_path(inspection, tab: :slide)
    within(".safety-standards-info") do
      expect(page).to have_content("Wall Height Requirements")
      expect(page).to have_content("Breakdown")
      expect(page).to have_css("h5", text: "Breakdown", count: 1) # Only one breakdown section visible
    end
  end
end
