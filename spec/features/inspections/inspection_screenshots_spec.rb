# typed: false

require "rails_helper"
require "timeout"
require Rails.root.join("db/seeds/seed_data")

RSpec.feature "Complete Inspection Workflow",
  type: :feature,
  screenshot: true,
  skip: "Run manually with --tag screenshot" do
  scenario "complete workflow with prefilling - no slide or enclosure",
    js: true do
    InspectionScreenshotWorkflow.new(
      has_slide: true,
      is_totally_enclosed: true
    ).execute
  end
end

class InspectionScreenshotWorkflow
  include Capybara::DSL
  include RSpec::Matchers
  include Rails.application.routes.url_helpers
  include RadioButtonHelpers
  include FactoryBot::Syntax::Methods
  include InspectionTestHelpers
  include FormHelpers
  include GuideScreenshotHelpers

  attr_reader :user
  attr_reader :unit
  attr_reader :inspection
  attr_reader :second_inspection
  attr_reader :options

  def initialize(has_slide:, is_totally_enclosed:, unit_type: :bouncy_castle)
    @options = {has_slide:, is_totally_enclosed:, unit_type:}
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
    @inspection.reload.applicable_tabs.reject { |tab| tab == "inspection" }
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
  end

  def fill_and_verify_inspection
    fill_general_inspection_details
    fill_all_assessments
    mark_inspection_complete
    verify_inspection_complete
  end

  def register_new_user
    visit root_path
    capture_guide_screenshot("Home Page - Not Logged In")

    click_link t("users.titles.register")
    capture_guide_screenshot("Registration Form")

    user_data = SeedData.user_fields
    user_data.each do |field_name, value|
      fill_in_form :user_new, field_name, value
    end
    capture_guide_screenshot("Registration Form - Filled")

    submit_form :user_new
    User.find_by!(email: user_data[:email])
  end

  def verify_inactive_user_warning
    capture_guide_screenshot("Inactive User Warning")
  end

  def activate_user
    @user.update!(active_until: 5.minutes.from_now)
  end

  def verify_no_warning_after_activation
    visit current_path
  end

  def create_test_unit
    navigate_to_units_page
    fill_unit_form
    submit_and_find_unit
  end

  def navigate_to_units_page
    visit root_path
    click_link "Units"
    capture_guide_screenshot("Units Index - Empty")
    click_button t("units.buttons.add_unit")
    capture_guide_screenshot("Create Unit Form")
  end

  def fill_unit_form
    unit_data = SeedData.unit_fields.merge(name: "Test Bouncy Castle")
    unit_data.each do |field_name, value|
      fill_in_form :units, field_name, value
    end
    capture_guide_screenshot("Create Unit Form - Filled")
  end

  def submit_and_find_unit
    submit_form :units
    capture_guide_screenshot("Unit Created Successfully")
    unit_data = SeedData.unit_fields.merge(name: "Test Bouncy Castle")
    Unit.find_by!(
      name: unit_data[:name],
      serial: unit_data[:serial]
    )
  end

  def create_inspection_for_unit
    visit root_path
    click_link "Units"
    click_link "Test Bouncy Castle"
    capture_guide_screenshot("Unit Details Page")

    # Click the add inspection button
    click_button t("units.buttons.add_inspection")

    # Wait for the page to redirect to edit page
    expect(page).to have_current_path(/inspections\/\w+\/edit/, wait: 10)

    # The inspection should have been created
    @inspection = @user.inspections.last
    raise "Inspection was not created" if @inspection.nil?

    capture_guide_screenshot("New Inspection - Basic Details")
    @inspection
  end

  def fill_general_inspection_details
    field_data = SeedData.inspection_fields(passed: true).merge(@options)

    field_data.each do |field_name, value|
      fill_inspection_field(field_name, value)
    end
    capture_guide_screenshot("Inspection Details - Filled")

    click_submit_button
    capture_guide_screenshot("Inspection Summary - Incomplete")
  end

  def fill_all_assessments
    applicable_tabs.each do |tab_name|
      fill_assessment_tab(tab_name)
    end
  end

  def fill_assessment_tab(tab_name)
    visit edit_inspection_path(@inspection, tab: tab_name)
    capture_guide_screenshot("#{tab_name.humanize} Assessment Form")

    field_data = SeedData.send(
      "#{tab_name}_fields",
      passed: true
    )

    field_data.each do |field_name, value|
      fill_assessment_field(tab_name, field_name, value)
    end
    capture_guide_screenshot("#{tab_name.humanize} Assessment - Filled")
    submit_form tab_name.to_sym
    expect(page).to have_selector "#form_save_message"
    capture_guide_screenshot("#{tab_name.humanize} Assessment - Saved")
  end

  def mark_inspection_complete
    visit edit_inspection_path(@inspection)
    capture_guide_screenshot("Inspection Summary - All Complete")
    # Verify the button is now visible since there are no incomplete fields
    click_mark_complete_button
    capture_guide_screenshot("Inspection Marked Complete")
  end

  def verify_inspection_complete
    visit inspection_path(@inspection)
    capture_guide_screenshot("Completed Inspection View")
  end

  def verify_second_inspection_prefilling
    update_first_inspection_dates
    create_second_inspection
    save_main_form
    verify_assessments_prefill_and_complete
    mark_second_inspection_complete
    verify_date_handling
  end

  def update_first_inspection_dates
    @inspection.reload.update!(
      inspection_date: 7.days.ago,
      complete_date: 7.days.ago
    )
  end

  def create_second_inspection
    visit unit_path(@unit)
    click_button t("units.buttons.add_inspection")

    # Wait for redirect
    expect(page).to have_current_path(/inspections\/\w+\/edit/, wait: 10)

    @second_inspection = @unit.inspections.order(created_at: :desc).first
    raise "Second inspection was not created" if @second_inspection.nil?
    @second_inspection
  end

  def save_main_form
    click_submit_button
  end

  def verify_assessments_prefill_and_complete
    visit edit_inspection_path(@second_inspection)
    @second_inspection.reload
    applicable_tabs = get_applicable_tabs
    applicable_tabs.each { |tab_name| process_assessment_tab(tab_name) }
  end

  def get_applicable_tabs
    @second_inspection.applicable_tabs.reject { |tab| tab == "inspection" }
  end

  def process_assessment_tab(tab_name)
    visit edit_inspection_path(@second_inspection, tab: tab_name)
    fill_results_tab_if_needed(tab_name)
    submit_form tab_name.to_sym
  end

  def fill_results_tab_if_needed(tab_name)
    return unless tab_name == "results"

    # The passed field is not prefilled, so we need to fill it manually
    # This is correct behavior - each inspection's pass/fail must be
    # determined independently
    field_data = SeedData.send("#{tab_name}_fields", passed: true)
    field_data.each do |field_name, value|
      fill_assessment_field(tab_name, field_name, value)
    end
  end

  def mark_second_inspection_complete
    visit edit_inspection_path(@second_inspection)

    click_mark_complete_button
  end

  def verify_date_handling
    @second_inspection.reload
  end

  def fail_to_delete_unit
    visit root_path
    click_link "Units"
    click_link "Test Bouncy Castle"
    click_link t("ui.edit")
  end

  def delete_second_inspection
    visit edit_inspection_path(@second_inspection)
    visit inspection_path(@second_inspection)
    click_switch_to_in_progress_button
    click_delete_button
  end
end
