require "rails_helper"

RSpec.describe EnclosedAssessment, type: :model do
  let(:inspection) { create(:inspection) }

  describe "associations" do
    it "belongs to inspection" do
      assessment = build(:enclosed_assessment, inspection: inspection)
      expect(assessment.inspection).to eq(inspection)
    end
  end

  describe "validations" do
    it "validates presence of inspection_id" do
      assessment = build(:enclosed_assessment, inspection_id: nil)
      expect(assessment).not_to be_valid
      expect(assessment.errors[:inspection_id]).to include("can't be blank")
    end

    it "validates uniqueness of inspection_id" do
      create(:enclosed_assessment, inspection: inspection)
      duplicate = build(:enclosed_assessment, inspection: inspection)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:inspection_id]).to include("has already been taken")
    end

    it "validates exit_number is positive when present" do
      assessment = build(:enclosed_assessment, inspection: inspection, exit_number: -1)
      expect(assessment).not_to be_valid
      expect(assessment.errors[:exit_number]).to include("must be greater than 0")
    end

    it "allows exit_number to be blank" do
      assessment = build(:enclosed_assessment, inspection: inspection, exit_number: nil)
      expect(assessment).to be_valid
    end
  end

  describe "factory" do
    it "creates valid enclosed assessment" do
      assessment = build(:enclosed_assessment, inspection: inspection)
      expect(assessment).to be_valid
    end

    it "creates valid passed assessment" do
      assessment = build(:enclosed_assessment, :passed, inspection: inspection)
      expect(assessment).to be_valid
      expect(assessment.exit_number_pass).to be true
      expect(assessment.exit_visible_pass).to be true
    end

    it "creates valid failed assessment" do
      assessment = build(:enclosed_assessment, :failed, inspection: inspection)
      expect(assessment).to be_valid
      expect(assessment.exit_number_pass).to be false
      expect(assessment.exit_visible_pass).to be false
    end
  end

  describe "#complete?" do
    it "returns true when all required fields are present" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number: 2,
        exit_number_pass: true,
        exit_visible_pass: true)
      expect(assessment.complete?).to be true
    end

    it "returns false when exit_number is missing" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number: nil,
        exit_number_pass: true,
        exit_visible_pass: true)
      expect(assessment.complete?).to be false
    end

    it "returns false when exit_number_pass is missing" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number: 2,
        exit_number_pass: nil,
        exit_visible_pass: true)
      expect(assessment.complete?).to be false
    end
  end

  describe "#completion_percentage" do
    it "returns 100 when all fields are complete" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number: 2,
        exit_number_pass: true,
        exit_visible_pass: true)
      expect(assessment.completion_percentage).to eq(100)
    end

    it "returns 67 when 2 of 3 fields are complete" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number: 2,
        exit_number_pass: true,
        exit_visible_pass: nil)
      expect(assessment.completion_percentage).to eq(67)
    end

    it "returns 0 when no fields are complete" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number: nil,
        exit_number_pass: nil,
        exit_visible_pass: nil)
      expect(assessment.completion_percentage).to eq(0)
    end
  end

  describe "#passed_checks_count" do
    it "counts passed checks" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number_pass: true,
        exit_visible_pass: true)
      expect(assessment.passed_checks_count).to eq(2)
    end

    it "counts only true values" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number_pass: true,
        exit_visible_pass: false)
      expect(assessment.passed_checks_count).to eq(1)
    end
  end

  describe "#has_critical_failures?" do
    it "returns false when all checks pass" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number_pass: true,
        exit_visible_pass: true)
      expect(assessment.has_critical_failures?).to be false
    end

    it "returns true when exit_number_pass fails" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number_pass: false,
        exit_visible_pass: true)
      expect(assessment.has_critical_failures?).to be true
    end

    it "returns true when exit_visible_pass fails" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number_pass: true,
        exit_visible_pass: false)
      expect(assessment.has_critical_failures?).to be true
    end
  end

  describe "#critical_failure_summary" do
    it "lists all critical failures" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number_pass: false,
        exit_visible_pass: false)
      expect(assessment.critical_failure_summary).to eq("Insufficient exits, Exits not clearly visible")
    end

    it "lists only failed items" do
      assessment = build(:enclosed_assessment,
        inspection: inspection,
        exit_number_pass: false,
        exit_visible_pass: true)
      expect(assessment.critical_failure_summary).to eq("Insufficient exits")
    end
  end
end
