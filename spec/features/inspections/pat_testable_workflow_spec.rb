# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "PAT Testable Inspection Workflow", type: :feature do
  include InspectionTestHelpers

  let(:user) { create(:user) }

  before { sign_in(user) }

  scenario "complete PAT testable inspection workflow" do
    # Create a PAT testable unit
    unit = create_pat_testable_unit

    # Create inspection for the unit
    inspection = create_inspection_for_pat_unit(unit)

    # Verify only PAT assessment tab appears (not bouncy castle tabs)
    verify_only_pat_tab_visible(inspection)

    # Fill in the PAT assessment form
    fill_pat_assessment(inspection)

    # Mark inspection complete
    complete_inspection(inspection)

    # Verify inspection is complete
    verify_inspection_complete(inspection)
  end

  scenario "PAT testable unit shows correct unit type" do
    visit units_path
    click_button I18n.t("units.buttons.add_unit")

    unit_data = SeedData.unit_fields.merge(name: "Test PAT Appliance")
    unit_data.each do |field_name, value|
      fill_in_form :units, field_name, value
    end

    select I18n.t("units.unit_types.pat_testable"),
      from: I18n.t("forms.units.fields.unit_type")

    submit_form :units
    expect_units_message("created")

    unit = Unit.find_by!(name: "Test PAT Appliance")
    expect(unit.unit_type).to eq("pat_testable")
  end

  scenario "PAT inspection does not show bouncy castle assessment tabs" do
    unit = create(:unit, user: user, unit_type: :pat_testable)
    inspection = create(:inspection, user: user, unit: unit)

    visit edit_inspection_path(inspection)

    # Should have PAT tab
    expect_assessment_tab("pat")

    # Should NOT have bouncy castle tabs
    expect_no_assessment_tab("structure")
    expect_no_assessment_tab("materials")
    expect_no_assessment_tab("anchorage")
    expect_no_assessment_tab("user_height")
    expect_no_assessment_tab("slide")
    expect_no_assessment_tab("enclosed")

    # Fan tab should also not appear for PAT testable
    expect_no_assessment_tab("fan")
  end

  private

  def create_pat_testable_unit
    visit units_path
    click_button I18n.t("units.buttons.add_unit")

    unit_data = SeedData.unit_fields.merge(name: "PAT Test Device")
    unit_data.each do |field_name, value|
      fill_in_form :units, field_name, value
    end

    select I18n.t("units.unit_types.pat_testable"),
      from: I18n.t("forms.units.fields.unit_type")

    submit_form :units
    expect_units_message("created")

    Unit.find_by!(name: "PAT Test Device")
  end

  def create_inspection_for_pat_unit(unit)
    # Create inspection via factory (confirm dialogs require JS driver)
    inspection = create(:inspection, user: user, unit: unit)
    expect(inspection.inspection_type).to eq("pat_testable")
    inspection
  end

  def verify_only_pat_tab_visible(inspection)
    visit edit_inspection_path(inspection)

    # PAT tab should be visible
    expect_assessment_tab("pat")

    # Bouncy castle tabs should NOT be visible
    %w[anchorage enclosed fan materials slide structure user_height].each do
      expect_no_assessment_tab(it)
    end
  end

  def fill_pat_assessment(inspection)
    visit edit_inspection_path(inspection, tab: "pat")

    field_data = SeedData.pat_fields(passed: true)
    field_data.each do |field_name, value|
      fill_assessment_field("pat", field_name, value)
    end

    submit_form :pat
    expect_updated_message

    # Also fill in the results tab
    visit edit_inspection_path(inspection, tab: "results")
    fill_assessment_field("results", :passed, true)
    fill_in_risk_assessment("Unit passes all PAT tests")
    submit_form :results
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
