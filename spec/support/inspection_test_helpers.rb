# Helper methods for inspection-related feature tests
# These methods hide i18n complexity and make tests more readable
module InspectionTestHelpers
  # Include FormHelpers to reuse existing methods
  include FormHelpers

  # Boolean fields for inspection forms
  BOOLEAN_FIELDS = %w[has_slide is_totally_enclosed indoor_only passed].freeze

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

  def fill_in_report_number(value)
    fill_in_form(:inspection, :unique_report_number, value)
  end

  def fill_in_risk_assessment(value)
    # Risk assessment is now on the results tab
    fill_in_form(:results, :risk_assessment, value)
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
    inspection.assessment_types.each do |assessment_name, _|
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

  # Field filling methods for inspection workflow
  def fill_inspection_field(field_name, value)
    if BOOLEAN_FIELDS.include?(field_name.to_s)
      value ?
        check_form_radio(:inspection, field_name) :
        uncheck_form_radio(:inspection, field_name)
    else
      fill_in_form :inspection, field_name, value
    end
  end

  def fill_assessment_field(tab_name, field_name, value)
    return if field_name.to_s.end_with?("_comment")

    field_label = get_field_label(tab_name, field_name)

    case value
    when true, false
      if field_name.to_s.end_with?("_pass") || field_name.to_s == "passed"
        choose_pass_fail(field_label, value)
      elsif BOOLEAN_FIELDS.include?(field_name.to_s)
        value ? check_form_radio(tab_name.to_sym, field_name) :
                uncheck_form_radio(tab_name.to_sym, field_name)
      else
        choose_yes_no(field_label, value)
      end
    when :pass, "pass"
      choose_pass_fail(field_label, true)
    when :fail, "fail"
      choose_pass_fail(field_label, false)
    when :na, "na"
      # For now, skip N/A values as the test uses passing values
      # The form should support N/A but we don't need to test it here
    else
      fill_in_form(tab_name.to_sym, field_name, value) if value.present?
    end
  end

  # Unit-related button methods
  def click_units_button(key, confirm: false)
    translation = I18n.t("units.buttons.#{key}")
    if confirm && page.driver.respond_to?(:accept_modal)
      accept_confirm do
        click_button translation
      end
    else
      click_button translation
    end
  end

  def expect_units_message(key)
    expect_i18n_content("units.messages.#{key}")
  end
end

# Include in RSpec configuration
RSpec.configure do |config|
  config.include InspectionTestHelpers, type: :feature
end
