# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Catch Bed Inspection Workflow", type: :feature do
  include InspectionTestHelpers

  let(:user) { create(:user) }

  before { sign_in(user) }

  scenario "complete catch bed inspection workflow" do
    unit = create_catch_bed_unit
    inspection = create_inspection_for_catch_bed_unit(unit)

    verify_correct_tabs_visible(inspection)
    fill_inspection_tab(inspection)
    fill_all_catch_bed_assessments(inspection)
    complete_inspection(inspection)
    verify_inspection_complete(inspection)
  end

  scenario "catch bed unit shows correct unit type" do
    visit units_path
    click_button I18n.t("units.buttons.add_unit")

    unit_data = SeedData.unit_fields.merge(name: "Test Catch Bed")
    unit_data.each do |field_name, value|
      fill_in_form :units, field_name, value
    end

    select I18n.t("units.unit_types.catch_bed"),
      from: I18n.t("forms.units.fields.unit_type")

    submit_form :units
    expect_units_message("created")

    unit = Unit.find_by!(name: "Test Catch Bed")
    expect(unit.unit_type).to eq("catch_bed")
  end

  scenario "catch bed inspection shows correct assessment tabs" do
    unit = create(:unit, user: user, unit_type: :catch_bed)
    inspection = create(:inspection, user: user, unit: unit)

    visit edit_inspection_path(inspection)

    # Should have catch bed shared tabs
    expect_assessment_tab("structure")
    expect_assessment_tab("anchorage")
    expect_assessment_tab("materials")
    expect_assessment_tab("fan")
    expect_assessment_tab("catch_bed")

    # Should NOT have other unit type specific tabs
    expect_no_assessment_tab("user_height")
    expect_no_assessment_tab("slide")
    expect_no_assessment_tab("enclosed")
    expect_no_assessment_tab("pat")
    expect_no_assessment_tab("ball_pool")
    expect_no_assessment_tab("inflatable_game")
  end

  scenario "catch bed inspection form renders all i18n sections and fields" do
    unit = create(:unit, user: user, unit_type: :catch_bed)
    inspection = create(:inspection, user: user, unit: unit)

    visit edit_inspection_path(inspection, tab: "catch_bed")

    expect_form_matches_i18n("forms.catch_bed")
  end

  private

  def create_catch_bed_unit
    visit units_path
    click_button I18n.t("units.buttons.add_unit")

    unit_data = SeedData.unit_fields.merge(name: "Catch Bed Unit")
    unit_data.each do |field_name, value|
      fill_in_form :units, field_name, value
    end

    select I18n.t("units.unit_types.catch_bed"),
      from: I18n.t("forms.units.fields.unit_type")

    submit_form :units
    expect_units_message("created")

    Unit.find_by!(name: "Catch Bed Unit")
  end

  def create_inspection_for_catch_bed_unit(unit)
    inspection = create(:inspection, user: user, unit: unit)
    expect(inspection.inspection_type).to eq("catch_bed")
    inspection
  end

  def verify_correct_tabs_visible(inspection)
    visit edit_inspection_path(inspection)

    expect_assessment_tab("structure")
    expect_assessment_tab("anchorage")
    expect_assessment_tab("materials")
    expect_assessment_tab("fan")
    expect_assessment_tab("catch_bed")

    %w[enclosed pat slide user_height ball_pool inflatable_game].each do |tab|
      expect_no_assessment_tab(tab)
    end
  end

  def fill_inspection_tab(inspection)
    visit edit_inspection_path(inspection)

    field_data = SeedData.inspection_fields(passed: true)
    field_data.except!(:has_slide, :is_totally_enclosed, :indoor_only)

    field_data.each do |field_name, value|
      fill_inspection_field(field_name, value)
    end

    click_submit_button
  end

  def fill_all_catch_bed_assessments(inspection)
    {
      "structure" => SeedData.structure_fields(passed: true),
      "anchorage" => SeedData.anchorage_fields(passed: true),
      "materials" => SeedData.materials_fields(passed: true),
      "fan" => SeedData.fan_fields(passed: true),
      "catch_bed" => SeedData.catch_bed_fields(passed: true)
    }.each { |tab, fields| fill_assessment(inspection, tab, fields) }

    fill_results_tab(inspection)
  end

  def fill_results_tab(inspection)
    visit edit_inspection_path(inspection, tab: "results")
    fill_assessment_field("results", :passed, true)
    fill_in_risk_assessment("Unit passes all catch bed checks")
    submit_form :results
    expect_updated_message
  end

  def fill_assessment(inspection, tab_name, field_data)
    visit edit_inspection_path(inspection, tab: tab_name)

    field_data.each do |field_name, value|
      fill_assessment_field(tab_name, field_name, value)
    end

    submit_form tab_name.to_sym
    expect_updated_message
  end

  def complete_inspection(inspection)
    visit edit_inspection_path(inspection)
    expect(page).to have_button(I18n.t("inspections.buttons.mark_complete"))
    click_mark_complete_button
    expect_marked_complete_message
  end

  def verify_inspection_complete(inspection)
    inspection.reload
    expect(inspection.complete?).to be true
    expect(inspection.complete_date).to be_present
  end
end
