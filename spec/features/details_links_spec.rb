require "rails_helper"

RSpec.feature "Details element link behavior", js: true do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user:) }
  let(:inspection) do
    inspection = create(:inspection, :completed, user:, unit:)
    inspection.update!(complete_date: nil)
    inspection.update_column(:inspection_location, nil)
    inspection
  end

  before do
    sign_in(user)
    visit edit_inspection_path(inspection)
  end

  scenario "clicking links inside details elements navigates immediately" do
    details = find("details#incomplete_fields")
    expect(details[:open]).to be_falsey

    find("summary.incomplete-fields-summary").click
    expect(details[:open]).to be_truthy

    details.find("a", match: :first).click

    expect(page).to have_current_path(edit_inspection_path(inspection, tab: "inspection"))
  end

  scenario "multiple clicks on links work consistently" do
    inspection.user_height_assessment.update_column(:tallest_user_height, nil)

    find("summary.incomplete-fields-summary").click

    within("details#incomplete_fields") do
      find("a", text: I18n.t("forms.inspection.header")).click
    end

    expect(page).to have_current_path(edit_inspection_path(inspection, tab: "inspection"))

    find("summary.incomplete-fields-summary").click
    within("details#incomplete_fields") do
      find("a", text: I18n.t("forms.user_height.header")).click
    end

    expect(page).to have_current_path(edit_inspection_path(inspection, tab: "user_height"))
  end
end
