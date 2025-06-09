require "rails_helper"

RSpec.describe InspectionsHelper, type: :helper do
  describe "#format_inspection_count" do
    it "formats the inspection count with limit if limit is positive" do
      user = double("User", inspections: double("Inspections", count: 5), inspection_limit: 10)
      expect(helper.format_inspection_count(user)).to eq("5 / 10 inspections")
    end

    it "formats the inspection count without limit if limit is zero" do
      user = double("User", inspections: double("Inspections", count: 5), inspection_limit: 0)
      expect(helper.format_inspection_count(user)).to eq("5 inspections")
    end
  end

  describe "#assessment_completion_percentage" do
    let(:user) { create(:user) }
    let(:inspection) { create(:inspection, user: user) }

    context "with no assessments" do
      it "returns 0" do
        expect(helper.assessment_completion_percentage(inspection)).to eq(0)
      end
    end

    context "with incomplete assessments" do
      before do
        # Create assessments but don't complete them
        inspection.create_user_height_assessment!(containing_wall_height: 1.0)
        inspection.create_slide_assessment!(slide_platform_height: 2.0)
      end

      it "returns 0 when no assessments are complete" do
        expect(helper.assessment_completion_percentage(inspection)).to eq(0)
      end
    end

    context "with partially complete assessments" do
      before do
        # Complete one assessment
        create(:user_height_assessment, :with_basic_data,
          inspection: inspection,
          tallest_user_height_comment: "Complete")

        # Add incomplete assessment
        inspection.create_slide_assessment!(slide_platform_height: 2.0)
      end

      it "calculates percentage based on completed assessments" do
        # With 1 complete out of 6 expected assessments
        percentage = helper.assessment_completion_percentage(inspection)
        expect(percentage).to be > 0
        expect(percentage).to be <= 100
      end
    end

    context "with all assessments complete" do
      before do
        # Create all complete assessments
        create(:user_height_assessment, :with_basic_data,
          inspection: inspection,
          tallest_user_height_comment: "Complete")

        inspection.create_slide_assessment!(
          slide_platform_height: 2.0,
          slide_wall_height: 1.5,
          runout_value: 1.0,
          clamber_netting_pass: true,
          runout_pass: true,
          slip_sheet_pass: true
        )

        inspection.create_structure_assessment!(
          # Critical checks
          seam_integrity_pass: true,
          lock_stitch_pass: true,
          air_loss_pass: true,
          straight_walls_pass: true,
          sharp_edges_pass: true,
          unit_stable_pass: true,
          # Required measurements
          stitch_length: 5.0,
          unit_pressure_value: 250,
          blower_tube_length: 2.0,
          # Measurement pass/fail checks
          stitch_length_pass: true,
          unit_pressure_pass: true,
          blower_tube_length_pass: true,
          # Additional checks required for complete
          step_size_pass: true,
          fall_off_height_pass: true
        )

        inspection.create_anchorage_assessment!(
          num_low_anchors: 4,
          num_high_anchors: 4,
          num_anchors_pass: true,
          anchor_type_pass: true,
          pull_strength_pass: true,
          anchor_degree_pass: true,
          anchor_accessories_pass: true
        )

        inspection.create_materials_assessment!(
          rope_size: 10,
          rope_size_pass: true,
          clamber_pass: true,
          retention_netting_pass: true,
          zips_pass: true,
          windows_pass: true,
          artwork_pass: true,
          thread_pass: true,
          fabric_pass: true,
          fire_retardant_pass: true
        )

        inspection.create_fan_assessment!(
          blower_flap_pass: true,
          blower_finger_pass: true,
          blower_visual_pass: true,
          pat_pass: true,
          blower_serial: "FAN-12345",
          fan_size_comment: "Standard 1.5HP blower"
        )
      end

      it "returns 100 when all assessments are complete" do
        expect(helper.assessment_completion_percentage(inspection)).to eq(100)
      end
    end

    context "with totally enclosed unit" do
      before do
        unit = create(:unit, is_totally_enclosed: true)
        inspection.update!(unit: unit)
      end

      it "includes enclosed assessment in calculation" do
        # Create all assessments including enclosed
        create(:user_height_assessment, :with_basic_data,
          inspection: inspection,
          tallest_user_height_comment: "Complete")

        inspection.create_enclosed_assessment!(
          exit_number: 2,
          exit_number_pass: true,
          exit_visible_pass: true
        )

        # Should calculate based on 7 assessments for totally enclosed
        percentage = helper.assessment_completion_percentage(inspection)
        expect(percentage).to be > 0
      end
    end
  end

  describe "#inspection_tabs" do
    let(:user) { create(:user) }
    let(:inspection) { create(:inspection, user: user) }

    it "returns standard tabs for regular units" do
      tabs = helper.inspection_tabs(inspection)
      expect(tabs).to eq(%w[general user_height structure anchorage materials fan])
    end

    it "includes enclosed tab for totally enclosed units" do
      unit = create(:unit, is_totally_enclosed: true)
      inspection.update!(unit: unit, is_totally_enclosed: true)

      tabs = helper.inspection_tabs(inspection)
      expect(tabs).to include("enclosed")
      expect(tabs.count).to eq(7) # Standard tabs plus enclosed
    end

    it "includes slide tab for units with slides" do
      unit = create(:unit, has_slide: true)
      inspection.update!(unit: unit, has_slide: true)

      tabs = helper.inspection_tabs(inspection)
      expect(tabs).to include("slide")
      expect(tabs).to eq(%w[general user_height slide structure anchorage materials fan])
    end
  end

  describe "#inspection_actions" do
    let(:user) { create(:user) }
    let(:admin_user) { create(:user, email: "admin@example.com") }
    let(:inspection) { create(:inspection, user: user) }
    let(:complete_inspection) do
      inspection = create(:inspection, :complete, user: user)
      # Bypass validation to set complete status for testing
      inspection.update_column(:status, "complete")
      inspection
    end

    before do
      # Set up admin pattern
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ADMIN_EMAILS_PATTERN").and_return("admin@")
    end

    context "for non-complete inspections" do
      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "includes edit and delete actions" do
        actions = helper.inspection_actions(inspection)

        expect(actions).to include(
          hash_including(label: I18n.t("inspections.buttons.update"))
        )
        expect(actions).to include(
          hash_including(
            label: I18n.t("inspections.buttons.delete"),
            method: :delete,
            danger: true
          )
        )
      end
    end

    context "for complete inspections with regular user" do
      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it "includes both edit and delete actions" do
        actions = helper.inspection_actions(complete_inspection)

        expect(actions).to include(
          hash_including(label: I18n.t("inspections.buttons.update"))
        )
        expect(actions).to include(
          hash_including(label: I18n.t("inspections.buttons.delete"))
        )
      end
    end

    context "for complete inspections with admin user" do
      before do
        allow(helper).to receive(:current_user).and_return(admin_user)
      end

      it "includes both edit and delete actions" do
        actions = helper.inspection_actions(complete_inspection)

        expect(actions).to include(
          hash_including(label: I18n.t("inspections.buttons.update"))
        )
        expect(actions).to include(
          hash_including(
            label: I18n.t("inspections.buttons.delete"),
            method: :delete,
            danger: true
          )
        )
      end
    end

    context "when current_user is nil" do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it "includes both edit and delete actions for complete inspections" do
        actions = helper.inspection_actions(complete_inspection)

        expect(actions).to include(
          hash_including(label: I18n.t("inspections.buttons.update"))
        )
        expect(actions).to include(
          hash_including(label: I18n.t("inspections.buttons.delete"))
        )
      end
    end
  end
end
