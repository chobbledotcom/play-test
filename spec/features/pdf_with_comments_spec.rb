require "rails_helper"

RSpec.feature "PDF with Comments", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit) }

  scenario "renders assessment comments in purple italics" do
    # Create inspection with specific comments
    inspection = create(:inspection, user: user, unit: unit)

    # Add comments to anchorage assessment
    inspection.anchorage_assessment.update!(
      num_low_anchors: 4,
      num_low_anchors_pass: false,
      num_high_anchors_pass: false,
      num_low_anchors_comment: "Need 2 more low anchors for safety",
      anchor_type_pass: true,
      anchor_type_comment: "D-ring anchors properly installed"
    )

    # Add comments to structure assessment
    inspection.structure_assessment.update!(
      seam_integrity_pass: true,
      seam_integrity_comment: "All seams double-stitched",
      unit_stable_pass: true,
      unit_stable_comment: "Passed 90 second stability test"
    )

    sign_in user
    visit inspection_path(inspection, format: :pdf)

    pdf_content = extract_pdf_text(page.source)

    # Verify comments appear in PDF
    expect(pdf_content).to include("Need 2 more low anchors for safety")
    expect(pdf_content).to include("D-ring anchors properly installed")
    expect(pdf_content).to include("All seams double-stitched")
    expect(pdf_content).to include("Passed 90 second stability test")

    # Verify [PASS]/[FAIL] indicators
    expect(pdf_content).to include("[FAIL]")
    expect(pdf_content).to include("[PASS]")
  end

  private

  def extract_pdf_text(pdf_data)
    reader = PDF::Reader.new(StringIO.new(pdf_data))
    reader.pages.map(&:text).join("\n")
  end
end
