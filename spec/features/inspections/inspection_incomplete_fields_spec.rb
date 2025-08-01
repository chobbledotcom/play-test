# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Inspection incomplete fields display", type: :feature do
  include InspectionTestHelpers

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user:) }
  let(:inspection) { create_incomplete_inspection_with_multiple_sections }

  before { sign_in(user) }

  def create_incomplete_inspection_with_multiple_sections
    create_incomplete_inspection(
      inspection_fields: %i[inspection_date width length],
      assessment_fields: {
        structure_assessment: %i[seam_integrity_pass air_loss_pass stitch_length_pass]
      }
    )
  end

  def create_incomplete_inspection(inspection_fields: [], assessment_fields: {}, **attrs)
    # Start with complete inspection to avoid validation errors
    inspection = create(:inspection, :completed, {unit:, user:}.merge(attrs))

    # Make it incomplete (remove complete_date)
    inspection.update_column(:complete_date, nil)

    # Remove specified inspection fields
    if inspection_fields.any?
      field_values = inspection_fields.index_with { nil }
      inspection.update_columns(field_values)
    end

    # Remove specified assessment fields
    assessment_fields.each do |assessment_name, fields|
      assessment = inspection.send(assessment_name)
      field_values = fields.index_with { nil }
      assessment.update_columns(field_values)
    end

    inspection
  end

  def expect_incomplete_fields_summary(count)
    show_fields_key = "assessments.incomplete_fields.show_fields"
    summary_text = I18n.t(show_fields_key, count:)
    summary_selector = "summary.incomplete-fields-summary"
    expect(page).to have_css(summary_selector, text: summary_text)
  end

  def expand_incomplete_fields = find("summary.incomplete-fields-summary").click

  def expect_incomplete_field(form_name, field_name)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    within(".incomplete-fields-content") do
      expect(page).to have_content(field_label)
    end
  end

  def expect_incomplete_section(form_name, count: nil)
    section_header = I18n.t("forms.#{form_name}.header")
    expected_text = count ? "#{section_header} (#{count})" : section_header
    within(".incomplete-fields-content") do
      expect(page).to have_link(expected_text)
    end
  end

  def expect_no_incomplete_section(form_name)
    section_header = I18n.t("forms.#{form_name}.header")
    within(".incomplete-fields-content") do
      expect(page).not_to have_content(section_header)
    end
  end

  scenario "displays incomplete fields on inspection edit page" do
    visit edit_inspection_path(inspection)

    within("#mark-as-complete") do
      summary = find("summary.incomplete-fields-summary")
      expect(summary.text).to match(/Show \d+ incomplete field/)

      expand_incomplete_fields

      incomplete_desc_key = "assessments.incomplete_fields.description"
      expect(page).to have_content(I18n.t(incomplete_desc_key))
      expect_incomplete_section("inspection")
      expect_incomplete_field("inspection", "inspection_date")
      # Button should NOT be visible when there are incomplete fields
      mark_complete_button = I18n.t("inspections.buttons.mark_complete")
      expect(page).not_to have_button(mark_complete_button)
    end
  end

  scenario "shows incomplete fields from assessments with section headers" do
    complete_unit = create(:unit, user:)
    controlled_inspection = create_incomplete_inspection(
      unit: complete_unit,
      passed: true,
      height: 3.0,
      length: 10.0,
      width: 8.0,
      inspection_fields: [:inspection_date],
      assessment_fields: {
        user_height_assessment: [:tallest_user_height]
      }
    )

    visit edit_inspection_path(controlled_inspection)
    expand_incomplete_fields

    expect_incomplete_section("inspection")
    expect_incomplete_section("user_height")
    expect_incomplete_field("inspection", "inspection_date")
    expect_incomplete_field("user_height", "tallest_user_height")
  end

  scenario "does not show incomplete fields when truly complete" do
    # :completed factory creates fully complete inspection with ALL fields
    completed_inspection = create(:inspection, :completed, unit:, user:)

    # Must un-complete to be able to edit
    completed_inspection.un_complete!(user)

    visit edit_inspection_path(completed_inspection)

    # Truly completed inspection should have no incomplete fields
    expect(page).not_to have_css("details.incomplete-fields-details")
    mark_complete_button = I18n.t("inspections.buttons.mark_complete")
    expect(page).to have_button(mark_complete_button)
  end

  scenario "excludes optional assessment incomplete fields" do
    inspection.update_column(:has_slide, false)
    inspection.slide_assessment.update!(runout: nil)

    visit edit_inspection_path(inspection)
    expand_incomplete_fields

    expect_no_incomplete_section("slide")
  end

  scenario "links to specific tabs and fields" do
    visit edit_inspection_path(inspection)
    expand_incomplete_fields

    # Find link by partial match since it now includes count
    inspection_header = I18n.t("forms.inspection.header")
    inspection_link = find_link(text: /#{Regexp.escape(inspection_header)}/)
    expect(inspection_link[:href]).to include("tab=inspection", "#tabs")

    field_link = find_link(I18n.t("forms.inspection.fields.inspection_date"))
    expected_params = ["tab=inspection", "#inspection_date"]
    expect(field_link[:href]).to include(*expected_params)
  end

  scenario "clicking incomplete field links navigates to correct tab" do
    visit edit_inspection_path(inspection)
    expand_incomplete_fields

    # Click field link from different tab in incomplete fields section
    within(".incomplete-fields-content") do
      structure_header = I18n.t("forms.structure.header")
      structure_link = find_link(text: /#{Regexp.escape(structure_header)}/)
      structure_link.click
    end

    # Verify we're on the structure tab
    structure_path = edit_inspection_path(inspection, tab: "structure")
    expect(page).to have_current_path(structure_path)

    # Go back and click on a specific field link
    visit edit_inspection_path(inspection)
    expand_incomplete_fields

    within(".incomplete-fields-content") do
      field_link = find_link(I18n.t("forms.inspection.fields.inspection_date"))
      field_link.click
    end

    # Verify we're on the inspection tab with the field anchor
    inspection_path = edit_inspection_path(inspection, tab: "inspection")
    expect(page).to have_current_path(inspection_path)
  end

  scenario "displays incomplete fields in correct tab order" do
    # The inspection fixture already has incomplete fields in multiple tabs
    # Just verify they appear in the correct order

    visit edit_inspection_path(inspection)
    expand_incomplete_fields

    # Get all section headers in order
    section_headers = all(".incomplete-fields-content strong a").map(&:text)

    # Verify the first item is always "General" (inspection tab)
    expect(section_headers.first).to include(I18n.t("forms.inspection.header"))

    # Verify Results appears last if present
    results_header = I18n.t("forms.results.header")
    expect(section_headers.last).to include(results_header) if section_headers.any? { |h| h.include?(results_header) }

    # Verify the order matches the tab order from applicable_tabs
    # Exact tabs shown depend on which have incomplete fields
    tab_order = inspection.applicable_tabs
    tab_headers = tab_order.map { |tab| I18n.t("forms.#{tab}.header") }

    # Filter to tabs that actually appear in incomplete fields
    expected_headers = tab_headers.select do |header|
      section_headers.any? { |sh| sh.include?(header) }
    end

    # Extract just the header names without counts for comparison
    section_names = section_headers.map { |h| h.sub(/ \(\d+\)$/, "") }
    expect(section_names).to eq(expected_headers)
  end

  scenario "displays incomplete field counts for each section" do
    controlled_inspection = create_incomplete_inspection(
      inspection_fields: %i[inspection_date width length],
      assessment_fields: {
        structure_assessment: %i[seam_integrity_pass stitch_length_pass air_loss_pass]
      }
    )

    visit edit_inspection_path(controlled_inspection)
    expand_incomplete_fields

    # Check that General shows (3) for inspection_date, width, and length
    expect_incomplete_section("inspection", count: 3)

    # Check that Structure shows (3) for the three nil fields
    expect_incomplete_section("structure", count: 3)
  end

  scenario "counts total incomplete fields across all pages" do
    visit edit_inspection_path(inspection)

    summary = find("summary.incomplete-fields-summary")
    count_match = summary.text.match(/(\d+)/)
    summary_count = count_match[1].to_i

    # Verify correct i18n pluralization
    show_fields_key = "assessments.incomplete_fields.show_fields"
    expected_text = I18n.t(show_fields_key, count: summary_count)
    expect(summary).to have_text(expected_text)

    expand_incomplete_fields

    within(".incomplete-fields-list") do
      # Field links have anchors to specific fields (not #tabs)
      all_links = all("a[href*='#']")
      field_links = all_links.reject { |link| link[:href].end_with?("#tabs") }
      total_fields = field_links.count

      expect(total_fields).to eq(summary_count)

      # Section headers have #tabs anchors
      section_headers = all("a[href$='#tabs']")
      expect(section_headers.count).to be > 1

      # Verify each section has at least one field
      section_headers.each do |header|
        section_name = header.text
        # Find fields for section by looking for links with same tab param
        tab_match = header[:href].match(/tab=(\w+)/)
        next unless tab_match

        tab_name = tab_match[1]
        tab_selector = "tab=#{tab_name}"
        section_fields = field_links.select do |link|
          link[:href].include?(tab_selector)
        end
        error_msg = "Section '#{section_name}' should have incomplete fields"
        expect(section_fields.count).to be > 0, error_msg
      end
    end
  end

  scenario "displays correct i18n text for field count" do
    visit edit_inspection_path(inspection)

    summary = find("summary.incomplete-fields-summary")
    count_match = summary.text.match(/(\d+)/)
    field_count = count_match[1].to_i

    show_fields_key = "assessments.incomplete_fields.show_fields"
    expected_text = I18n.t(show_fields_key, count: field_count)
    expect(summary).to have_text(expected_text)

    # Verify pluralization works
    show_fields_key = "assessments.incomplete_fields.show_fields"
    singular_text = I18n.t(show_fields_key, count: 1)
    plural_text = I18n.t("assessments.incomplete_fields.show_fields", count: 2)

    expect(singular_text).not_to eq(plural_text)
    expect(singular_text).to include("field")
    expect(plural_text).to include("fields")
  end

  scenario "completed factory creates inspection with no incomplete fields" do
    # Verifies that create(:inspection, :completed) fills ALL required fields
    completed = create(:inspection, :completed, unit:, user:)

    # Must un-complete to be able to edit
    completed.un_complete!(user)

    visit edit_inspection_path(completed)

    # Should not have any incomplete fields section
    expect(page).not_to have_css("details.incomplete-fields-details")
  end
end
