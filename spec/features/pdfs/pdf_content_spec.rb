require "rails_helper"
require "pdf/inspector"
require Rails.root.join("db/seeds/seed_data")

ASSESSMENT_FORMS = %w[user_height structure anchorage materials fan slide enclosed].freeze

RSpec.feature "PDF Content Structure", type: :feature, pdf: true do
  let(:user) { create(:user) }
  let(:inspector_company) { user.inspection_company }
  let(:unit) do
    create(:unit,
      user: user,
      **SeedData.unit_fields)
  end

  before do
    sign_in(user)
  end

  feature "Inspection PDF Content" do
    scenario "includes all required sections" do
      inspection = create(:inspection, :completed,
        user: user,
        unit: unit)

      inspection.user_height_assessment.update!(
        SeedData.user_height_fields.slice(:containing_wall_height, :tallest_user_height, :users_at_1800mm)
      )

      inspection.structure_assessment.update!(
        SeedData.structure_fields.slice(:seam_integrity_pass, :uses_lock_stitching_pass, :air_loss_pass)
      )

      pdf_text = get_pdf_text(inspection_path(inspection, format: :pdf))

      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.inspection.equipment_details")

      expect(pdf_text).to include(user.rpii_inspector_number) if user.rpii_inspector_number.present?
      expect(pdf_text).to include(unit.name)
      expect(pdf_text).to include(unit.serial)
      expect(pdf_text).to include(I18n.t("pdf.dimensions.width"))
      expect(pdf_text).to include(I18n.t("pdf.dimensions.length"))
      expect(pdf_text).to include(I18n.t("pdf.dimensions.height"))

      expect(pdf_text).to include(I18n.t("forms.user_height.header"))
      expect(pdf_text).to include(I18n.t("forms.structure.header"))

      expect_pdf_to_include_i18n(pdf_text, "pdf.inspection.passed")
    end

    scenario "handles failed inspection correctly" do
      # Create a completed failed inspection
      failed_inspection = create(:inspection,
        user: user,
        unit: unit,
        passed: false,
        complete_date: Time.current,
        width: 5.5,
        length: 6.0,
        height: 4.5,
        risk_assessment: "Multiple safety issues found")

      # Update all assessments to be complete
      failed_inspection.assessment_types.each do |assessment_name, _assessment_class|
        assessment = failed_inspection.send(assessment_name)
        assessment.update!(attributes_for(assessment_name, :complete))
      end

      failed_inspection.structure_assessment.update!(
        seam_integrity_pass: false,
        seam_integrity_comment: "Torn seam on left side"
      )

      pdf_text = get_pdf_text(inspection_path(failed_inspection, format: :pdf))

      expect_pdf_to_include_i18n(pdf_text, "pdf.inspection.failed")

      expect(pdf_text).to include("Torn seam on left side")
      expect(pdf_text).to include("Multiple safety issues found")
      expect_pdf_to_include_i18n(pdf_text, "pdf.inspection.risk_assessment")
    end

    scenario "includes all assessment types when present" do
      special_unit = create(:unit, user: user)

      inspection = create(:inspection, :completed,
        user: user,
        unit: special_unit)

      text_content = get_pdf_text(inspection_path(inspection, format: :pdf))

      ASSESSMENT_FORMS.each do |form|
        expect(text_content).to include(I18n.t("forms.#{form}.header"))
      end
    end

    scenario "handles user without RPII number correctly" do
      user_without_rpii = create(:user, :without_rpii)
      inspection = create(:inspection, :completed,
        user: user_without_rpii,
        unit: unit)

      pdf_text = get_pdf_text(inspection_path(inspection, format: :pdf))

      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.inspection.equipment_details")

      expect(pdf_text).to include(user_without_rpii.name)
      expect(pdf_text).not_to include(I18n.t("pdf.inspection.fields.rpii_inspector_no"))
    end

    scenario "does not include risk assessment section when blank" do
      inspection_without_risk = create(:inspection, :completed,
        user: user,
        unit: unit,
        risk_assessment: nil)

      pdf_text = get_pdf_text(inspection_path(inspection_without_risk, format: :pdf))

      expect(pdf_text).not_to include(I18n.t("pdf.inspection.risk_assessment"))
    end

    scenario "handles N/A enum values correctly" do
      inspection = create(:inspection, :completed,
        user: user,
        unit: unit,
        has_slide: true)

      # Set slide assessment with N/A value
      inspection.slide_assessment.update!(
        clamber_netting_pass: "na",
        slide_platform_height: 2.0,
        slide_wall_height: 1.5
      )

      # Set materials assessment with mixed values
      inspection.materials_assessment.update!(
        ropes_pass: "na",
        ropes: 16,
        retention_netting_pass: true,
        zips_pass: false
      )

      pdf_text = get_pdf_text(inspection_path(inspection, format: :pdf))

      # Check that N/A indicators appear
      expect(pdf_text).to include("[N/A]")

      # Check that we still have passes and fails
      expect(pdf_text).to include("[PASS]")
      expect(pdf_text).to include("[FAIL]")
    end

    scenario "shows IN PROGRESS for inspections without passed value" do
      in_progress_inspection = create(:inspection,
        user: user,
        unit: unit,
        passed: nil,
        complete_date: nil)

      pdf_text = get_pdf_text(inspection_path(in_progress_inspection, format: :pdf))

      expect(pdf_text).to include("IN PROGRESS")
      expect(pdf_text).not_to include(I18n.t("pdf.inspection.passed"))
      expect(pdf_text).not_to include(I18n.t("pdf.inspection.failed"))
    end
  end

  feature "Unit History PDF Content" do
    scenario "includes unit details and inspection history" do
      inspections = []
      3.times do |i|
        inspections << create(:inspection, :completed,
          user: user,
          unit: unit,
          inspection_date: i.months.ago,
          passed: i.even?)
      end

      pdf_text = get_pdf_text(unit_report_path(unit))

      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.unit.fields.unit_id",
        "pdf.unit.details",
        "pdf.unit.inspection_history")

      expect(pdf_text).to include(unit.name)
      expect(pdf_text).to include(unit.manufacturer)
      expect(pdf_text).to include(unit.serial)

      inspections.each do |inspection|
        expect(pdf_text).to include(inspection.inspection_date.strftime("%-d %B, %Y"))
      end
    end

    scenario "handles unit with no inspections" do
      empty_unit = create(:unit, user: user)

      pdf_text = get_pdf_text(unit_report_path(empty_unit))

      expect_pdf_to_include_i18n(pdf_text, "pdf.unit.fields.unit_id")
      expect_pdf_to_include_i18n(pdf_text, "pdf.unit.no_completed_inspections")
    end

    scenario "handles unit with image and multiple prior inspections" do
      unit_with_image = create(:unit, user: user,
        name: "Castle with Photo",
        manufacturer: "Photo Test Co",
        serial: "PTC-2024-IMG")

      unit_with_image.photo.attach(
        io: Rails.root.join("spec/fixtures/files/test_image.jpg").open,
        filename: "test_castle.jpg",
        content_type: "image/jpeg"
      )

      inspections = []
      3.times do |i|
        inspections << create(:inspection, :completed,
          user: user,
          unit: unit_with_image,
          inspection_date: i.months.ago,
          passed: i.even?,
          inspection_location: "Photo Location #{i + 1}")
      end

      start_time = Time.current
      pdf_data = get_pdf(unit_report_path(unit_with_image))
      generation_time = Time.current - start_time

      expect(generation_time).to be < 15.seconds

      expect_valid_pdf(pdf_data)
      expect(pdf_data).to include("/Image")

      pdf_text = pdf_text_content(pdf_data)

      expect_pdf_to_include_i18n_keys(pdf_text,
        "pdf.unit.fields.unit_id",
        "pdf.unit.details",
        "pdf.unit.inspection_history")

      expect(pdf_text).to include("Castle with Photo")
      expect(pdf_text).to include("Photo Test Co")
      expect(pdf_text).to include("PTC-2024-IMG")

      inspections.each do |inspection|
        expect(pdf_text).to include(inspection.inspection_date.strftime("%-d %B, %Y"))
      end

      inspections.each_with_index do |inspection, index|
        if inspection.passed?
          expect(pdf_text).to include(I18n.t("shared.pass_pdf"))
        else
          expect(pdf_text).to include(I18n.t("shared.fail_pdf"))
        end
      end

      expect(pdf_data.bytesize).to be < 5.megabytes
      expect(pdf_data.bytesize).to be > 10.kilobytes
    end
  end

  private

  def unit_report_path(unit)
    "/units/#{unit.id}.pdf"
  end
end
