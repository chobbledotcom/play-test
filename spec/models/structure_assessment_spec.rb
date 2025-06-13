require "rails_helper"

RSpec.describe Assessments::StructureAssessment, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:assessment) { inspection.structure_assessment }

  # Use shared examples for common behaviors
  it_behaves_like "an assessment model"
  it_behaves_like "has safety check methods"
  it_behaves_like "delegates to SafetyStandard", [:valid_stitch_length?, :valid_pressure?, :valid_fall_height?]

  describe "constants" do
    it "defines critical checks" do
      expect(Assessments::StructureAssessment::CRITICAL_CHECKS).to eq([
        "seam_integrity_pass", "uses_lock_stitching_pass", "air_loss_pass",
        "straight_walls_pass", "sharp_edges_pass", "unit_stable_pass"
      ])
    end
  end

  describe "validations" do
    context "critical checks" do
      Assessments::StructureAssessment::CRITICAL_CHECKS.each do |field|
        include_examples "validates boolean field", field
      end
    end

    context "additional pass/fail checks" do
      %w[stitch_length_pass blower_tube_length_pass
        step_size_pass critical_fall_off_height_pass unit_pressure_pass
        trough_pass entrapment_pass markings_pass grounding_pass].each do |field|
        include_examples "validates boolean field", field
      end
    end

    context "measurements" do
      %w[stitch_length unit_pressure blower_tube_length
        step_size critical_fall_off_height trough_depth trough_width].each do |field|
        include_examples "validates non-negative numeric field", field
      end
    end

    context "comment fields" do
      (Assessments::StructureAssessment::CRITICAL_CHECKS + %w[stitch_length_pass blower_tube_length_pass
        step_size_pass critical_fall_off_height_pass unit_pressure_pass
        trough_pass entrapment_pass markings_pass grounding_pass]).map { |check| check.sub("_pass", "_comment") }.each do |field|
        include_examples "validates comment field", field
      end
    end
  end

  describe "#complete?" do
    it "returns true when all sections are complete" do
      # Use the complete factory trait
      complete_assessment = build(:structure_assessment, :complete)
      expect(complete_assessment.complete?).to be true
    end

    it "returns false when critical checks are missing" do
      assessment.seam_integrity_pass = nil
      expect(assessment.complete?).to be false
    end

    it "returns false when measurements are missing" do
      Assessments::StructureAssessment::CRITICAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.stitch_length = nil
      expect(assessment.complete?).to be false
    end

    it "returns false when additional checks are missing" do
      Assessments::StructureAssessment::CRITICAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.stitch_length = 5.0
      assessment.unit_pressure = 1.5
      assessment.blower_tube_length = 1.5
      assessment.stitch_length_pass = nil
      expect(assessment.complete?).to be false
    end
  end

  describe "#has_critical_failures?" do
    it "returns true when any critical check fails" do
      Assessments::StructureAssessment::CRITICAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.seam_integrity_pass = false
      expect(assessment.has_critical_failures?).to be true
    end

    it "returns false when all critical checks pass" do
      Assessments::StructureAssessment::CRITICAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      expect(assessment.has_critical_failures?).to be false
    end

    it "returns false when critical checks are nil" do
      expect(assessment.has_critical_failures?).to be false
    end
  end

  describe "#critical_failure_summary" do
    it "returns 'No critical failures' when all pass" do
      Assessments::StructureAssessment::CRITICAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
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
      assessment.unit_pressure = 1.5
      assessment.blower_tube_length = 1.5
      assessment.critical_fall_off_height = 0.5

      compliance = assessment.measurement_compliance

      expect(compliance).to have_key(:stitch_length)
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

    describe "unit_pressure_compliant?" do
      it "delegates to SafetyStandard" do
        assessment.unit_pressure = 1.5
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
        assessment.critical_fall_off_height = 0.5
        expect(SafetyStandard).to receive(:valid_fall_height?).with(0.5)
        assessment.send(:fall_off_height_compliant?)
      end
    end
  end

  describe "edge cases" do
    it "handles extreme measurement values" do
      assessment.update!(
        stitch_length: 999.99,
        unit_pressure: 999.99
      )

      expect(assessment).to be_valid
    end

    it "handles zero measurement values" do
      assessment.update!(
        stitch_length: 0,
        unit_pressure: 0
      )

      expect(assessment).to be_valid
    end

    it "handles mixed pass/fail states" do
      assessment.seam_integrity_pass = true
      assessment.uses_lock_stitching_pass = false
      assessment.air_loss_pass = true
      assessment.straight_walls_pass = false
      assessment.sharp_edges_pass = true
      assessment.unit_stable_pass = false

      expect(assessment.has_critical_failures?).to be true
      expect(assessment.passed_checks_count).to eq(3)
    end
  end
end