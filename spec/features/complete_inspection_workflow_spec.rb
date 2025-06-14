require "rails_helper"
require_relative "../../db/seeds/assessment_data"

# Workflow class for creating and completing inspections
class InspectionWorkflow
  include Capybara::DSL
  include RSpec::Matchers
  include Rails.application.routes.url_helpers

  BOOLEAN_FIELDS = %w[slide_permanent_roof].freeze

  attr_reader :user
  attr_reader :unit
  attr_reader :inspection
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
    self
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
    fill_all_assessments
    mark_inspection_complete
    verify_inspection_complete
  end

  def register_new_user
    visit root_path
    click_link t("users.titles.register")

    user_data = AssessmentData.user_fields
    user_data.each do |field_name, value|
      next if value.nil?
      field_label = t("forms.user_new.fields.#{field_name}")
      fill_in field_label, with: value
    end

    click_button t("forms.user_new.submit")
    User.find_by!(email: user_data[:email])
  end

  def verify_inactive_user_warning
    expect(page).to have_content(t("users.messages.user_inactive"))
  end

  def activate_user = @user.update!(active_until: 5.minutes.from_now)

  def verify_no_warning_after_activation
    visit current_path
    expect(page).not_to have_content(
      t("users.messages.user_inactive")
    )
  end

  def create_test_unit
    visit units_path
    click_button t("units.buttons.add_unit")

    unit_data = AssessmentData.unit_fields.merge(
      name: "Test Bouncy Castle"
    )

    unit_data.each do |field_name, value|
      field_label = t("forms.units.fields.#{field_name}")
      fill_in field_label, with: value
    end

    click_button t("forms.units.submit")
    expect(page).to have_content(t("units.messages.created"))

    Unit.find_by!(
      name: unit_data[:name],
      serial: unit_data[:serial]
    )
  end

  def create_inspection_for_unit
    click_button t("units.buttons.add_inspection")
    expect(page).to have_content(t("inspections.titles.edit"))

    @unit.inspections.order(created_at: :desc).first.tap do |inspection|
      expect(inspection).to be_present
    end
  end

  def fill_general_inspection_details
    field_data = AssessmentData.inspection_fields.merge(@options)

    field_data.each do |field_name, value|
      fill_inspection_field(field_name, value)
    end

    click_button t("forms.inspections.submit")

    @inspection.reload
    expect(@inspection.has_slide).to eq(
      @options[:has_slide]
    )
    expect(@inspection.is_totally_enclosed).to eq(
      @options[:is_totally_enclosed]
    )
  end

  def fill_inspection_field(field_name, value)
    field_label = t("forms.inspections.fields.#{field_name}")

    case field_name
    when :is_totally_enclosed, :has_slide
      value ? check(field_label) : uncheck(field_label)
    when ->(n) { value.is_a?(Date) }
      fill_in field_label, with: value
    when ->(n) { value.is_a?(String) || value.is_a?(Numeric) }
      fill_in field_label, with: value
    end
  end

  def fill_all_assessments
    applicable_tabs.each_with_index do |tab_name, index|
      fill_assessment_tab(tab_name)

      if index < applicable_tabs.length - 1
        verify_inspection_not_completable
      end
    end
  end

  def applicable_tabs
    @applicable_tabs ||= begin
      all_tabs = Inspection::ASSESSMENT_TYPES.keys.map { |k|
        k.to_s.sub(/_assessment$/, "")
      }

      all_tabs.select do |tab_name|
        case tab_name
        when "slide"
          @inspection.has_slide
        when "enclosed"
          @inspection.is_totally_enclosed
        else
          true
        end
      end
    end
  end

  def fill_assessment_tab(tab_name)
    visit edit_inspection_path(@inspection, tab: tab_name)
    field_data = AssessmentData.send(
      "#{tab_name}_fields",
      passed: true
    )

    field_data.each do |field_name, value|
      fill_assessment_field(tab_name, field_name, value)
    end

    click_button t("forms.#{tab_name}.submit")
    expect(page).to have_content(
      t("inspections.messages.updated")
    )

    assessment = @inspection.reload.send("#{tab_name}_assessment")
    expect(assessment.complete?).to be true
  end

  def fill_assessment_field(tab_name, field_name, value)
    field_name_str = field_name.to_s
    return if field_name_str.end_with?("_comment")

    field_label = get_field_label(tab_name, field_name, field_name_str)

    case field_name_str
    when /.*_pass$/
      choose "#{field_name}_#{value ? "true" : "false"}"
    when ->(s) { BOOLEAN_FIELDS.include?(s) }
      checkbox_id = "#{field_name}_checkbox"
      value ? check(checkbox_id) : uncheck(checkbox_id)
    when ->(s) { value.is_a?(String) && value.present? }
      fill_in field_label, with: value
    when ->(s) { value.is_a?(Numeric) }
      fill_in field_label, with: value
    end
  end

  def get_field_label(tab_name, field_name, field_name_str)
    i18n_key = "forms.#{tab_name}.fields.#{field_name}"

    begin
      t(i18n_key)
    rescue I18n::MissingTranslationData
      if field_name_str.end_with?("_pass")
        base_field_name = field_name_str.sub(/_pass$/, "")
        base_key = "forms.#{tab_name}.fields.#{base_field_name}"
        t(base_key)
      else
        raise
      end
    end
  end

  def verify_inspection_not_completable
    visit edit_inspection_path(@inspection)
    click_button t("inspections.buttons.mark_complete")
    expect(page).to have_content(
      "Cannot mark as complete:"
    )
  end

  def mark_inspection_complete
    visit edit_inspection_path(@inspection)
    click_button t("inspections.buttons.mark_complete")
    expect(page).to have_content(
      t("inspections.messages.marked_complete")
    )
  end

  def verify_inspection_complete
    @inspection.reload
    expect(@inspection.complete?).to be true
    expect(@inspection.complete_date).to be_present

    visit inspection_path(@inspection, format: :pdf)
    expect(page.status_code).to eq(200)
  end
end

RSpec.feature "Complete Inspection Workflow", type: :feature do
  scenario "from user creation to pdf - no slide or enclosure" do
    InspectionWorkflow.new(
      has_slide: false,
      is_totally_enclosed: false
    ).execute
  end
  scenario "from user creation to pdf - slide, no enclosure" do
    InspectionWorkflow.new(
      has_slide: true,
      is_totally_enclosed: false
    ).execute
  end
  scenario "from user creation to pdf - no slide, enclosure" do
    InspectionWorkflow.new(
      has_slide: false,
      is_totally_enclosed: true
    ).execute
  end
  scenario "from user creation to pdf - slide and enclosure" do
    InspectionWorkflow.new(
      has_slide: true,
      is_totally_enclosed: true
    ).execute
  end
end
