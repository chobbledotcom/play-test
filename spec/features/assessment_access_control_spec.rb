require "rails_helper"

RSpec.feature "Assessment Access Control", type: :feature do
  include InspectionTestHelpers
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:unit1) { create(:unit, user: user1) }
  let(:unit2) { create(:unit, user: user2) }
  let(:inspection1) { create(:inspection, user: user1, unit: unit1) }
  let(:inspection2) { create(:inspection, user: user2, unit: unit2, unique_report_number: "TEST-REPORT-123") }

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
          num_low_anchors_pass: true,
          num_high_anchors_pass: true
        }
      }
    }

    expect_access_denied

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

    expect_access_denied

    inspection2.reload
    assessment = inspection2.user_height_assessment
    expect(assessment.containing_wall_height).not_to eq(999.99)
    expect(assessment.platform_height).not_to eq(888.88)
  end

  scenario "allows public access to inspection JSON data" do
    sign_in(user1)
    visit inspection_path(inspection2, format: :json)
    expect(page).to have_content(inspection2.inspection_location)
    expect(page).not_to have_content(I18n.t("inspections.errors.access_denied"))
  end

  scenario "allows updating own assessment data successfully" do
    sign_in(user1)
    visit edit_inspection_path(inspection1, tab: "anchorage")
    expect(page).to have_content("Edit Inspection")

    fill_in_form(:anchorage, :num_low_anchors, "8")
    fill_in_form(:anchorage, :num_high_anchors, "6")
    click_button I18n.t("inspections.buttons.save_assessment")

    expect_updated_message

    inspection1.reload
    expect(inspection1.anchorage_assessment.num_low_anchors).to eq(8)
    expect(inspection1.anchorage_assessment.num_high_anchors).to eq(6)
  end

  scenario "isolates assessment updates between users" do
    sign_in(user1)
    visit edit_inspection_path(inspection1, tab: "user_height")
    fill_in I18n.t("forms.user_height.fields.containing_wall_height"), with: "2.5"
    click_button I18n.t("inspections.buttons.save_assessment")
    expect_updated_message

    click_button I18n.t("sessions.buttons.log_out")
    sign_in(user2)
    visit edit_inspection_path(inspection2, tab: "user_height")

    wall_height_field = find_field(I18n.t("forms.user_height.fields.containing_wall_height"))
    expect(wall_height_field.value).not_to eq("2.5")

    inspection1.reload
    inspection2.reload
    expect(inspection1.user_height_assessment.containing_wall_height).to eq(2.5)
    expect(inspection2.user_height_assessment.containing_wall_height).not_to eq(2.5)
  end
end
