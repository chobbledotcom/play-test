require "rails_helper"

RSpec.feature "Inspection incomplete fields display", type: :feature do
  include InspectionTestHelpers

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user:) }
  let(:inspection) {
    create(:inspection,
      unit:,
      user:,
      inspection_location: nil,
      passed: true,
      width: 5.0,
      length: 10.0,
      height: 3.0)
  }

  before { sign_in(user) }

  def expect_incomplete_fields_summary(count)
    summary_text = I18n.t("assessments.incomplete_fields.show_fields", count:)
    expect(page).to have_css("summary.incomplete-fields-summary", text: summary_text)
  end

  def expand_incomplete_fields = find("summary.incomplete-fields-summary").click

  def expect_incomplete_field(form_name, field_name)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    within(".incomplete-fields-content") { expect(page).to have_content(field_label) }
  end

  def expect_incomplete_section(form_name)
    section_header = I18n.t("forms.#{form_name}.header")
    within(".incomplete-fields-content") { expect(page).to have_link(section_header) }
  end

  def expect_no_incomplete_section(form_name)
    section_header = I18n.t("forms.#{form_name}.header")
    within(".incomplete-fields-content") { expect(page).not_to have_content(section_header) }
  end

  scenario "displays incomplete fields on inspection edit page" do
    visit edit_inspection_path(inspection)

    within("#mark-as-complete") do
      summary = find("summary.incomplete-fields-summary")
      expect(summary.text).to match(/Show \d+ incomplete field/)

      expand_incomplete_fields

      expect(page).to have_content(I18n.t("assessments.incomplete_fields.description"))
      expect_incomplete_section("inspection")
      expect_incomplete_field("inspection", "inspection_location")
      # Button should NOT be visible when there are incomplete fields
      expect(page).not_to have_button(I18n.t("inspections.buttons.mark_complete"))
    end
  end

  scenario "shows incomplete fields from assessments with section headers" do
    complete_unit = create(:unit, user:)
    controlled_inspection = create(:inspection,
      unit: complete_unit,
      user:,
      inspection_location: nil,
      passed: true,
      height: 3.0,
      length: 10.0,
      width: 8.0)

    controlled_inspection.user_height_assessment.update!(tallest_user_height: nil)

    visit edit_inspection_path(controlled_inspection)
    expand_incomplete_fields

    expect_incomplete_section("inspection")
    expect_incomplete_section("user_height")
    expect_incomplete_field("inspection", "inspection_location")
    expect_incomplete_field("user_height", "tallest_user_height")
  end

  scenario "does not show incomplete fields when inspection is truly complete" do
    # The :completed factory creates a fully complete inspection with ALL required fields filled
    completed_inspection = create(:inspection, :completed, unit:, user:)

    # Must un-complete to be able to edit
    completed_inspection.un_complete!(user)

    visit edit_inspection_path(completed_inspection)

    # A truly completed inspection should have no incomplete fields
    expect(page).not_to have_css("details#incomplete_fields")
    expect(page).to have_button(I18n.t("inspections.buttons.mark_complete"))
  end

  scenario "excludes optional assessment incomplete fields" do
    inspection.update!(has_slide: false)
    inspection.slide_assessment.update!(runout: nil)

    visit edit_inspection_path(inspection)
    expand_incomplete_fields

    expect_no_incomplete_section("slide")
  end

  scenario "links to specific tabs and fields" do
    visit edit_inspection_path(inspection)
    expand_incomplete_fields

    inspection_link = find_link(I18n.t("forms.inspection.header"))
    expect(inspection_link[:href]).to include("tab=inspection", "#tabs")

    field_link = find_link(I18n.t("forms.inspection.fields.inspection_location"))
    expect(field_link[:href]).to include("tab=inspection", "#inspection_location")
  end

  scenario "counts total incomplete fields across all pages" do
    visit edit_inspection_path(inspection)

    summary = find("summary.incomplete-fields-summary")
    count_match = summary.text.match(/(\d+)/)
    summary_count = count_match[1].to_i

    # Verify correct i18n pluralization
    expected_text = I18n.t("assessments.incomplete_fields.show_fields", count: summary_count)
    expect(summary).to have_text(expected_text)

    expand_incomplete_fields

    within(".incomplete-fields-list") do
      # Field links have anchors to specific fields (not #tabs)
      field_links = all("a[href*='#']").reject { |link| link[:href].end_with?("#tabs") }
      total_fields = field_links.count

      expect(total_fields).to eq(summary_count)

      # Section headers have #tabs anchors
      section_headers = all("a[href$='#tabs']")
      expect(section_headers.count).to be > 1

      # Verify each section has at least one field
      section_headers.each do |header|
        section_name = header.text
        # Find fields for this section by looking for links with the same tab parameter
        tab_match = header[:href].match(/tab=(\w+)/)
        if tab_match
          tab_name = tab_match[1]
          section_fields = field_links.select { |link| link[:href].include?("tab=#{tab_name}") }
          expect(section_fields.count).to be > 0, "Section '#{section_name}' should have incomplete fields"
        end
      end
    end
  end

  scenario "displays correct i18n text for field count" do
    visit edit_inspection_path(inspection)

    summary = find("summary.incomplete-fields-summary")
    count_match = summary.text.match(/(\d+)/)
    field_count = count_match[1].to_i

    expected_text = I18n.t("assessments.incomplete_fields.show_fields", count: field_count)
    expect(summary).to have_text(expected_text)

    # Verify pluralization works
    singular_text = I18n.t("assessments.incomplete_fields.show_fields", count: 1)
    plural_text = I18n.t("assessments.incomplete_fields.show_fields", count: 2)

    expect(singular_text).not_to eq(plural_text)
    expect(singular_text).to include("field")
    expect(plural_text).to include("fields")
  end

  scenario "completed factory creates inspection with no incomplete fields" do
    # This verifies that create(:inspection, :completed) fills ALL required fields
    completed = create(:inspection, :completed, unit:, user:)

    # Must un-complete to be able to edit
    completed.un_complete!(user)

    visit edit_inspection_path(completed)

    # Should not have any incomplete fields section
    expect(page).not_to have_css("details#incomplete_fields")
  end
end
