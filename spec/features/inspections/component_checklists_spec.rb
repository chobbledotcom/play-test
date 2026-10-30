# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Component-aware inspection lifecycle", type: :feature do
  let(:user) { create(:user) }

  around do |example|
    with_unit_badges_disabled { example.run }
  end

  background { sign_in(user) }

  scenario "previews a pillow configuration without saving the unit" do
    visit new_unit_path
    fill_in_form :units, :name, "Movable pillow"
    fill_in_form :units, :serial, "PILLOW-CONFIG"
    fill_in_form :units, :description, "Pillow for changing installation sites"
    select I18n.t("units.unit_types.bouncing_pillow"),
      from: I18n.t("forms.units.fields.unit_type")

    expect {
      click_button I18n.t("forms.units.buttons.apply_type")
    }.not_to change(Unit, :count)

    choose_yes_no I18n.t("forms.units.fields.has_blower"), true
    choose_yes_no I18n.t("forms.units.fields.has_fencing"), false
    submit_form :units

    unit = Unit.find_by!(serial: "PILLOW-CONFIG")
    expect(unit).to be_bouncing_pillow
    expect(unit.has_blower).to be true
    expect(unit.has_fencing).to be false
    expect(unit.has_slide).to be false
    expect(unit.is_totally_enclosed).to be false
  end

  scenario "uses the sole enabled non-castle type and rejects impossible components" do
    original = Rails.configuration.units
    Rails.configuration.units = UnitsConfig.new(
      badges_enabled: false,
      reports_unbranded: original.reports_unbranded,
      pdf_filename_prefix: original.pdf_filename_prefix,
      enabled_unit_types: %w[catch_bed]
    )

    visit new_unit_path
    fill_in_form :units, :name, "Catch bed"
    fill_in_form :units, :serial, "SOLE-CATCH"
    fill_in_form :units, :description, "Rodeo catch bed"
    submit_form :units

    unit = Unit.find_by!(serial: "SOLE-CATCH")
    expect(unit).to be_catch_bed
    page.driver.submit :patch, unit_path(unit),
      {unit: {has_slide: true, is_totally_enclosed: true}}
    expect(page).to have_content(
      I18n.t("activerecord.errors.messages.not_applicable_to_unit_type")
    )
    expect(unit.reload.has_slide).to be false
    expect(unit.is_totally_enclosed).to be false
  ensure
    Rails.configuration.units = original
  end

  scenario "snapshots physical configuration independently of later unit edits" do
    unit = create(:unit, user:, has_slide: true, is_totally_enclosed: true)
    inspection = create(:inspection, user:, unit:, has_slide: true,
      is_totally_enclosed: true, indoor_only: false)
    unit.update!(has_slide: false, is_totally_enclosed: false)

    visit edit_inspection_path(inspection)
    expect_assessment_tab "slide"
    expect_assessment_tab "enclosed"
    expect(inspection.reload.has_slide).to be true
    expect(inspection.is_totally_enclosed).to be true
  end

  scenario "changes a draft's unit without discarding compatible answers" do
    castle = create(:unit, user:, has_slide: true, is_totally_enclosed: true)
    game = create(:unit, user:, unit_type: :inflatable_game,
      name: "Target game", has_slide: false, is_totally_enclosed: false)
    inspection = create(:inspection, user:, unit: castle)
    inspection.structure_assessment.update!(seam_integrity_pass: "fail",
      seam_integrity_comment: "Repair required", platform_height: 1500,
      platform_height_pass: "pass")
    inspection.fan_assessment.update!(blower_serial: "RETAINED-FAN")
    inspection.slide_assessment.update!(slide_platform_height: 1.5)
    inspection.enclosed_assessment.update!(exit_number: 2)

    visit edit_inspection_path(inspection)
    click_link I18n.t("inspections.buttons.change_unit")
    within(find("li", text: game.name)) do
      click_button I18n.t("units.actions.select")
    end

    expect(inspection.reload).to be_inflatable_game
    expect(inspection.unit_id).to eq(game.id)
    expect(inspection.structure_assessment.seam_integrity_pass).to eq("fail")
    expect(inspection.structure_assessment.seam_integrity_comment)
      .to eq("Repair required")
    expect(inspection.structure_assessment.platform_height).to be_nil
    expect(inspection.fan_assessment.blower_serial).to eq("RETAINED-FAN")
    expect(Assessments::SlideAssessment.find_by(inspection:)).to be_nil
    expect(Assessments::EnclosedAssessment.find_by(inspection:)).to be_nil
    expect_no_assessment_tab "slide"
    expect_no_assessment_tab "enclosed"
  end

  scenario "reclassifies an actively edited draft only when its changes are saved" do
    unit = create(:unit, user:)
    inspection = create(:inspection, user:, unit:)
    inspection.fan_assessment.update!(blower_serial: "SAME-BLOWER")
    unit.update!(unit_type: :catch_bed)

    visit edit_inspection_path(inspection)
    expect_assessment_tab "catch_bed"
    expect_no_assessment_tab "slide"
    expect(inspection.reload).to be_bouncy_castle
    submit_form :inspection

    expect(inspection.reload).to be_catch_bed
    expect(inspection.has_slide).to be false
    expect(inspection.is_totally_enclosed).to be false
    expect(inspection.fan_assessment.blower_serial).to eq("SAME-BLOWER")
  end

  scenario "leaves a historical pillow untouched until editing and requires its new checks" do
    unit = create(:unit, user:, unit_type: :bouncing_pillow, has_blower: true)
    inspection = create(:inspection, :completed, user:, unit:,
      has_blower: true, indoor_only: false)
    inspection.bouncing_pillow_assessment.destroy!
    original_fan = inspection.fan_assessment.attributes
    unit.update_columns(
      InspectionChecklist::COMPONENT_FIELDS.to_h { |field| [field, nil] }
    )
    inspection.update_columns(checklist_revision: nil, inspection_location: nil,
      has_blower: nil, has_fencing: nil)
    original = inspection.reload.attributes

    visit inspection_path(inspection)
    expect(inspection.reload.attributes).to eq(original)
    expect(Assessments::BouncingPillowAssessment.find_by(inspection:)).to be_nil

    click_button I18n.t("inspections.buttons.switch_to_in_progress")
    expect(inspection.reload.checklist_revision).to eq(2)
    expect(inspection).not_to be_complete
    expect(page).to have_content(I18n.t("forms.bouncing_pillow.header"))
    expect(Assessments::BouncingPillowAssessment.find_by(inspection:)).to be_nil
    expect(inspection.reload.fan_assessment?.attributes).to eq(original_fan)
    page.driver.submit :patch, complete_inspection_path(inspection), {}
    expect(inspection.reload).not_to be_complete

    visit edit_inspection_path(inspection)
    fill_in_form :inspection, :inspection_location, "Current installation site"
    choose_yes_no I18n.t("forms.inspection.fields.has_blower"), true
    choose_yes_no I18n.t("forms.inspection.fields.has_fencing"), false
    submit_form :inspection
    visit edit_inspection_path(inspection, tab: "bouncing_pillow")
    inspection.bouncing_pillow_assessment.form_schema.fields.each do |field|
      label = I18n.t("forms.bouncing_pillow.fields.#{field.name}")
      choose_pass_fail label, "na"
    end
    submit_form :bouncing_pillow
    visit edit_inspection_path(inspection, tab: "results")
    click_button I18n.t("inspections.buttons.mark_complete")

    expect(inspection.reload).to be_complete
    expect(inspection.inspection_location).to eq("Current installation site")
    expect(inspection.bouncing_pillow_assessment.internal_pressure).to be_nil
    expect(inspection.bouncing_pillow_assessment.internal_pressure_pass)
      .to eq("na")
  end
end
