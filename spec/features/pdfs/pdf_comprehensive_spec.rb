require "rails_helper"
require "pdf/inspector"

RSpec.feature "PDF Comprehensive Testing", type: :feature do
  let(:user) { create(:user, name: "Test User", email: "test@example.com") }
  let(:unit) { create(:unit, :with_all_fields, user: user) }
  let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  before do
    sign_in user
  end

  # This single scenario replaces multiple files:
  # - pdf_content_spec.rb (content structure testing)
  # - pdf_generation_spec.rb (UI workflow testing)
  # - pdf_edge_cases_spec.rb (performance and edge cases)
  # - pdf_with_comments_spec.rb (comment handling)
  scenario "comprehensive PDF functionality with all edge cases" do
    # === USER WORKFLOW TESTING ===
    # Test UI iframe integration
    visit inspection_path(inspection)
    expect(page).to have_css("iframe", wait: 5)
    expect(page).to have_css("iframe[src*='#{inspection.id}']")

    # === CONTENT STRUCTURE TESTING ===
    visit inspection_path(inspection, format: :pdf)
    pdf_content = extract_pdf_text(page.source)

    # Test all assessment sections present
    inspection.each_applicable_assessment do |assessment_key, _, _|
      assessment_type = assessment_key.to_s.sub(/_assessment$/, "")
      header = I18n.t("forms.#{assessment_type}.header")
      expect(pdf_content).to include(header)
    end

    # Test core inspection details
    expect(pdf_content).to include(unit.name)
    expect(pdf_content).to include(unit.serial)
    date_format = inspection.inspection_date.strftime("%-d %B, %Y")
    expect(pdf_content).to include(date_format)

    # Test i18n usage
    expect_pdf_to_include_i18n_keys(pdf_content,
      "pdf.inspection.equipment_details",
      "pdf.dimensions.width",
      "pdf.dimensions.length",
      "pdf.dimensions.height")

    # === EDGE CASE TESTING ===
    # Test with long comments (performance)
    long_comment = "Long assessment comment " * 100
    inspection.user_height_assessment.update(
      containing_wall_height_comment: long_comment
    )

    start_time = Time.current
    visit inspection_path(inspection, format: :pdf)
    generation_time = Time.current - start_time
    expect(generation_time).to be < 8.seconds

    # Test Unicode handling
    unit.update(name: "Ünicøde Unit 😎", manufacturer: "Émoji Company 🏭")
    visit inspection_path(inspection, format: :pdf)
    unicode_pdf_content = extract_pdf_text(page.source)
    expect(unicode_pdf_content).to be_present
    expect(unicode_pdf_content.encoding.name).to eq("UTF-8")

    # === UNIT PDF TESTING ===
    # Test unit history reports
    3.times do |i|
      create(:inspection, :completed,
        user: user, unit: unit,
        inspection_date: i.months.ago,
        passed: i.even?)
    end

    visit unit_path(unit, format: :pdf)
    unit_pdf_content = extract_pdf_text(page.source)
    expect_pdf_to_include_i18n_keys(unit_pdf_content,
      "pdf.unit.fields.unit_id",
      "pdf.unit.details",
      "pdf.unit.inspection_history")

    # === DIFFERENT INSPECTION STATES ===
    # Test failed inspection
    failed_inspection = create(:inspection, :completed,
      user: user, unit: unit, passed: false)
    visit inspection_path(failed_inspection, format: :pdf)
    failed_pdf = extract_pdf_text(page.source)
    expect(failed_pdf).to include(I18n.t("pdf.inspection.failed"))

    # Test draft inspection
    draft_inspection = create(:inspection, user: user, unit: unit)
    visit inspection_path(draft_inspection, format: :pdf)
    draft_pdf = extract_pdf_text(page.source)
    expect(draft_pdf).to be_present # Should generate even for drafts

    # === AUTHENTICATION TESTING ===
    # Test that PDFs work when authenticated (just verify it loads)
    visit inspection_path(inspection, format: :pdf)
    expect(page.driver.response.status).to eq(200)
  end

  private

  def extract_pdf_text(pdf_data)
    reader = PDF::Reader.new(StringIO.new(pdf_data))
    reader.pages.map(&:text).join(" ")
  end
end
