require "rails_helper"
require "pdf/inspector"

RSpec.feature "PDF Content Structure", type: :feature, pdf: true do
  ASSESSMENT_FORMS = %w[tallest_user_height structure anchorage materials fan slide enclosed].freeze

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
        lock_stitch_pass: true,
        air_loss_pass: true
      )

      pdf_text = get_pdf_text(inspection_report_path(inspection))

      # Check all core i18n keys are present
      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.inspection.title",
        "pdf.inspection.equipment_details",
        "shared.comment")

      # Check dynamic content
      expect(pdf_text).to include(user.rpii_inspector_number) if user.rpii_inspector_number.present?
      expect(pdf_text).to include("Test Bouncy Castle")
      expect(pdf_text).to include("BCL-2024-001")
      expect(pdf_text).to include(I18n.t("pdf.dimensions.width"))
      expect(pdf_text).to include(I18n.t("pdf.dimensions.length"))
      expect(pdf_text).to include(I18n.t("pdf.dimensions.height"))

      # Check assessment sections exist
      expect(pdf_text).to include(I18n.t("forms.tallest_user_height.header"))
      expect(pdf_text).to include(I18n.t("forms.structure.header"))

      # Check result
      expect_pdf_to_include_i18n(pdf_text, "pdf.inspection.passed")
    end

    scenario "handles failed inspection correctly" do
      failed_inspection = create(:inspection, :pdf_complete_test_data,
        user: user,
        unit: unit,
        passed: false,
        comments: "Multiple safety issues found")

      # Update the auto-created assessment
      failed_inspection.structure_assessment.update!(
        seam_integrity_pass: false,
        seam_integrity_comment: "Torn seam on left side"
      )

      pdf_text = get_pdf_text(inspection_report_path(failed_inspection))

      # Check for failed status
      expect_pdf_to_include_i18n(pdf_text, "pdf.inspection.failed")
      expect(pdf_text).to include("Multiple safety issues found")
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

    scenario "shows 'No data available' for missing assessments" do
      inspection = create(:inspection,
        user: user,
        unit: unit,
        complete_date: Time.current)

      # Assessments are auto-created but have no data

      pdf_text = get_pdf_text(inspection_report_path(inspection))

      # Should show no data messages for assessments
      expect_no_assessment_messages(pdf_text, inspection)
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
