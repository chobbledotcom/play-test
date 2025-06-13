require "rails_helper"

RSpec.describe Assessments::FanAssessment, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:assessment) { inspection.fan_assessment }

  # Use shared examples for common behaviors
  it_behaves_like "an assessment model"
  it_behaves_like "has safety check methods"
  
  describe "constants" do
    describe "SAFETY_CHECKS" do
      it "contains all safety check field names" do
        expected_checks = %w[
          blower_serial_pass
          blower_flap_pass
          blower_finger_pass
          blower_visual_pass
          pat_pass
        ]

        expect(described_class::SAFETY_CHECKS).to eq(expected_checks)
      end

      it "is frozen to prevent modification" do
        expect(described_class::SAFETY_CHECKS).to be_frozen
      end
    end
  end

  describe "validations" do
    context "safety checks" do
      described_class::SAFETY_CHECKS.each do |field|
        include_examples "validates boolean field", field
      end
    end

    context "comment fields" do
      described_class::SAFETY_CHECKS.map { |check| check.sub("_pass", "_comment") }.push("fan_size_type").each do |field|
        include_examples "validates comment field", field
      end
    end
  end

  describe "#complete?" do
    context "when all safety checks are assessed and specifications present" do
      before do
        described_class::SAFETY_CHECKS.each do |check|
          assessment.send("#{check}=", true)
        end
        assessment.blower_serial = "BL123"
        assessment.fan_size_type = "2HP blower"
      end

      it "returns true" do
        expect(assessment.complete?).to be true
      end
    end

    context "when safety checks are missing" do
      before do
        assessment.blower_flap_pass = nil
        assessment.blower_serial = "BL123"
        assessment.fan_size_type = "2HP blower"
      end

      it "returns false" do
        expect(assessment.complete?).to be false
      end
    end

    context "when specifications are missing" do
      before do
        described_class::SAFETY_CHECKS.each do |check|
          assessment.send("#{check}=", true)
        end
        assessment.blower_serial = nil
      end

      it "returns false" do
        expect(assessment.complete?).to be false
      end
    end
  end

  describe "#has_critical_failures?" do
    context "when any safety check fails" do
      before do
        assessment.blower_flap_pass = false
        assessment.blower_finger_pass = true
        assessment.blower_visual_pass = true
        assessment.pat_pass = true
      end

      it "returns true" do
        expect(assessment.has_critical_failures?).to be true
      end
    end

    context "when all safety checks pass" do
      before do
        described_class::SAFETY_CHECKS.each do |check|
          assessment.send("#{check}=", true)
        end
      end

      it "returns false" do
        expect(assessment.has_critical_failures?).to be false
      end
    end

    context "when safety checks are nil" do
      before do
        described_class::SAFETY_CHECKS.each do |check|
          assessment.send("#{check}=", nil)
        end
      end

      it "returns false" do
        expect(assessment.has_critical_failures?).to be false
      end
    end
  end

  describe "#safety_issues_summary" do
    context "when there are no failures" do
      before do
        described_class::SAFETY_CHECKS.each do |check|
          assessment.send("#{check}=", true)
        end
      end

      it "returns no safety issues message" do
        expect(assessment.safety_issues_summary).to eq("No safety issues")
      end
    end

    context "when all checks are nil" do
      before do
        described_class::SAFETY_CHECKS.each do |check|
          assessment.send("#{check}=", nil)
        end
      end

      it "returns no safety issues message" do
        expect(assessment.safety_issues_summary).to eq("No safety issues")
      end
    end

    context "when there are multiple failures" do
      before do
        assessment.blower_flap_pass = false
        assessment.blower_finger_pass = true
        assessment.blower_visual_pass = false
        assessment.pat_pass = true
      end

      it "lists the failed checks" do
        result = assessment.safety_issues_summary
        expect(result).to start_with("Safety issues:")
        expect(result).to include("Blower flap pass")
        expect(result).to include("Blower visual pass")
        expect(result).not_to include("Blower finger pass")
        expect(result).not_to include("Pat pass")
      end
    end

    context "when there is one failure" do
      before do
        assessment.blower_flap_pass = false
        assessment.blower_finger_pass = true
        assessment.blower_visual_pass = true
        assessment.pat_pass = true
      end

      it "lists the single failed check" do
        expect(assessment.safety_issues_summary).to eq("Safety issues: Blower flap pass")
      end
    end
  end

  describe "fields" do
    it "stores basic fan assessment data" do
      assessment.update!(
        fan_size_type: "2HP centrifugal blower",
        blower_flap_pass: true,
        blower_flap_comment: "Flap operates correctly",
        blower_finger_pass: true,
        blower_finger_comment: "Finger guards secure",
        pat_pass: true,
        pat_comment: "PAT test passed",
        blower_visual_pass: true,
        blower_visual_comment: "Good visual condition",
        blower_serial: "BL789456")

      expect(assessment.fan_size_type).to eq("2HP centrifugal blower")
      expect(assessment.blower_serial).to eq("BL789456")
      expect(assessment.blower_flap_pass).to be true
      expect(assessment.pat_pass).to be true
    end
  end
end