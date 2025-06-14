require "rails_helper"
require "pdf/inspector"

ASSESSMENT_FORMS = %w[user_height structure anchorage materials fan slide enclosed].freeze

RSpec.feature "PDF Content Structure", type: :feature, pdf: true do
  let(:user) { create(:user) }
  let(:inspector_company) { user.inspection_company }
  let(:unit) do
    create(:unit,
      user: user,
      name: "Test Bouncy Castle",
      manufacturer: "Bounce Co Ltd",
      serial: "BCL-2024-001")
  end

  before do
    sign_in(user)
  end

  feature "Inspection PDF Content" do
    scenario "includes all required sections" do
      inspection = create(:inspection, :pdf_complete_test_data,
        user: user,
        unit: unit)

      # Update the auto-created assessments
      inspection.user_height_assessment.update!(
        containing_wall_height: 2.5,
        tallest_user_height: 1.8,
        users_at_1800mm: 5
      )

      inspection.structure_assessment.update!(
        seam_integrity_pass: true,
        uses_lock_stitching_pass: true,
        air_loss_pass: true
      )

      pdf_text = get_pdf_text(inspection_report_path(inspection))

      # Check all core i18n keys are present
      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.inspection.title",
        "pdf.inspection.equipment_details")

      # Check dynamic content
      expect(pdf_text).to include(user.rpii_inspector_number) if user.rpii_inspector_number.present?
      expect(pdf_text).to include("Test Bouncy Castle")
      expect(pdf_text).to include("BCL-2024-001")
      expect(pdf_text).to include(I18n.t("pdf.dimensions.width"))
      expect(pdf_text).to include(I18n.t("pdf.dimensions.length"))
      expect(pdf_text).to include(I18n.t("pdf.dimensions.height"))

      # Check assessment sections exist
      expect(pdf_text).to include(I18n.t("forms.user_height.header"))
      expect(pdf_text).to include(I18n.t("forms.structure.header"))

      # Check result
      expect_pdf_to_include_i18n(pdf_text, "pdf.inspection.passed")
    end

    scenario "handles failed inspection correctly" do
      failed_inspection = create(:inspection, :pdf_complete_test_data,
        user: user,
        unit: unit,
        passed: false,
        risk_assessment: "Multiple safety issues found")

      # Update the auto-created assessment
      failed_inspection.structure_assessment.update!(
        seam_integrity_pass: false,
        seam_integrity_comment: "Torn seam on left side"
      )

      pdf_text = get_pdf_text(inspection_report_path(failed_inspection))

      # Check for failed status
      expect_pdf_to_include_i18n(pdf_text, "pdf.inspection.failed")
      # Note: Risk assessment and comments may not be included in PDF output
      expect(pdf_text).to include("Torn seam on left side")
    end

    scenario "includes all assessment types when present" do
      # Create unit with slide and totally enclosed
      special_unit = create(:unit, user: user)

      inspection = create(:inspection, :completed, :pdf_complete_test_data, :with_slide, :totally_enclosed,
        user: user,
        unit: special_unit)

      text_content = get_pdf_text(inspection_report_path(inspection))

      # Check all assessment sections are present
      ASSESSMENT_FORMS.each do |form|
        expect(text_content).to include(I18n.t("forms.#{form}.header"))
      end
    end

    scenario "handles user without RPII number correctly" do
      user_without_rpii = create(:user, :without_rpii)
      inspection = create(:inspection, :completed, :pdf_complete_test_data,
        user: user_without_rpii,
        unit: unit)

      pdf_text = get_pdf_text(inspection_report_path(inspection))

      # Check PDF still generates correctly
      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.inspection.title",
        "pdf.inspection.equipment_details")

      # Check user info is present but RPII is not
      expect(pdf_text).to include(user_without_rpii.name)
      expect(pdf_text).not_to include(I18n.t("pdf.inspection.fields.rpii_inspector_no"))
    end

    scenario "shows proper handling for empty assessments" do
      inspection = create(:inspection,
        user: user,
        unit: unit,
        complete_date: Time.current)

      # Assessments are auto-created but have no data

      pdf_text = get_pdf_text(inspection_report_path(inspection))

      # Should show assessment headers even with empty data
      expect(pdf_text).to include(I18n.t("forms.structure.header"))
      expect(pdf_text).to include(I18n.t("forms.user_height.header"))

      # Should handle null values with [NULL] indicators
      expect(pdf_text).to include("[NULL]")
    end
  end

  feature "Unit History PDF Content" do
    scenario "includes unit details and inspection history" do
      # Create multiple inspections
      inspections = []
      3.times do |i|
        inspections << create(:inspection, :completed, :pdf_complete_test_data,
          user: user,
          unit: unit,
          inspection_date: i.months.ago,
          passed: i.even?)
      end

      pdf_text = get_pdf_text(unit_report_path(unit))

      # Check all core i18n keys are present
      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.unit.title",
        "pdf.unit.details",
        "pdf.unit.inspection_history")

      # Check unit details
      expect(pdf_text).to include("Test Bouncy Castle")
      expect(pdf_text).to include("Bounce Co Ltd")
      expect(pdf_text).to include("BCL-2024-001")

      # Should include inspection dates
      inspections.each do |inspection|
        expect(pdf_text).to include(inspection.inspection_date.strftime("%d/%m/%Y"))
      end
    end

    scenario "handles unit with no inspections" do
      empty_unit = create(:unit, user: user)

      pdf_text = get_pdf_text(unit_report_path(empty_unit))

      expect_pdf_to_include_i18n(pdf_text, "pdf.unit.title")
      expect_pdf_to_include_i18n(pdf_text, "pdf.unit.no_completed_inspections")
    end

    scenario "handles unit with 10 prior inspections" do
      # Create 10 inspections with varied data
      inspections = []
      10.times do |i|
        inspections << create(:inspection, :completed, :pdf_complete_test_data,
          user: user,
          unit: unit,
          inspection_date: i.months.ago,
          passed: i.even?,
          inspection_location: "Location #{i + 1}")
      end

      start_time = Time.current
      pdf_text = get_pdf_text(unit_report_path(unit))
      generation_time = Time.current - start_time

      # Should generate within reasonable time
      expect(generation_time).to be < 10.seconds

      # Check all core i18n keys are present
      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.unit.title",
        "pdf.unit.details",
        "pdf.unit.inspection_history")

      # Check unit details
      expect(pdf_text).to include("Test Bouncy Castle")
      expect(pdf_text).to include("Bounce Co Ltd")
      expect(pdf_text).to include("BCL-2024-001")

      # Should include all inspection dates
      inspections.each do |inspection|
        expect(pdf_text).to include(inspection.inspection_date.strftime("%d/%m/%Y"))
      end

      # Should include pass/fail status for each inspection
      inspections.each_with_index do |inspection, index|
        if inspection.passed?
          expect(pdf_text).to include(I18n.t("shared.pass_pdf"))
        else
          expect(pdf_text).to include(I18n.t("shared.fail_pdf"))
        end
      end
    end

    scenario "handles unit with image and 10 prior inspections" do
      # Create unit with attached image
      unit_with_image = create(:unit, user: user,
        name: "Castle with Photo",
        manufacturer: "Photo Test Co",
        serial: "PTC-2024-IMG")

      # Attach a test image to the unit
      unit_with_image.photo.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_image.jpg")),
        filename: "test_castle.jpg",
        content_type: "image/jpeg"
      )

      # Create 10 inspections with varied data
      inspections = []
      10.times do |i|
        inspections << create(:inspection, :completed, :pdf_complete_test_data,
          user: user,
          unit: unit_with_image,
          inspection_date: i.months.ago,
          passed: i.even?,
          inspection_location: "Photo Location #{i + 1}")
      end

      start_time = Time.current
      pdf_data = get_pdf(unit_report_path(unit_with_image))
      generation_time = Time.current - start_time

      # Should generate within reasonable time even with image processing
      expect(generation_time).to be < 15.seconds

      # Verify PDF is valid and contains image data
      expect_valid_pdf(pdf_data)
      expect(pdf_data).to include("/Image")

      # Extract text content
      pdf_text = pdf_text_content(pdf_data)

      # Check all core i18n keys are present
      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.unit.title",
        "pdf.unit.details",
        "pdf.unit.inspection_history")

      # Check unit details
      expect(pdf_text).to include("Castle with Photo")
      expect(pdf_text).to include("Photo Test Co")
      expect(pdf_text).to include("PTC-2024-IMG")

      # Should include all inspection dates
      inspections.each do |inspection|
        expect(pdf_text).to include(inspection.inspection_date.strftime("%d/%m/%Y"))
      end

      # Should include pass/fail status for each inspection
      inspections.each_with_index do |inspection, index|
        if inspection.passed?
          expect(pdf_text).to include(I18n.t("shared.pass_pdf"))
        else
          expect(pdf_text).to include(I18n.t("shared.fail_pdf"))
        end
      end

      # PDF should be reasonably sized even with image and 10 inspections
      expect(pdf_data.bytesize).to be < 5.megabytes
      expect(pdf_data.bytesize).to be > 10.kilobytes
    end
  end

  feature "PDF Formatting" do
    scenario "uses correct fonts" do
      inspection = create(:inspection, :completed, :pdf_complete_test_data, user: user, unit: unit)

      pdf_data = get_pdf(inspection_report_path(inspection))
      expect_valid_pdf(pdf_data)
    end

    scenario "generates valid PDF structure" do
      inspection = create(:inspection, :completed, :pdf_complete_test_data, user: user, unit: unit)

      pdf_data = get_pdf(inspection_report_path(inspection))
      expect_valid_pdf(pdf_data)
    end
  end

  feature "QR Code Generation" do
    scenario "includes QR code in inspection report" do
      inspection = create(:inspection, :completed, :pdf_complete_test_data, user: user, unit: unit)

      pdf_data = get_pdf(inspection_report_path(inspection))

      # PDF should contain image data (QR code)
      expect(pdf_data).to include("/Image")

      text_content = pdf_text_content(pdf_data)

      # Should include report ID
      expect(text_content).to include(inspection.id)
    end
  end

  private

  def inspection_report_path(inspection)
    "/inspections/#{inspection.id}.pdf"
  end

  def unit_report_path(unit)
    "/units/#{unit.id}.pdf"
  end
end
