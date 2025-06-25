require "rails_helper"
require_relative "../../../db/seeds/seed_data"

class InspectionWorkflow
  include Capybara::DSL
  include RSpec::Matchers
  include Rails.application.routes.url_helpers
  include RadioButtonHelpers
  include FactoryBot::Syntax::Methods
  include InspectionTestHelpers
  include FormHelpers

  BOOLEAN_FIELDS = %w[has_slide is_totally_enclosed passed].freeze

  attr_reader :user
  attr_reader :unit
  attr_reader :inspection
  attr_reader :second_inspection
  attr_reader :options

  def initialize(has_slide:, is_totally_enclosed:)
    @options = {has_slide:, is_totally_enclosed:}
  end

  def t(key, **options)
    I18n.t(key, raise: true, **options)
  end

  def execute
    setup_user
    setup_unit_and_inspection
    fill_and_verify_inspection
    fail_to_delete_unit
    verify_second_inspection_prefilling
    delete_second_inspection
    self
  end

  def applicable_tabs
    @inspection.applicable_tabs.reject { |tab| tab == "inspection" }
  end

  private

  def setup_user
    @user = register_new_user
    verify_inactive_user_warning
    activate_user
    verify_no_warning_after_activation
  end

  def setup_unit_and_inspection
    @unit = create_test_unit
    @inspection = create_inspection_for_unit
    verify_inspection_not_completable
  end

  def fill_and_verify_inspection
    fill_general_inspection_details
    verify_inspection_not_completable
    verify_change_unit_functionality
    fill_all_assessments
    mark_inspection_complete
    verify_inspection_complete
  end

  def register_new_user
    visit root_path
    click_link t("users.titles.register")

    user_data = SeedData.user_fields
    user_data.each do |field_name, value|
      fill_in_form :user_new, field_name, value
    end

    submit_form :user_new
    User.find_by!(email: user_data[:email])
  end

  def verify_inactive_user_warning
    expect(page).to have_content(t("users.messages.user_inactive"))
  end

  def activate_user
    @user.update!(active_until: 5.minutes.from_now)
  end

  def verify_no_warning_after_activation
    visit current_path
    expect(page).not_to have_content(
      t("users.messages.user_inactive")
    )
  end

  def create_test_unit
    visit root_path
    click_link "Units"
    click_units_button("add_unit")

    unit_data = SeedData.unit_fields.merge(
      name: "Test Bouncy Castle"
    )

    unit_data.each do |field_name, value|
      fill_in_form :units, field_name, value
    end

    submit_form :units
    expect_units_message("created")

    Unit.find_by!(
      name: unit_data[:name],
      serial: unit_data[:serial]
    )
  end

  def create_inspection_for_unit
    visit root_path
    click_link "Units"
    click_link "Test Bouncy Castle"

    click_units_button("add_inspection")
    expect(page).to have_content(t("inspections.titles.edit"))

    @unit.inspections.order(created_at: :desc).first.tap do |inspection|
      expect(inspection).to be_present
    end
  end

  def fill_general_inspection_details
    field_data = SeedData.inspection_fields(passed: true).merge(@options)

    field_data.each do |field_name, value|
      fill_inspection_field(field_name, value)
    end

    click_submit_button

    @inspection.reload
    expect(@inspection.has_slide).to eq(
      @options[:has_slide]
    )
    expect(@inspection.is_totally_enclosed).to eq(
      @options[:is_totally_enclosed]
    )
  end

  def fill_inspection_field(field_name, value)
    if BOOLEAN_FIELDS.include?(field_name.to_s)
      value ?
        check_form_radio(:inspection, field_name) :
        uncheck_form_radio(:inspection, field_name)
    else
      fill_in_form :inspection, field_name, value
    end
  end

  def fill_all_assessments
    applicable_tabs.each_with_index do |tab_name, index|
      # Before filling this tab, verify check marks are correct
      verify_assessment_check_marks(completed_tabs: applicable_tabs[0...index])

      fill_assessment_tab(tab_name)

      if index < applicable_tabs.length - 1
        verify_inspection_not_completable
      end
    end

    # After all assessments are complete, verify all tabs have check marks
    verify_assessment_check_marks(completed_tabs: applicable_tabs)
  end

  def fill_assessment_tab(tab_name)
    visit edit_inspection_path(@inspection, tab: tab_name)
    field_data = SeedData.send(
      "#{tab_name}_fields",
      passed: true
    )

    field_data.each do |field_name, value|
      fill_assessment_field(tab_name, field_name, value)
    end

    submit_form tab_name.to_sym
    expect_updated_message

    if tab_name == "results"
      # Results tab doesn't have an assessment model, check the inspection fields directly
      @inspection.reload
      expect(@inspection.passed).to be true
    else
      assessment = @inspection.reload.send("#{tab_name}_assessment")
      expect(assessment.complete?).to be true
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
    else
      fill_in_form(tab_name.to_sym, field_name, value) if value.present?
    end
  end

  def get_field_label(tab_name, field_name)
    field_str = field_name.to_s

    if field_str.end_with?("_pass")
      pass_key = "forms.#{tab_name}.fields.#{field_name}"
      base_key = "forms.#{tab_name}.fields.#{field_str.chomp("_pass")}"

      I18n.exists?(pass_key) ? I18n.t(pass_key) : I18n.t(base_key)
    else
      I18n.t("forms.#{tab_name}.fields.#{field_name}")
    end
  end

  def click_units_button(key)
    click_button t("units.buttons.#{key}")
  end

  def expect_units_message(key)
    expect(page).to have_content(t("units.messages.#{key}"))
  end

  def verify_inspection_not_completable
    visit edit_inspection_path(@inspection)

    incomplete_fields = @inspection.incomplete_fields
    if incomplete_fields.any?
      # Count total fields across all forms, not just forms with incomplete fields
      total_field_count = incomplete_fields.sum { |form| form[:fields].count }

      expect(page).to have_content(
        t("assessments.incomplete_fields.show_fields", count: total_field_count)
      )

      find("details#incomplete_fields summary").click
      expect(page).to have_content(
        t("assessments.incomplete_fields.description")
      )

      # The button should not be visible when there are incomplete fields
      expect(page).not_to have_button(t("inspections.buttons.mark_complete"))
    end
  end

  def verify_assessment_check_marks(completed_tabs:)
    visit edit_inspection_path(@inspection)

    # Main inspection tab always has check mark (it's completed in fill_general_inspection_details)
    within("nav#tabs") do
      # Check if inspection tab is current (span) or link
      if page.has_css?("span", text: t("forms.inspection.header"))
        expect(page).to have_css("span", text: "#{t("forms.inspection.header")} ✓")
      else
        expect(page).to have_link("#{t("forms.inspection.header")} ✓")
      end

      # Check each assessment tab
      applicable_tabs.each do |tab_name|
        tab_text = t("forms.#{tab_name}.header")

        if completed_tabs.include?(tab_name)
          # Should have check mark
          if page.has_css?("span", text: tab_text)
            expect(page).to have_css("span", text: "#{tab_text} ✓")
          else
            expect(page).to have_link("#{tab_text} ✓")
          end
        elsif page.has_css?("span", text: tab_text)
          # Should NOT have check mark
          expect(page).to have_css("span", text: tab_text)
          expect(page).not_to have_css("span", text: "#{tab_text} ✓")
        else
          expect(page).to have_link(tab_text)
          expect(page).not_to have_link("#{tab_text} ✓")
        end
      end
    end
  end

  def mark_inspection_complete
    visit edit_inspection_path(@inspection)
    # Verify the button is now visible since there are no incomplete fields
    expect(page).to have_button(t("inspections.buttons.mark_complete"))
    click_mark_complete_button
    expect_marked_complete_message
  end

  def verify_inspection_complete
    @inspection.reload
    expect(@inspection.complete?).to be true
    expect(@inspection.complete_date).to be_present

    visit inspection_path(@inspection, format: :pdf)
    expect(page.status_code).to eq(200)

    verify_log_functionality
  end

  def verify_log_functionality
    # Check that log link appears on inspection show page
    visit inspection_path(@inspection)
    expect(page).to have_link(t("inspections.buttons.log"))

    # Visit the log page
    click_link t("inspections.buttons.log")
    expect(page).to have_current_path(log_inspection_path(@inspection))
    expect(page).to have_content(t("inspections.titles.log", inspection: @inspection.id))

    # Verify events are shown
    expect(page).to have_content("Created")
    expect(page).to have_content("Updated")
    expect(page).to have_content("Completed")

    # Navigate back to inspection
    click_link t("inspections.links.back_to_inspection")
    expect(page).to have_current_path(inspection_path(@inspection))
  end

  def verify_second_inspection_prefilling
    update_first_inspection_dates
    create_second_inspection
    verify_boolean_fields_prefilled
    save_main_form
    verify_assessments_prefill_and_complete
    mark_second_inspection_complete
    verify_date_handling
  end

  def update_first_inspection_dates
    @inspection.update!(
      inspection_date: 7.days.ago,
      complete_date: 7.days.ago
    )
  end

  def create_second_inspection
    visit unit_path(@unit)
    click_units_button("add_inspection")
    @second_inspection = @unit.inspections.order(created_at: :desc).first
  end

  def verify_boolean_fields_prefilled
    if @options[:has_slide]
      has_slide_yes = find('input[type="radio"][name="inspection[has_slide]"][value="true"]')
      expect(has_slide_yes).to be_checked
    end

    if @options[:is_totally_enclosed]
      is_enclosed_yes = find('input[type="radio"][name="inspection[is_totally_enclosed]"][value="true"]')
      expect(is_enclosed_yes).to be_checked
    end
  end

  def save_main_form
    click_submit_button
  end

  def verify_assessments_prefill_and_complete
    visit edit_inspection_path(@second_inspection)
    @second_inspection.reload

    applicable_tabs = @second_inspection.applicable_tabs.reject { |tab| tab == "inspection" }

    applicable_tabs.each do |tab_name|
      visit edit_inspection_path(@second_inspection, tab: tab_name)

      if tab_name == "results"
        # The passed field is not prefilled, so we need to fill it manually
        # This is correct behavior - each inspection's pass/fail must be determined independently
        field_data = SeedData.send("#{tab_name}_fields", passed: true)
        field_data.each do |field_name, value|
          fill_assessment_field(tab_name, field_name, value)
        end
      end

      submit_form tab_name.to_sym
      expect_updated_message

      @second_inspection.reload
      if tab_name == "results"
        # Results tab doesn't have an assessment model
        expect(@second_inspection.passed).to be true
      else
        assessment = @second_inspection.send("#{tab_name}_assessment")
        expect(assessment.complete?).to be true
      end
    end
  end

  def mark_second_inspection_complete
    visit edit_inspection_path(@second_inspection)

    expect(@second_inspection.has_slide).to eq(@options[:has_slide])
    expect(@second_inspection.is_totally_enclosed).to eq(@options[:is_totally_enclosed])
    expect(@second_inspection.inspection_location).to eq(@inspection.inspection_location)

    click_mark_complete_button
    expect_marked_complete_message
  end

  def verify_date_handling
    @second_inspection.reload

    expect(@inspection.inspection_date.to_date).to eq(7.days.ago.to_date)
    expect(@inspection.complete_date.to_date).to eq(7.days.ago.to_date)

    expect(@second_inspection.complete_date.to_date).to eq(Date.current)
    expect(@second_inspection.inspection_date).to eq(Date.current)
  end

  def fail_to_delete_unit
    visit root_path
    click_link "Units"
    click_link "Test Bouncy Castle"
    click_link t("ui.edit")
    expect_units_message("not_deletable")
  end

  def verify_change_unit_functionality
    other_unit = create(:unit, user: @user, name: "Alternative Unit")

    visit edit_inspection_path(@inspection)
    click_link t("inspections.buttons.change_unit")

    expect(page).to have_current_path(select_unit_inspection_path(@inspection))
    expect(page).to have_content(other_unit.name)

    other_user_unit = create(:unit, user: create(:user), name: "Other User's Unit")
    visit current_path
    expect(page).not_to have_content(other_user_unit.name)
  end

  def delete_second_inspection
    visit edit_inspection_path(@second_inspection)

    expect(page).to have_current_path(inspection_path(@second_inspection))
    expect_cannot_edit_complete_message

    visit inspection_path(@second_inspection)
    click_switch_to_in_progress_button
    expect_marked_in_progress_message

    click_delete_button
    expect_deleted_message
  end
