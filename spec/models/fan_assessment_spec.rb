require "rails_helper"

RSpec.describe FanAssessment, type: :model do
  let(:inspection) { create(:inspection) }

  describe "associations" do
    it "belongs to inspection" do
      assessment = build(:fan_assessment, inspection: inspection)
      expect(assessment.inspection).to eq(inspection)
    end
  end

  describe "validations" do
    it "validates presence of inspection_id" do
      assessment = build(:fan_assessment, inspection_id: nil)
      expect(assessment).not_to be_valid
      expect(assessment.errors[:inspection_id]).to include("can't be blank")
    end

    it "validates uniqueness of inspection_id" do
      create(:fan_assessment, inspection: inspection)
      duplicate = build(:fan_assessment, inspection: inspection)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:inspection_id]).to include("has already been taken")
    end
  end

  describe "factory" do
    it "creates valid fan assessment" do
      assessment = build(:fan_assessment, inspection: inspection)
      expect(assessment).to be_valid
    end

    it "creates valid passed assessment" do
      assessment = build(:fan_assessment, :passed, inspection: inspection)
      expect(assessment).to be_valid
      expect(assessment.blower_flap_pass).to be true
      expect(assessment.blower_finger_pass).to be true
      expect(assessment.pat_pass).to be true
      expect(assessment.blower_visual_pass).to be true
    end

    it "creates valid failed assessment" do
      assessment = build(:fan_assessment, :failed, inspection: inspection)
      expect(assessment).to be_valid
      expect(assessment.blower_flap_pass).to be false
      expect(assessment.blower_finger_pass).to be false
      expect(assessment.pat_pass).to be false
      expect(assessment.blower_visual_pass).to be false
    end
  end

  describe "fields" do
    it "stores basic fan assessment data" do
      assessment = create(:fan_assessment, inspection: inspection,
        fan_size_comment: "2HP centrifugal blower",
        blower_flap_pass: true,
        blower_flap_comment: "Flap operates correctly",
        blower_finger_pass: true,
        blower_finger_comment: "Finger guards secure",
        pat_pass: true,
        pat_comment: "PAT test passed",
        blower_visual_pass: true,
        blower_visual_comment: "Good visual condition",
        blower_serial: "BL789456")

      expect(assessment.fan_size_comment).to eq("2HP centrifugal blower")
      expect(assessment.blower_serial).to eq("BL789456")
      expect(assessment.blower_flap_pass).to be true
      expect(assessment.pat_pass).to be true
    end
  end

  describe "constants" do
    describe "SAFETY_CHECKS" do
      it "contains all safety check field names" do
        expected_checks = %w[
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

  describe "safety check validations" do
    let(:assessment) { build(:fan_assessment, inspection: inspection) }

    described_class::SAFETY_CHECKS.each do |check|
      it "validates #{check} accepts true/false/nil values" do
        # Valid values
        assessment.send("#{check}=", true)
        expect(assessment).to be_valid

        assessment.send("#{check}=", false)
        expect(assessment).to be_valid

        assessment.send("#{check}=", nil)
        expect(assessment).to be_valid
      end
    end
  end

  describe "#complete?" do
    let(:assessment) { build(:fan_assessment, inspection: inspection) }

    context "when all safety checks are assessed and specifications present" do
      before do
        described_class::SAFETY_CHECKS.each do |check|
          assessment.send("#{check}=", true)
        end
        assessment.blower_serial = "BL123"
        assessment.fan_size_comment = "2HP blower"
      end

      it "returns true" do
        expect(assessment.complete?).to be true
      end
    end

    context "when safety checks are missing" do
      before do
        assessment.blower_flap_pass = nil
        assessment.blower_serial = "BL123"
        assessment.fan_size_comment = "2HP blower"
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
    let(:assessment) { build(:fan_assessment, inspection: inspection) }

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

  describe "#safety_check_count" do
    it "returns the number of safety checks" do
      assessment = build(:fan_assessment, inspection: inspection)
      expect(assessment.safety_check_count).to eq(4)
    end
  end

  describe "#passed_checks_count" do
    let(:assessment) { build(:fan_assessment, inspection: inspection) }

    context "when some checks pass" do
      before do
        assessment.blower_flap_pass = true
        assessment.blower_finger_pass = false
        assessment.blower_visual_pass = true
        assessment.pat_pass = nil
      end

      it "counts only the passing checks" do
        expect(assessment.passed_checks_count).to eq(2)
      end
    end

    context "when all checks pass" do
      before do
        described_class::SAFETY_CHECKS.each do |check|
          assessment.send("#{check}=", true)
        end
      end

      it "returns total count" do
        expect(assessment.passed_checks_count).to eq(4)
      end
    end

    context "when no checks pass" do
      before do
        described_class::SAFETY_CHECKS.each do |check|
          assessment.send("#{check}=", false)
        end
      end

      it "returns zero" do
        expect(assessment.passed_checks_count).to eq(0)
      end
    end
  end

  describe "#completion_percentage" do
    let(:assessment) { build(:fan_assessment, inspection: inspection) }

    context "when all fields are complete" do
      before do
        described_class::SAFETY_CHECKS.each do |check|
          assessment.send("#{check}=", true)
        end
        assessment.blower_serial = "BL123"
        assessment.fan_size_comment = "2HP blower"
      end

      it "returns 100%" do
        expect(assessment.completion_percentage).to eq(100)
      end
    end

    context "when half the fields are complete" do
      before do
        assessment.blower_flap_pass = true
        assessment.blower_finger_pass = true
        assessment.blower_visual_pass = nil
        assessment.pat_pass = nil
        assessment.blower_serial = "BL123"
        assessment.fan_size_comment = nil
      end

      it "returns 50%" do
        expect(assessment.completion_percentage).to eq(50)
      end
    end

    context "when no fields are complete" do
      before do
        described_class::SAFETY_CHECKS.each do |check|
          assessment.send("#{check}=", nil)
        end
        assessment.blower_serial = nil
        assessment.fan_size_comment = nil
      end

      it "returns 0%" do
        expect(assessment.completion_percentage).to eq(0)
      end
    end
  end

  describe "#safety_issues_summary" do
    let(:assessment) { build(:fan_assessment, inspection: inspection) }

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
end
