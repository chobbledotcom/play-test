require "rails_helper"

RSpec.describe StructureAssessment, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:assessment) { create(:structure_assessment, inspection: inspection) }

  describe "associations" do
    it "belongs to inspection" do
      expect(assessment.inspection).to eq(inspection)
    end
  end

  describe "constants" do
    it "defines critical checks" do
      expect(StructureAssessment::CRITICAL_CHECKS).to eq([
        "seam_integrity_pass", "lock_stitch_pass", "air_loss_pass",
        "straight_walls_pass", "sharp_edges_pass", "unit_stable_pass"
      ])
    end
  end

  describe "validations" do
    context "critical checks" do
      StructureAssessment::CRITICAL_CHECKS.each do |check|
        it "allows nil for #{check}" do
          assessment.send("#{check}=", nil)
          expect(assessment).to be_valid
        end

        it "allows true/false for #{check}" do
          assessment.send("#{check}=", true)
          expect(assessment).to be_valid

          assessment.send("#{check}=", false)
          expect(assessment).to be_valid
        end
      end
    end

    context "additional pass/fail checks" do
      %w[stitch_length_pass blower_tube_length_pass evacuation_time_pass
        step_size_pass fall_off_height_pass unit_pressure_pass
        trough_pass entrapment_pass markings_pass grounding_pass].each do |check|
        it "allows true/false for #{check}" do
          assessment.send("#{check}=", true)
          expect(assessment).to be_valid

          assessment.send("#{check}=", false)
          expect(assessment).to be_valid
        end
      end
    end

    context "measurements" do
      %w[stitch_length evacuation_time unit_pressure_value blower_tube_length
        step_size_value fall_off_height_value trough_depth_value trough_width_value].each do |measurement|
        it "validates #{measurement} is non-negative" do
          assessment.send("#{measurement}=", -1.0)
          expect(assessment).not_to be_valid
          expect(assessment.errors[measurement.to_sym]).to include("must be greater than or equal to 0")
        end

        it "allows blank #{measurement}" do
          assessment.send("#{measurement}=", nil)
          expect(assessment).to be_valid
        end
      end
    end
  end

  describe "#complete?" do
    it "returns true when all sections are complete" do
      # Set all critical checks
      StructureAssessment::CRITICAL_CHECKS.each do |check|
        assessment.send("#{check}=", true)
      end

      # Set required measurements
      assessment.stitch_length = 5.0
      assessment.evacuation_time = 25.0
      assessment.unit_pressure_value = 1.5
      assessment.blower_tube_length = 1.5

      # Set additional checks
      assessment.stitch_length_pass = true
      assessment.evacuation_time_pass = true
      assessment.unit_pressure_pass = true
      assessment.blower_tube_length_pass = true
      assessment.step_size_pass = true
      assessment.fall_off_height_pass = true

      expect(assessment.complete?).to be true
    end

    it "returns false when critical checks are missing" do
      assessment.seam_integrity_pass = nil
      expect(assessment.complete?).to be false
    end

    it "returns false when measurements are missing" do
      StructureAssessment::CRITICAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.stitch_length = nil
      expect(assessment.complete?).to be false
    end

    it "returns false when additional checks are missing" do
      StructureAssessment::CRITICAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.stitch_length = 5.0
      assessment.evacuation_time = 25.0
      assessment.unit_pressure_value = 1.5
      assessment.blower_tube_length = 1.5
      assessment.stitch_length_pass = nil
      expect(assessment.complete?).to be false
    end
  end

  describe "#has_critical_failures?" do
    it "returns true when any critical check fails" do
      StructureAssessment::CRITICAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.seam_integrity_pass = false
      expect(assessment.has_critical_failures?).to be true
    end

    it "returns false when all critical checks pass" do
      StructureAssessment::CRITICAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      expect(assessment.has_critical_failures?).to be false
    end

    it "returns false when critical checks are nil" do
      expect(assessment.has_critical_failures?).to be false
    end
  end

  describe "#safety_check_count" do
    it "returns total number of safety checks" do
      expect(assessment.safety_check_count).to eq(16) # 6 critical + 10 additional
    end
  end

  describe "#passed_checks_count" do
    it "counts all passed checks" do
      StructureAssessment::CRITICAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.stitch_length_pass = true
      assessment.blower_tube_length_pass = false
      assessment.evacuation_time_pass = true

      count = assessment.passed_checks_count
      expect(count).to be >= 8 # At least the 6 critical + 2 additional
    end

    it "returns 0 when no checks are completed" do
      expect(assessment.passed_checks_count).to eq(0)
    end
  end

  describe "#completion_percentage" do
    it "calculates percentage of completed fields" do
      StructureAssessment::CRITICAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.stitch_length = 5.0
      assessment.evacuation_time = 25.0
      # Leave other fields blank

      percentage = assessment.completion_percentage
      expect(percentage).to be > 0
      expect(percentage).to be <= 100
    end

    it "returns 0 for empty assessment" do
      expect(assessment.completion_percentage).to eq(0)
    end
  end

  describe "#critical_failure_summary" do
    it "returns 'No critical failures' when all pass" do
      StructureAssessment::CRITICAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      expect(assessment.critical_failure_summary).to eq("No critical failures")
    end

    it "lists failed critical checks" do
      assessment.seam_integrity_pass = false
      assessment.air_loss_pass = false
      summary = assessment.critical_failure_summary
      expect(summary).to include("Seam integrity pass")
      expect(summary).to include("Air loss pass")
    end
  end

  describe "#measurement_compliance" do
    it "returns compliance status for all measurements" do
      assessment.stitch_length = 5.0
      assessment.evacuation_time = 25.0
      assessment.unit_pressure_value = 1.5
      assessment.blower_tube_length = 1.5
      assessment.fall_off_height_value = 0.5

      compliance = assessment.measurement_compliance

      expect(compliance).to have_key(:stitch_length)
      expect(compliance).to have_key(:evacuation_time)
      expect(compliance).to have_key(:unit_pressure)
      expect(compliance).to have_key(:blower_tube_distance)
      expect(compliance).to have_key(:fall_off_height)
    end
  end

  describe "measurement compliance methods" do
    describe "stitch_length_compliant?" do
      it "delegates to SafetyStandard" do
        assessment.stitch_length = 5.0
        expect(SafetyStandard).to receive(:valid_stitch_length?).with(5.0)
        assessment.send(:stitch_length_compliant?)
      end
    end

    describe "evacuation_time_compliant?" do
      it "delegates to SafetyStandard" do
        assessment.evacuation_time = 25.0
        expect(SafetyStandard).to receive(:valid_evacuation_time?).with(25.0)
        assessment.send(:evacuation_time_compliant?)
      end
    end

    describe "unit_pressure_compliant?" do
      it "delegates to SafetyStandard" do
        assessment.unit_pressure_value = 1.5
        expect(SafetyStandard).to receive(:valid_pressure?).with(1.5)
        assessment.send(:unit_pressure_compliant?)
      end
    end

    describe "blower_tube_distance_compliant?" do
      it "returns true when distance >= 1.2m" do
        assessment.blower_tube_length = 1.5
        expect(assessment.send(:blower_tube_distance_compliant?)).to be true
      end

      it "returns false when distance < 1.2m" do
        assessment.blower_tube_length = 1.0
        expect(assessment.send(:blower_tube_distance_compliant?)).to be false
      end

      it "returns false when distance is nil" do
        assessment.blower_tube_length = nil
        expect(assessment.send(:blower_tube_distance_compliant?)).to be false
      end
    end

    describe "fall_off_height_compliant?" do
      it "delegates to SafetyStandard" do
        assessment.fall_off_height_value = 0.5
        expect(SafetyStandard).to receive(:valid_fall_height?).with(0.5)
        assessment.send(:fall_off_height_compliant?)
      end
    end
  end

  describe "audit logging" do
    it "logs assessment updates" do
      expect(assessment).to receive(:log_assessment_update)
      assessment.update!(stitch_length: 5.0)
    end
  end

  describe "edge cases" do
    it "handles extreme measurement values" do
      assessment.update!(
        stitch_length: 999.99,
        evacuation_time: 999.99,
        unit_pressure_value: 999.99
      )

      expect(assessment).to be_valid
    end

    it "handles zero measurement values" do
      assessment.update!(
        stitch_length: 0,
        evacuation_time: 0,
        unit_pressure_value: 0
      )

      expect(assessment).to be_valid
    end

    it "handles mixed pass/fail states" do
      assessment.seam_integrity_pass = true
      assessment.lock_stitch_pass = false
      assessment.air_loss_pass = true
      assessment.straight_walls_pass = false
      assessment.sharp_edges_pass = true
      assessment.unit_stable_pass = false

      expect(assessment.has_critical_failures?).to be true
      expect(assessment.passed_checks_count).to eq(3)
    end
  end
end
