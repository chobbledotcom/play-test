# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Play Zone Inspection Workflow", type: :feature do
  include InspectionTestHelpers

  let(:user) { create(:user) }

  before { sign_in(user) }

  scenario "complete play zone inspection workflow with slide" do
    unit = create_play_zone_unit
    inspection = create_inspection_for_unit(unit)

    verify_correct_tabs_visible(inspection, with_slide: false)
    fill_inspection_tab(inspection, has_slide: true)

    # After setting has_slide, slide tab should appear
    verify_correct_tabs_visible(inspection, with_slide: true)
    fill_all_play_zone_assessments(inspection, with_slide: true)
    complete_inspection(inspection)
    verify_inspection_complete(inspection)
  end

  scenario "complete play zone inspection workflow without slide" do
    unit = create_play_zone_unit
    inspection = create_inspection_for_unit(unit)

    fill_inspection_tab(inspection, has_slide: false)
    verify_correct_tabs_visible(inspection, with_slide: false)
    fill_all_play_zone_assessments(inspection, with_slide: false)
    complete_inspection(inspection)
    verify_inspection_complete(inspection)
  end

  scenario "play zone unit shows correct unit type" do
    visit units_path
    click_button I18n.t("units.buttons.add_unit")

    unit_data = SeedData.unit_fields.merge(name: "Test Play Zone")
    unit_data.each do |field_name, value|
      fill_in_form :units, field_name, value
    end

    select I18n.t("units.unit_types.play_zone"),
      from: I18n.t("forms.units.fields.unit_type")

    submit_form :units
    expect_units_message("created")

    unit = Unit.find_by!(name: "Test Play Zone")
    expect(unit.unit_type).to eq("play_zone")
  end

  scenario "play zone inspection shows correct tabs" do
    unit = create(:unit, user: user, unit_type: :play_zone)
    inspection = create(
      :inspection, user: user, unit: unit,
      has_slide: nil
    )

    visit edit_inspection_path(inspection)

    expect_assessment_tab("structure")
    expect_assessment_tab("user_height")
    expect_assessment_tab("materials")
    expect_assessment_tab("fan")
    expect_assessment_tab("play_zone")

    # Slide tab not shown until has_slide is set
    expect_no_assessment_tab("slide")

    %w[enclosed pat ball_pool catch_bed
      inflatable_game anchorage bungee].each do |tab|
      expect_no_assessment_tab(tab)
    end
  end

  scenario "play zone form renders all i18n fields" do
    unit = create(:unit, user: user, unit_type: :play_zone)
    inspection = create(:inspection, user: user, unit: unit)

    visit edit_inspection_path(inspection, tab: "play_zone")

    expect_form_matches_i18n("forms.play_zone")
  end

  private

  def create_play_zone_unit
    visit units_path
    click_button I18n.t("units.buttons.add_unit")

    unit_data = SeedData.unit_fields
      .merge(name: "Play Zone Unit")
    unit_data.each do |field_name, value|
      fill_in_form :units, field_name, value
    end

    select I18n.t("units.unit_types.play_zone"),
      from: I18n.t("forms.units.fields.unit_type")

    submit_form :units
    expect_units_message("created")

    Unit.find_by!(name: "Play Zone Unit")
  end

  def create_inspection_for_unit(unit)
    inspection = create(
      :inspection, user: user, unit: unit,
      has_slide: nil
    )
    expect(inspection.inspection_type).to eq("play_zone")
    inspection
  end

  def verify_correct_tabs_visible(inspection, with_slide:)
    visit edit_inspection_path(inspection)

    expect_assessment_tab("structure")
    expect_assessment_tab("user_height")
    expect_assessment_tab("materials")
    expect_assessment_tab("fan")
    expect_assessment_tab("play_zone")

    if with_slide
      expect_assessment_tab("slide")
    else
      expect_no_assessment_tab("slide")
    end

    %w[enclosed pat ball_pool catch_bed
      inflatable_game anchorage bungee].each do |tab|
      expect_no_assessment_tab(tab)
    end
  end

  def fill_inspection_tab(inspection, has_slide:)
    visit edit_inspection_path(inspection)

    field_data = SeedData.inspection_fields(passed: true)
    field_data.except!(:is_totally_enclosed, :indoor_only)
    field_data[:has_slide] = has_slide

    field_data.each do |field_name, value|
      fill_inspection_field(field_name, value)
    end

    click_submit_button
  end

  def fill_all_play_zone_assessments(inspection, with_slide:)
    tabs = {
      "structure" => SeedData.structure_fields(passed: true),
      "user_height" =>
        SeedData.user_height_fields(passed: true),
      "materials" => SeedData.materials_fields(passed: true),
      "fan" => SeedData.fan_fields(passed: true),
      "play_zone" =>
        SeedData.play_zone_fields(passed: true)
    }

    if with_slide
      tabs["slide"] = SeedData.slide_fields(passed: true)
    end

    tabs.each do |tab, fields|
      fill_assessment(inspection, tab, fields)
    end

    fill_results_tab(inspection)
  end

  def fill_results_tab(inspection)
    visit edit_inspection_path(inspection, tab: "results")
    fill_assessment_field("results", :passed, true)
    fill_in_risk_assessment(
      "Unit passes all play zone checks"
    )
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
    expect(page).to have_button(
      I18n.t("inspections.buttons.mark_complete")
    )
    click_mark_complete_button
    expect_marked_complete_message
  end

  def verify_inspection_complete(inspection)
    inspection.reload
    expect(inspection.complete?).to be true
    expect(inspection.complete_date).to be_present
  end
end
