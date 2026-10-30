# typed: false

require "rails_helper"

RSpec.feature "Assessment outcome completion", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  background { sign_in(user) }

  scenario "N/A exempts a measurement and Fail needs no comment" do
    visit edit_inspection_path(inspection, tab: "fan")
    fill_in I18n.t("forms.fan.fields.fan_size_type"), with: "1.5 kW"
    fill_in I18n.t("forms.fan.fields.blower_serial"), with: "FAN123"
    fill_in I18n.t("forms.fan.fields.number_of_blowers"), with: 1

    %i[blower_flap blower_finger pat].each do |field|
      choose_pass_fail(I18n.t("forms.fan.fields.#{field}"), "na")
    end
    choose_pass_fail(I18n.t("forms.fan.fields.blower_visual"), "fail")
    submit_form :fan
    expect_updated_message
    expect(inspection.reload.fan_assessment.incomplete_fields)
      .to include(:blower_tube_length, :blower_tube_length_pass)

    visit edit_inspection_path(inspection, tab: "fan")
    choose_pass_fail(I18n.t("forms.fan.fields.blower_tube_length"), "na")
    submit_form :fan
    expect_updated_message

    assessment = inspection.reload.fan_assessment
    expect(assessment.blower_tube_length).to be_nil
    expect(assessment.blower_tube_length_pass).to eq("na")
    expect(assessment.blower_visual_pass).to eq("fail")
    expect(assessment.blower_visual_comment).to be_blank
    expect(assessment.blower_tube_length_comment).to be_blank
    expect(assessment).to be_complete
    visit edit_inspection_path(inspection, tab: "fan")
    expect_assessment_check_mark("fan")
  end
end
