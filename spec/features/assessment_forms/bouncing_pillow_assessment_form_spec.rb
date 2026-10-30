# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Pillow assessment", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user:, unit_type: :bouncing_pillow) }
  let(:inspection) do
    create(:inspection, user:, unit:, has_fencing: false,
      inspection_location: "North field", checklist_revision: 2)
  end

  before { sign_in(user) }

  def answer_pillow(inspection, outcome: "pass")
    visit edit_inspection_path(inspection, tab: "bouncing_pillow")
    assessment = inspection.bouncing_pillow_assessment
    sample = build(:bouncing_pillow_assessment, :complete)
    assessment.form_schema.fields.each do |field|
      name = field.name
      label = I18n.t("forms.bouncing_pillow.fields.#{name}")
      fill_in label, with: sample[name] if sample.has_attribute?(name)
      choose_pass_fail(label, outcome)
    end
  end

  scenario "completes the applicable checks without fencing or comments" do
    answer_pillow(inspection)
    submit_form :bouncing_pillow
    expect_updated_message

    pillow = inspection.reload.bouncing_pillow_assessment
    expect(pillow).to be_complete
    expect(pillow.incomplete_fields).to be_empty
    expect(pillow.number_of_users).to eq(22)
    expect(pillow.fencing_distance).to be_nil
  end

  scenario "saves all fencing measurements in the single pillow assessment" do
    inspection.update!(has_fencing: true)
    answer_pillow(inspection)
    submit_form :bouncing_pillow
    expect_updated_message

    pillow = inspection.reload.bouncing_pillow_assessment
    expect(pillow).to be_complete
    expect(pillow.fencing_distance).to eq(2.3)
    expect(pillow.fencing_height).to eq(0.9)
    expect(pillow.fencing_gateways).to eq(2)
    expect(pillow.fencing_entrapment_pass).to eq("pass")
  end

  scenario "N/A checks complete without measurements or comments" do
    visit edit_inspection_path(inspection, tab: "bouncing_pillow")
    inspection.bouncing_pillow_assessment.form_schema.fields.each do |field|
      name = field.name
      label = I18n.t("forms.bouncing_pillow.fields.#{name}")
      choose_pass_fail(label, "na")
    end
    submit_form :bouncing_pillow
    expect_updated_message

    pillow = inspection.reload.bouncing_pillow_assessment
    expect(pillow).to be_complete
    expect(pillow.internal_pressure).to be_nil
    expect(pillow.internal_pressure_pass).to eq("na")
  end

  scenario "failed checks allow optional comments and still complete" do
    answer_pillow(inspection, outcome: "fail")
    find("textarea[name$='[foundation_comment]']", visible: :all)
      .set("Sand foundation requires attention")
    submit_form :bouncing_pillow
    expect_updated_message

    pillow = inspection.reload.bouncing_pillow_assessment
    expect(pillow).to be_complete
    expect(pillow.foundation_pass).to eq("fail")
    expect(pillow.foundation_comment).to eq("Sand foundation requires attention")
  end

  scenario "moving the same pillow retains separate site findings" do
    answer_pillow(inspection)
    fill_in I18n.t("forms.bouncing_pillow.fields.slope"), with: "2.5"
    submit_form :bouncing_pillow
    expect_updated_message

    second = create(:inspection, user:, unit:, has_fencing: false,
      inspection_location: "South field", checklist_revision: 2)
    answer_pillow(second)
    fill_in I18n.t("forms.bouncing_pillow.fields.slope"), with: "4.0"
    fill_in I18n.t("forms.bouncing_pillow.fields.clear_area"), with: "3.5"
    submit_form :bouncing_pillow
    expect_updated_message

    expect(inspection.reload.inspection_location).to eq("North field")
    expect(inspection.bouncing_pillow_assessment.slope).to eq(2.5)
    expect(inspection.bouncing_pillow_assessment.clear_area).to eq(2.1)
    expect(second.reload.inspection_location).to eq("South field")
    expect(second.bouncing_pillow_assessment.slope).to eq(4.0)
    expect(second.bouncing_pillow_assessment.clear_area).to eq(3.5)
    expect(second.bouncing_pillow_assessment).to be_complete
  end
end
