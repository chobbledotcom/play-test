require "rails_helper"

RSpec.feature "Assessment Access Control", type: :feature do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:unit1) { create(:unit, user: user1) }
  let(:unit2) { create(:unit, user: user2) }
  let(:inspection1) { create(:inspection, user: user1, unit: unit1) }
  let(:inspection2) { create(:inspection, user: user2, unit: unit2) }

  before do
    create(:anchorage_assessment, :complete, inspection: inspection1)
    create(:user_height_assessment, :complete, inspection: inspection1)
    create(:anchorage_assessment, :complete, inspection: inspection2)
    create(:user_height_assessment, :complete, inspection: inspection2)
  end

  scenario "prevents viewing another user's inspection assessment form" do
    sign_in(user1)
    visit edit_inspection_path(inspection2)

    expect_access_denied
  end

  scenario "prevents submitting assessment data via direct POST" do
    sign_in(user1)

    page.driver.submit :patch, inspection_path(inspection2), {
      inspection: {
        anchorage_assessment_attributes: {
          num_low_anchors: 10,
          num_high_anchors: 5,
          num_anchors_pass: true
        }
      }
    }

    expect(page).to have_content(I18n.t("inspections.errors.access_denied"))
    expect(current_path).to eq(inspections_path)
    
    inspection2.reload
    expect(inspection2.anchorage_assessment.num_low_anchors).not_to eq(10)
  end

  scenario "prevents modifying assessment data through form manipulation" do
    sign_in(user1)
    visit edit_inspection_path(inspection1)
    expect(page).to have_content("Edit Inspection")

    page.driver.submit :patch, inspection_path(inspection2), {
      inspection: {
        user_height_assessment_attributes: {
          containing_wall_height: 999.99,
          platform_height: 888.88
        }
      }
    }

    expect(page).to have_content(I18n.t("inspections.errors.access_denied"))
    expect(current_path).to eq(inspections_path)
    
    inspection2.reload
    assessment = inspection2.user_height_assessment
    expect(assessment.containing_wall_height).not_to eq(999.99)
    expect(assessment.platform_height).not_to eq(888.88)
  end

  scenario "prevents accessing assessment data through JSON endpoints" do
    sign_in(user1)
    visit inspection_path(inspection2, format: :json)

    expect_access_denied
  end

  scenario "allows updating own assessment data successfully" do
    sign_in(user1)
    visit edit_inspection_path(inspection1, tab: "anchorage")
    expect(page).to have_content("Edit Inspection")

    within ".anchorage-assessment" do
      fill_in "inspection_anchorage_assessment_attributes_num_low_anchors", with: "8"
      fill_in "inspection_anchorage_assessment_attributes_num_high_anchors", with: "6"
    end
    click_button I18n.t("inspections.buttons.save_assessment")

    expect(page).to have_content(I18n.t("inspections.messages.updated"))
    
    inspection1.reload
    expect(inspection1.anchorage_assessment.num_low_anchors).to eq(8)
    expect(inspection1.anchorage_assessment.num_high_anchors).to eq(6)
  end

  scenario "isolates assessment updates between users" do
    sign_in(user1)
    visit edit_inspection_path(inspection1, tab: "user_height")
    within ".user-height-assessment" do
      fill_in "inspection_user_height_assessment_attributes_containing_wall_height", with: "2.5"
    end
    click_button I18n.t("inspections.buttons.save_assessment")
    expect(page).to have_content(I18n.t("inspections.messages.updated"))

    click_button I18n.t("sessions.buttons.log_out")
    sign_in(user2)
    visit edit_inspection_path(inspection2, tab: "user_height")

    within ".user-height-assessment" do
      wall_height_field = find_field("inspection_user_height_assessment_attributes_containing_wall_height")
      expect(wall_height_field.value).not_to eq("2.5")
    end

    inspection1.reload
    inspection2.reload
    expect(inspection1.user_height_assessment.containing_wall_height).to eq(2.5)
    expect(inspection2.user_height_assessment.containing_wall_height).not_to eq(2.5)
  end

  private

  def expect_access_denied
    expect(page).to have_content(I18n.t("inspections.errors.access_denied"))
    expect(current_path).to eq(inspections_path)
  end

end