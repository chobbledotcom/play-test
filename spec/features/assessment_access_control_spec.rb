require "rails_helper"

RSpec.feature "Assessment Access Control", type: :feature do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:unit1) { create(:unit, user: user1) }
  let(:unit2) { create(:unit, user: user2) }
  let(:inspection1) { create(:inspection, user: user1, unit: unit1) }
  let(:inspection2) { create(:inspection, user: user2, unit: unit2) }

  before do
    # Create assessments for both inspections
    create(:anchorage_assessment, :complete, inspection: inspection1)
    create(:user_height_assessment, :complete, inspection: inspection1)
    create(:anchorage_assessment, :complete, inspection: inspection2)
    create(:user_height_assessment, :complete, inspection: inspection2)
  end

  scenario "user cannot view another user's inspection assessment form" do
    sign_in(user1)

    # Try to access user2's inspection edit page (where assessments are shown)
    visit edit_inspection_path(inspection2)

    # Should be redirected with access denied message
    expect(page).to have_content(I18n.t("inspections.errors.access_denied"))
    expect(current_path).to eq(inspections_path)
  end

  scenario "user cannot submit assessment data for another user's inspection via POST" do
    sign_in(user1)

    # Try to directly POST assessment data to user2's inspection
    assessment_data = {
      inspection: {
        anchorage_assessment_attributes: {
          num_low_anchors: 10,
          num_high_anchors: 5,
          num_anchors_pass: true
        }
      }
    }

    # Submit directly to the update endpoint
    page.driver.submit :patch, inspection_path(inspection2), assessment_data

    # Should get access denied and redirect
    expect(page).to have_content(I18n.t("inspections.errors.access_denied"))
    
    # Verify the assessment data was NOT updated
    inspection2.reload
    expect(inspection2.anchorage_assessment.num_low_anchors).not_to eq(10)
  end

  scenario "user cannot modify assessment data through form manipulation" do
    sign_in(user1)
    
    # Visit user1's own inspection to get a valid form
    visit edit_inspection_path(inspection1)
    expect(page).to have_content("Edit Inspection")

    # Try to manipulate the form to submit to user2's inspection
    # This simulates someone changing the form action in developer tools
    assessment_data = {
      inspection: {
        user_height_assessment_attributes: {
          containing_wall_height: 999.99,
          platform_height: 888.88
        }
      }
    }

    # Attempt to submit assessment data to user2's inspection
    page.driver.submit :patch, inspection_path(inspection2), assessment_data

    # Should be denied access
    expect(page).to have_content(I18n.t("inspections.errors.access_denied"))

    # Verify user2's assessment data was not modified
    inspection2.reload
    user2_assessment = inspection2.user_height_assessment
    expect(user2_assessment.containing_wall_height).not_to eq(999.99)
    expect(user2_assessment.platform_height).not_to eq(888.88)
  end

  scenario "user cannot access assessment data through JSON endpoints" do
    sign_in(user1)

    # Try to access user2's inspection data via JSON
    visit inspection_path(inspection2, format: :json)

    # Should get access denied
    expect(page).to have_content(I18n.t("inspections.errors.access_denied"))
  end

  scenario "user can successfully update their own assessment data" do
    sign_in(user1)
    
    visit edit_inspection_path(inspection1, tab: "anchorage")
    expect(page).to have_content("Edit Inspection")

    # Find and fill in an anchorage assessment field
    within ".anchorage-assessment" do
      fill_in "inspection_anchorage_assessment_attributes_num_low_anchors", with: "8"
      fill_in "inspection_anchorage_assessment_attributes_num_high_anchors", with: "6"
    end

    # Submit the form
    click_button I18n.t("inspections.buttons.save_assessment")

    # Should be successful
    expect(page).to have_content(I18n.t("inspections.messages.updated"))

    # Verify the data was actually updated
    inspection1.reload
    expect(inspection1.anchorage_assessment.num_low_anchors).to eq(8)
    expect(inspection1.anchorage_assessment.num_high_anchors).to eq(6)
  end

  scenario "assessment updates are isolated between users" do
    sign_in(user1)
    
    # Update user1's inspection
    visit edit_inspection_path(inspection1, tab: "user_height")
    
    within ".user-height-assessment" do
      fill_in "inspection_user_height_assessment_attributes_containing_wall_height", with: "2.5"
    end
    
    click_button I18n.t("inspections.buttons.save_assessment")
    expect(page).to have_content(I18n.t("inspections.messages.updated"))

    # Sign out and sign in as user2
    click_button I18n.t("sessions.buttons.log_out")
    sign_in(user2)

    # Check that user2's assessment data is unchanged
    visit edit_inspection_path(inspection2, tab: "user_height")
    
    # User2's assessment should have the original factory values, not user1's changes
    within ".user-height-assessment" do
      wall_height_field = find_field("inspection_user_height_assessment_attributes_containing_wall_height")
      expect(wall_height_field.value).not_to eq("2.5")
    end

    # Verify in the database as well
    inspection1.reload
    inspection2.reload
    expect(inspection1.user_height_assessment.containing_wall_height).to eq(2.5)
    expect(inspection2.user_height_assessment.containing_wall_height).not_to eq(2.5)
  end
end