end

RSpec.feature "Complete Inspection Workflow", type: :feature do
  scenario "complete workflow with prefilling - no slide or enclosure" do
    InspectionWorkflow.new(
      has_slide: false,
      is_totally_enclosed: false
    ).execute
  end

  scenario "inspection log access control" do
    user = create(:user)
    other_user = create(:user)
    unit = create(:unit, user: user)
    inspection = create(:inspection, user: user, unit: unit)

    # Owner can view log
    sign_in(user)
    visit log_inspection_path(inspection)
    expect(page).to have_content(I18n.t("inspections.titles.log", inspection: inspection.id))

    # Use direct navigation instead of logout/login
    # Non-owner cannot view log
    page.driver.browser.clear_cookies
    sign_in(other_user)
    visit log_inspection_path(inspection)
    expect(page.status_code).to eq(404)
  end

  scenario "complete workflow with prefilling - slide, no enclosure" do
    InspectionWorkflow.new(
      has_slide: true,
      is_totally_enclosed: false
    ).execute
  end

  scenario "complete workflow with prefilling - no slide, enclosure" do
    InspectionWorkflow.new(
      has_slide: false,
      is_totally_enclosed: true
    ).execute
  end

  scenario "complete workflow with prefilling - slide and enclosure" do
    InspectionWorkflow.new(
      has_slide: true,
      is_totally_enclosed: true
    ).execute
  end

  scenario "prevents duplicate unique report numbers for same user" do
    user = create(:user)
    sign_in(user)

    # Create first inspection with a unique report number
    unit1 = create(:unit, user: user)
    inspection1 = create(:inspection, unit: unit1, user: user)

    visit edit_inspection_path(inspection1)
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: "TEST-001"
    click_button I18n.t("forms.inspection.submit")
    expect(page).to have_content(I18n.t("inspections.messages.updated"))

    # Create second inspection and try to use same report number
    unit2 = create(:unit, user: user)
    inspection2 = create(:inspection, unit: unit2, user: user)

    visit edit_inspection_path(inspection2)
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: "TEST-001"
    click_button I18n.t("forms.inspection.submit")

    # Should show validation error in form
    expect(page).to have_content("has already been taken")
    expect(page).to have_css(".form-errors")

    # Fix by using different report number
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: "TEST-002"
    click_button I18n.t("forms.inspection.submit")
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
  end

  scenario "allows multiple inspections with blank unique report numbers" do
    user = create(:user)
    sign_in(user)

    # Create first inspection with blank unique report number
    unit1 = create(:unit, user: user)
    inspection1 = create(:inspection, unit: unit1, user: user)

    visit edit_inspection_path(inspection1)
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: ""
    click_button I18n.t("forms.inspection.submit")
    expect(page).to have_content(I18n.t("inspections.messages.updated"))

    # Create second inspection also with blank unique report number
    unit2 = create(:unit, user: user)
    inspection2 = create(:inspection, unit: unit2, user: user)

    visit edit_inspection_path(inspection2)
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: ""
    click_button I18n.t("forms.inspection.submit")

    # Should save successfully - blank values are allowed
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
    expect(page).not_to have_css(".form-errors")
  end

  scenario "different users can use the same unique report number" do
    user1 = create(:user)
    user2 = create(:user)

    # User 1 creates inspection with report number
    sign_in(user1)
    unit1 = create(:unit, user: user1)
    inspection1 = create(:inspection, unit: unit1, user: user1)

    visit edit_inspection_path(inspection1)
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: "TEST-001"
    click_button I18n.t("forms.inspection.submit")
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
    logout

    # User 2 can use the same report number
    sign_in(user2)
    unit2 = create(:unit, user: user2)
    inspection2 = create(:inspection, unit: unit2, user: user2)

    visit edit_inspection_path(inspection2)
    fill_in I18n.t("forms.inspection.fields.unique_report_number"), with: "TEST-001"
    click_button I18n.t("forms.inspection.submit")

    # Should save successfully - different users can have same report number
    expect(page).to have_content(I18n.t("inspections.messages.updated"))
    expect(page).not_to have_css(".form-errors")
  end
end
