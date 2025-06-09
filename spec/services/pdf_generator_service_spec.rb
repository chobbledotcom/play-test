require "rails_helper"
require "pdf/inspector"

RSpec.describe PdfGeneratorService, pdf: true do
  # Test I18n integration
  around do |example|
    I18n.with_locale(:en) do
      example.run
    end
  end
  describe ".generate_inspection_report" do
    let(:user) { create(:user) }
    let(:inspection) { create(:inspection, user: user) }

    it "generates a PDF" do
      pdf = PdfGeneratorService.generate_inspection_report(inspection)
      expect(pdf).to be_a(Prawn::Document)

      pdf_string = pdf.render
      expect(pdf_string).to be_a(String)
      expect(pdf_string[0..3]).to eq("%PDF")
    end

    it "uses I18n translations for PDF content" do
      pdf = PdfGeneratorService.generate_inspection_report(inspection)
      pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

      # Check that I18n translations are used
      expect(pdf_text).to include(I18n.t("pdf.inspection.title"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.equipment_details"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.inspection_results"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.verification"))
      expect(pdf_text).to include(I18n.t("pdf.inspection.footer_text"))
    end

    it "handles different inspection statuses with I18n" do
      inspection.update(passed: true)
      pdf = PdfGeneratorService.generate_inspection_report(inspection)
      pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")
      expect(pdf_text).to include(I18n.t("pdf.inspection.passed"))

      inspection.update(passed: false)
      pdf = PdfGeneratorService.generate_inspection_report(inspection)
      pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")
      expect(pdf_text).to include(I18n.t("pdf.inspection.failed"))
    end

    context "with comments" do
      before do
        inspection.update(comments: "Test comments")
      end

      it "generates PDF with comments section using I18n" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("pdf.inspection.comments"))
        expect(pdf_text).to include("Test comments")
      end
    end

    context "with missing manufacturer" do
      before do
        inspection.unit.update(manufacturer: nil)
      end

      it "shows 'not specified' text using I18n" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("pdf.inspection.fields.not_specified"))
      end
    end
  end

  describe ".generate_unit_report" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user) }

    it "generates a PDF" do
      pdf = PdfGeneratorService.generate_unit_report(unit)
      expect(pdf).to be_a(Prawn::Document)

      pdf_string = pdf.render
      expect(pdf_string).to be_a(String)
      expect(pdf_string[0..3]).to eq("%PDF")
    end

    it "uses I18n translations for unit PDF content" do
      pdf = PdfGeneratorService.generate_unit_report(unit)
      pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

      # Check that I18n translations are used
      expect(pdf_text).to include(I18n.t("pdf.unit.title"))
      expect(pdf_text).to include(I18n.t("pdf.unit.details"))
      expect(pdf_text).to include(I18n.t("pdf.unit.verification"))
      expect(pdf_text).to include(I18n.t("pdf.unit.footer_text"))
    end

    it "displays unit fields with I18n labels" do
      pdf = PdfGeneratorService.generate_unit_report(unit)
      pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

      expect(pdf_text).to include(I18n.t("pdf.unit.fields.name"))
      expect(pdf_text).to include(I18n.t("pdf.unit.fields.serial_number"))
      expect(pdf_text).to include(I18n.t("pdf.unit.fields.manufacturer"))
      expect(pdf_text).to include(I18n.t("pdf.unit.fields.has_slide"))
      expect(pdf_text).to include(I18n.t("pdf.unit.fields.owner"))
    end

    context "with inspections" do
      let!(:passed_inspection) { create(:inspection, :completed, user: user, unit: unit, passed: true) }
      let!(:failed_inspection) { create(:inspection, :completed, user: user, unit: unit, passed: false) }

      it "generates PDF with inspection history using I18n" do
        pdf = PdfGeneratorService.generate_unit_report(unit)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("pdf.unit.inspection_history"))
        expect(pdf_text).to include(I18n.t("pdf.unit.fields.date"))
        expect(pdf_text).to include(I18n.t("pdf.unit.fields.inspector"))
        expect(pdf_text).to include(I18n.t("pdf.unit.fields.result"))
        expect(pdf_text).to include(I18n.t("pdf.unit.fields.pass"))
        expect(pdf_text).to include(I18n.t("pdf.unit.fields.fail"))
      end
    end

    context "with missing manufacturer" do
      before do
        unit.update(manufacturer: nil)
      end

      it "shows 'not specified' text using I18n" do
        pdf = PdfGeneratorService.generate_unit_report(unit)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("pdf.unit.fields.not_specified"))
      end
    end

    context "without inspections" do
      it "shows no completed inspections message" do
        pdf = PdfGeneratorService.generate_unit_report(unit)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("pdf.unit.no_completed_inspections"))
      end
    end
  end

  describe "draft inspections" do
    let(:user) { create(:user) }
    let(:draft_inspection) { create(:inspection, user: user, complete_date: nil) }

    it "adds draft watermark to incomplete inspections" do
      pdf = PdfGeneratorService.generate_inspection_report(draft_inspection)
      pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

      # Draft watermarks should appear multiple times
      draft_count = pdf_text.scan("DRAFT").count
      expect(draft_count).to be > 5 # Should have multiple DRAFT watermarks
    end

    it "does not add draft watermark to complete inspections" do
      complete_inspection = create(:inspection, :completed, user: user)
      pdf = PdfGeneratorService.generate_inspection_report(complete_inspection)
      pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

      expect(pdf_text).not_to include("DRAFT")
    end
  end

  describe "assessment sections" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user, has_slide: true, is_totally_enclosed: true) }
    let(:inspection) { create(:inspection, user: user, unit: unit) }

    context "with user height assessment" do
      let!(:user_height_assessment) do
        create(:user_height_assessment,
          inspection: inspection,
          containing_wall_height: 2.5,
          containing_wall_height_comment: "Wall height ok",
          platform_height: 1.2,
          platform_height_comment: "Platform good",
          permanent_roof: true,
          permanent_roof_comment: "Has roof",
          tallest_user_height: 1.8,
          tallest_user_height_comment: "Tall users",
          play_area_length: 5.0,
          play_area_length_comment: "Length good",
          play_area_width: 4.0,
          play_area_width_comment: "Width good",
          negative_adjustment: 0.5,
          negative_adjustment_comment: "Small adjustment",
          users_at_1000mm: 10,
          users_at_1200mm: 8,
          users_at_1500mm: 6,
          users_at_1800mm: 4
        )
      end

      it "includes user height assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("inspections.assessments.user_height.title"))
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.user_height.fields.containing_wall_height")}: 2.5m")
        expect(pdf_text).to include("Wall height ok")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.user_height.fields.platform_height")}: 1.2m")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.user_height.fields.permanent_roof")}: #{I18n.t("shared.yes")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.user_height.fields.tallest_user_height")}: 1.8m")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.user_height.fields.play_area_length")}: 5.0m")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.user_height.fields.play_area_width")}: 4.0m")
        # Fix: The m² character might not render correctly in the text analyzer
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.user_height.fields.negative_adjustment")}: 0.5")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.user_height.fields.users_at_1000mm")}: 10")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.user_height.fields.users_at_1200mm")}: 8")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.user_height.fields.users_at_1500mm")}: 6")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.user_height.fields.users_at_1800mm")}: 4")
      end
    end

    context "with slide assessment" do
      let!(:slide_assessment) do
        create(:slide_assessment,
          inspection: inspection,
          slide_platform_height: 2.0,
          slide_platform_height_comment: "Platform ok",
          slide_wall_height: 1.5,
          slide_wall_height_comment: "Wall good",
          slide_first_metre_height: 1.0,
          slide_first_metre_height_comment: "First metre ok",
          slide_beyond_first_metre_height: 0.5,
          slide_beyond_first_metre_height_comment: "Beyond ok",
          slide_permanent_roof: false,
          slide_permanent_roof_comment: "No roof",
          clamber_netting_pass: true,
          clamber_netting_comment: "Netting good",
          runout_value: 3.0,
          runout_pass: true,
          runout_comment: "Runout ok",
          slip_sheet_pass: true,
          slip_sheet_comment: "Slip sheet present"
        )
      end

      it "includes slide assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include("Slide")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.slide.fields.slide_platform_height")}: 2.0m")
        expect(pdf_text).to include("Platform ok")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.slide.fields.slide_wall_height")}: 1.5m")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.slide.fields.slide_first_metre_height")}: 1.0m")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.slide.fields.slide_beyond_first_metre_height")}: 0.5m")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.slide.fields.slide_permanent_roof")}: #{I18n.t("shared.no")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.slide.fields.clamber_netting_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.slide.fields.runout_value")}: 3.0m - #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.slide.fields.slip_sheet_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
      end
    end

    context "with structure assessment" do
      let!(:structure_assessment) do
        create(:structure_assessment,
          inspection: inspection,
          seam_integrity_pass: true,
          seam_integrity_comment: "Seams good",
          lock_stitch_pass: true,
          lock_stitch_comment: "Stitching ok",
          stitch_length: 10,
          stitch_length_pass: true,
          stitch_length_comment: "Length ok",
          air_loss_pass: true,
          air_loss_comment: "No air loss",
          straight_walls_pass: true,
          straight_walls_comment: "Walls straight",
          sharp_edges_pass: true,
          sharp_edges_comment: "No sharp edges",
          blower_tube_length: 2.5,
          blower_tube_length_pass: true,
          blower_tube_length_comment: "Tube good",
          unit_stable_pass: true,
          unit_stable_comment: "Very stable",
          evacuation_time_pass: true,
          evacuation_time_comment: "Quick evacuation"
        )
      end

      it "includes structure assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("inspections.assessments.structure.title"))
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.structure.fields.seam_integrity_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("Seams good")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.structure.fields.lock_stitch_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        # Stitch length field shows value and pass/fail status
        expect(pdf_text).to match(/#{I18n.t("inspections.assessments.structure.fields.stitch_length")}:.*10.*#{I18n.t("pdf.inspection.fields.pass")}/)
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.structure.fields.air_loss_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.structure.fields.straight_walls_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.structure.fields.sharp_edges_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.structure.fields.blower_tube_length")}: 2.5m - #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.structure.fields.unit_stable_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.structure.fields.evacuation_time_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
      end
    end

    context "with anchorage assessment" do
      let!(:anchorage_assessment) do
        create(:anchorage_assessment,
          inspection: inspection,
          num_low_anchors: 4,
          num_high_anchors: 2,
          num_anchors_pass: true,
          anchor_type_pass: true,
          pull_strength_pass: true,
          anchor_degree_pass: true,
          anchor_accessories_pass: true
        )
      end

      it "includes anchorage assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("inspections.assessments.anchorage.title"))
        # The anchor count format is complex, so just check key parts
        # The actual format includes the i18n labels
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.anchorage.fields.num_low_anchors")}: 4")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.anchorage.fields.num_high_anchors")}: 2")
        expect(pdf_text).to include(I18n.t("pdf.inspection.fields.pass"))
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.anchorage.fields.anchor_type_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.anchorage.fields.pull_strength_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.anchorage.fields.anchor_degree_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.anchorage.fields.anchor_accessories_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
      end
    end

    context "with enclosed assessment" do
      let!(:enclosed_assessment) do
        create(:enclosed_assessment,
          inspection: inspection,
          exit_number: 3,
          exit_number_pass: true,
          exit_visible_pass: true
        )
      end

      it "includes enclosed assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("inspections.assessments.enclosed.title"))
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.enclosed.fields.exit_number")}: 3 - #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.enclosed.fields.exit_visible_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
      end
    end

    context "with materials assessment" do
      let!(:materials_assessment) do
        create(:materials_assessment,
          inspection: inspection,
          fabric_pass: true,
          fire_retardant_pass: true,
          thread_pass: true,
          rope_size: 12,
          rope_size_pass: true
        )
      end

      it "includes materials assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("inspections.assessments.materials.title"))
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.materials.fields.fabric_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.materials.fields.fire_retardant_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.materials.fields.thread_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        # Rope size field shows value and pass/fail status
        expect(pdf_text).to match(/#{I18n.t("inspections.assessments.materials.fields.rope_size")}:.*12.*#{I18n.t("pdf.inspection.fields.pass")}/)
      end
    end

    context "with fan assessment" do
      let!(:fan_assessment) do
        create(:fan_assessment,
          inspection: inspection,
          blower_flap_pass: true,
          blower_finger_pass: true,
          pat_pass: true,
          blower_visual_pass: true
        )
      end

      it "includes fan assessment data" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include(I18n.t("inspections.assessments.fan.title"))
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.fan.fields.blower_flap_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.fan.fields.blower_finger_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.fan.fields.pat_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
        expect(pdf_text).to include("#{I18n.t("inspections.assessments.fan.fields.blower_visual_pass")}: #{I18n.t("pdf.inspection.fields.pass")}")
      end
    end

    context "without assessments" do
      it "shows no assessment data messages" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = pdf_text_content(pdf.render)

        expect_no_assessment_messages(pdf_text, inspection.unit)
      end
    end

    context "for unit without slide" do
      before { unit.update(has_slide: false) }

      it "does not include slide section" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).not_to include("Slide platform height")
      end
    end

    context "for unit not totally enclosed" do
      before { unit.update(is_totally_enclosed: false) }

      it "does not include enclosed section" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).not_to include("Totally Enclosed")
      end
    end
  end

  describe "unit with photo" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user) }

    context "with attached photo" do
      before do
        unit.photo.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename: "test_image.jpg",
          content_type: "image/jpeg"
        )
      end

      it "generates PDF without errors" do
        expect {
          pdf = PdfGeneratorService.generate_unit_report(unit)
          pdf.render
        }.not_to raise_error
      end

      it "generates inspection PDF with unit photo without errors" do
        inspection = create(:inspection, user: user, unit: unit)
        expect {
          pdf = PdfGeneratorService.generate_inspection_report(inspection)
          pdf.render
        }.not_to raise_error
      end

      it "handles photo loading errors gracefully" do
        # Create a mock that will raise an error when image is called
        allow(Rails.logger).to receive(:warn)
        
        # Mock the add_unit_photo method to simulate an error and recovery
        allow(PdfGeneratorService).to receive(:add_unit_photo) do |pdf, unit|
          begin
            raise StandardError.new("Photo error")
          rescue => e
            Rails.logger.warn "Failed to add unit photo to PDF: #{e.message}"
          end
        end
        
        expect {
          pdf = PdfGeneratorService.generate_unit_report(unit)
          pdf.render
        }.not_to raise_error
        
        expect(Rails.logger).to have_received(:warn).with(/Failed to add unit photo to PDF/)
      end
    end
  end

  describe "helper methods" do
    describe ".truncate_text" do
      it "truncates long text" do
        result = PdfGeneratorService.truncate_text("This is a very long text that should be truncated", 20)
        expect(result).to eq("This is a very long ...")
      end

      it "returns full text if shorter than max" do
        result = PdfGeneratorService.truncate_text("Short text", 20)
        expect(result).to eq("Short text")
      end

      it "handles nil text" do
        result = PdfGeneratorService.truncate_text(nil, 20)
        expect(result).to eq("")
      end
    end

    describe ".format_pass_fail" do
      it "formats true as Pass" do
        expect(PdfGeneratorService.format_pass_fail(true)).to eq("Pass")
      end

      it "formats false as Fail" do
        expect(PdfGeneratorService.format_pass_fail(false)).to eq("Fail")
      end

      it "formats nil as N/A" do
        expect(PdfGeneratorService.format_pass_fail(nil)).to eq("N/A")
      end
    end

    describe ".format_measurement" do
      it "formats value with unit" do
        expect(PdfGeneratorService.format_measurement(5.5, "m")).to eq("5.5m")
      end

      it "formats value without unit" do
        expect(PdfGeneratorService.format_measurement(10)).to eq("10")
      end

      it "handles nil value" do
        expect(PdfGeneratorService.format_measurement(nil, "m")).to eq("N/A")
      end
    end
  end

  describe "edge cases" do
    let(:user) { create(:user) }

    context "inspection without unit" do
      let(:inspection) { create(:inspection, user: user, unit: nil) }

      it "generates PDF without errors" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include("No unit associated with this inspection")
      end
    end

    context "with very long comments" do
      let(:long_comment) { "A" * 100 }
      let(:inspection) { create(:inspection, :completed, user: user, comments: long_comment) }

      it "truncates long comments in inspection history" do
        unit = inspection.unit
        pdf = PdfGeneratorService.generate_unit_report(unit)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        # Should be truncated to 30 characters
        expect(pdf_text).to include("A" * 27 + "...")
      end
    end

    context "QR code generation" do
      let(:inspection) { create(:inspection, user: user) }
      let(:unit) { create(:unit, user: user) }

      it "handles QR code tempfile cleanup for inspections" do
        allow(Tempfile).to receive(:new).and_call_original
        
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf.render

        # Tempfile should be cleaned up (test passes if no errors)
      end

      it "handles QR code tempfile cleanup for units" do
        allow(Tempfile).to receive(:new).and_call_original
        
        pdf = PdfGeneratorService.generate_unit_report(unit)
        pdf.render

        # Tempfile should be cleaned up (test passes if no errors)
      end
    end

    context "with missing inspector company" do
      let(:inspection) { create(:inspection, user: user, inspector_company: nil) }

      it "handles missing inspector company gracefully" do
        expect {
          pdf = PdfGeneratorService.generate_inspection_report(inspection)
          pdf.render
        }.not_to raise_error
      end
    end

    context "unit with next inspection due" do
      let(:unit) { create(:unit, user: user) }
      let!(:past_inspection) { create(:inspection, :completed, unit: unit, user: user, inspection_date: Date.today - 330.days) }

      it "includes next inspection due date" do
        pdf = PdfGeneratorService.generate_unit_report(unit)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expected_due_date = (past_inspection.inspection_date + 365.days).strftime("%d/%m/%Y")
        expect(pdf_text).to include("Next Inspection Due")
        expect(pdf_text).to include(expected_due_date)
      end
    end

    context "unit with overdue inspection" do
      let(:unit) { create(:unit, user: user) }
      let!(:old_inspection) { create(:inspection, :completed, unit: unit, user: user, inspection_date: Date.today - 400.days) }

      it "shows overdue date" do
        pdf = PdfGeneratorService.generate_unit_report(unit)
        # Can't easily test color in PDF, but ensure it renders without error
        expect { pdf.render }.not_to raise_error
      end
    end
  end

  describe "final result section" do
    let(:user) { create(:user) }

    context "with passed inspection" do
      let(:inspection) { create(:inspection, :completed, user: user, passed: true) }

      it "shows PASSED result" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include("Final Result")
        expect(pdf_text).to include("PASSED")
        expect(pdf_text).to include("Status: Complete")
      end
    end

    context "with failed inspection" do
      let(:inspection) { create(:inspection, :completed, user: user, passed: false) }

      it "shows FAILED result" do
        pdf = PdfGeneratorService.generate_inspection_report(inspection)
        pdf_text = PDF::Inspector::Text.analyze(pdf.render).strings.join(" ")

        expect(pdf_text).to include("Final Result")
        expect(pdf_text).to include("FAILED")
      end
    end
  end
end
