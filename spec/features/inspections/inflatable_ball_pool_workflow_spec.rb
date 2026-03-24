# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Inflatable Ball Pool Inspection Workflow", type: :feature do
  include InspectionTestHelpers

  let(:user) { create(:user) }

  before { sign_in(user) }

  scenario "complete inflatable ball pool inspection workflow" do
    unit = create_ball_pool_unit
    inspection = create_inspection_for_ball_pool_unit(unit)

    verify_correct_tabs_visible(inspection)
    fill_inspection_tab(inspection)
    fill_all_ball_pool_assessments(inspection)
    complete_inspection(inspection)
    verify_inspection_complete(inspection)
  end

  scenario "ball pool unit shows correct unit type" do
    visit units_path
    click_button I18n.t("units.buttons.add_unit")

    unit_data = SeedData.unit_fields.merge(name: "Test Ball Pool")
    unit_data.each do |field_name, value|
      fill_in_form :units, field_name, value
    end

    select I18n.t("units.unit_types.inflatable_ball_pool"),
      from: I18n.t("forms.units.fields.unit_type")

    submit_form :units
    expect_units_message("created")

    unit = Unit.find_by!(name: "Test Ball Pool")
    expect(unit.unit_type).to eq("inflatable_ball_pool")
  end

  scenario "ball pool inspection shows correct assessment tabs" do
    unit = create(:unit, user: user, unit_type: :inflatable_ball_pool)
    inspection = create(:inspection, user: user, unit: unit)

    visit edit_inspection_path(inspection)

    # Should have ball pool shared tabs
    expect_assessment_tab("structure")
    expect_assessment_tab("materials")
    expect_assessment_tab("fan")
    expect_assessment_tab("ball_pool")

    # Should NOT have bouncy castle specific tabs
    expect_no_assessment_tab("user_height")
    expect_no_assessment_tab("slide")
    expect_no_assessment_tab("anchorage")
    expect_no_assessment_tab("enclosed")
    expect_no_assessment_tab("pat")
  end

  scenario "ball pool inspection form renders all i18n sections and fields" do
    unit = create(:unit, user: user, unit_type: :inflatable_ball_pool)
    inspection = create(:inspection, user: user, unit: unit)

    visit edit_inspection_path(inspection, tab: "ball_pool")

    expect_form_matches_i18n("forms.ball_pool")
  end

  private

  def create_ball_pool_unit
    visit units_path
    click_button I18n.t("units.buttons.add_unit")

    unit_data = SeedData.unit_fields.merge(name: "Ball Pool Unit")
    unit_data.each do |field_name, value|
      fill_in_form :units, field_name, value
    end

    select I18n.t("units.unit_types.inflatable_ball_pool"),
      from: I18n.t("forms.units.fields.unit_type")

    submit_form :units
    expect_units_message("created")

    Unit.find_by!(name: "Ball Pool Unit")
  end

  def create_inspection_for_ball_pool_unit(unit)
    inspection = create(:inspection, user: user, unit: unit)
    expect(inspection.inspection_type).to eq("inflatable_ball_pool")
    inspection
  end

  def verify_correct_tabs_visible(inspection)
    visit edit_inspection_path(inspection)

    expect_assessment_tab("structure")
    expect_assessment_tab("materials")
    expect_assessment_tab("fan")
    expect_assessment_tab("ball_pool")

    %w[anchorage enclosed pat slide user_height].each do
      expect_no_assessment_tab(it)
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

  def fill_all_ball_pool_assessments(inspection)
    # Fill shared assessments
    fill_assessment(inspection, "structure",
      SeedData.structure_fields(passed: true))
    fill_assessment(inspection, "materials",
      SeedData.materials_fields(passed: true))
    fill_assessment(inspection, "fan",
      SeedData.fan_fields(passed: true))

    # Fill ball pool specific assessment
    fill_assessment(inspection, "ball_pool",
      SeedData.ball_pool_fields(passed: true))

    # Fill results tab
    visit edit_inspection_path(inspection, tab: "results")
    fill_assessment_field("results", :passed, true)
    fill_in_risk_assessment("Unit passes all ball pool checks")
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
