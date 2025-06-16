# Helper methods for inspection-related feature tests
# These methods hide i18n complexity and make tests more readable
module InspectionTestHelpers
  # Include FormHelpers to reuse existing methods
  include FormHelpers

  # Button clicks - these are specific to inspections, not generic form buttons
  def click_mark_complete_button
    click_button I18n.t("inspections.buttons.mark_complete")
  end

  def click_switch_to_in_progress_button
    click_button I18n.t("inspections.buttons.switch_to_in_progress")
  end

  def click_submit_button
    submit_form(:inspection)
  end

  def click_add_inspection_button
    click_button I18n.t("units.buttons.add_inspection")
  end

  def click_add_inspection_on_index_button
    click_button I18n.t("inspections.buttons.add_inspection")
  end

  def click_delete_button
    click_button I18n.t("inspections.buttons.delete")
  end

  def click_update_button
    click_button I18n.t("inspections.buttons.update")
  end

  # Form filling - use the generic form helpers
  def fill_in_location(value)
    fill_in_form(:inspection, :inspection_location, value)
  end

  def fill_in_report_number(value)
    fill_in_form(:inspection, :unique_report_number, value)
  end

  def fill_in_risk_assessment(value)
    fill_in_form(:inspection, :risk_assessment, value)
  end

  # Expectations for messages
  def expect_cannot_edit_complete_message
    expect(page).to have_content(I18n.t("inspections.messages.cannot_edit_complete"))
  end

  def expect_marked_in_progress_message
    expect(page).to have_content(I18n.t("inspections.messages.marked_in_progress"))
  end

  def expect_marked_complete_message
    expect(page).to have_content(I18n.t("inspections.messages.marked_complete"))
  end

  def expect_updated_message
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
  end

  def expect_deleted_message
    expect(page).to have_content(I18n.t("inspections.messages.deleted"))
  end

  def expect_access_denied_message
    expect_access_denied
  end

  def expect_access_denied
    expect(page).to have_content(I18n.t("inspections.errors.access_denied"))
    expect(current_path).to eq(inspections_path)
  end

  def expect_cannot_complete_message
    expect(page).to have_content(I18n.t("inspections.messages.cannot_complete").split(":").first)
  end

  # Button expectations
  def expect_suggested_id_button(inspection)
    expected_text = I18n.t("inspections.buttons.use_suggested_id", id: inspection.id)
    expect(page).to have_button(expected_text)
  end

  def expect_no_suggested_id_button(inspection)
    expected_text = I18n.t("inspections.buttons.use_suggested_id", id: inspection.id)
    expect(page).not_to have_button(expected_text)
  end

  def expect_safety_standard(table, key, **args)
    string = I18n.t("safety_standards.#{table}.#{key}", **args)
    expect(page).to have_content(string)
  end

  # Data helpers
  def fill_assessments_with_complete_data(inspection)
    inspection.reload
    Inspection::ASSESSMENT_TYPES.each do |assessment_name, _|
      assessment = inspection.send(assessment_name)
      assessment.update!(attributes_for(assessment_name, :complete))
    end
  end

  # Navigation helpers
  def visit_inspection_edit(inspection)
    visit edit_inspection_path(inspection)
  end

  def visit_inspection_show(inspection)
    visit inspection_path(inspection)
  end

  def expect_on_inspection_show_page(inspection)
    expect(page).to have_current_path(inspection_path(inspection))
  end

  def expect_on_inspection_edit_page(inspection)
    expect(page).to have_current_path(edit_inspection_path(inspection))
  end
end

# Include in RSpec configuration
RSpec.configure do |config|
  config.include InspectionTestHelpers, type: :feature
end
