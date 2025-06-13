require "rails_helper"

RSpec.describe Assessments::EnclosedAssessment, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:assessment) { inspection.enclosed_assessment }

  # Use shared examples for common behaviors
  it_behaves_like "an assessment model"
  it_behaves_like "has safety check methods", 3
  
  describe "validations" do
    context "exit number" do
      it "validates exit_number is positive when present" do
        assessment.exit_number = -1
        expect(assessment).not_to be_valid
        expect(assessment.errors[:exit_number]).to include("must be greater than 0")
      end

      it "allows exit_number to be blank" do
        assessment.exit_number = nil
        expect(assessment).to be_valid
      end
    end

    context "pass/fail assessments" do
      %w[exit_number_pass exit_sign_always_visible_pass exit_sign_visible_pass].each do |field|
        include_examples "validates boolean field", field
      end
    end

    context "comment fields" do
      %w[exit_number_comment exit_sign_always_visible_comment exit_sign_visible_comment].each do |field|
        include_examples "validates comment field", field
      end
    end
  end

  describe "#complete?" do
    it "returns true when all required fields are present" do
      assessment.assign_attributes(
        exit_number: 2,
        exit_number_pass: true,
        exit_sign_always_visible_pass: true,
        exit_sign_visible_pass: true)
      expect(assessment.complete?).to be true
    end

    it "returns false when exit_number is missing" do
      assessment.assign_attributes(
        exit_number: nil,
        exit_number_pass: true,
        exit_sign_always_visible_pass: true)
      expect(assessment.complete?).to be false
    end

    it "returns false when exit_number_pass is missing" do
      assessment.assign_attributes(
        exit_number: 2,
        exit_number_pass: nil,
        exit_sign_always_visible_pass: true,
        exit_sign_visible_pass: true)
      expect(assessment.complete?).to be false
    end

    it "returns false when exit_sign_visible_pass is missing" do
      assessment.assign_attributes(
        exit_number: 2,
        exit_number_pass: true,
        exit_sign_always_visible_pass: true,
        exit_sign_visible_pass: nil)
      expect(assessment.complete?).to be false
    end
  end

  describe "#has_critical_failures?" do
    it "returns false when all checks pass" do
      assessment.assign_attributes(
        exit_number_pass: true,
        exit_sign_always_visible_pass: true,
        exit_sign_visible_pass: true)
      expect(assessment.has_critical_failures?).to be false
    end

    it "returns true when exit_number_pass fails" do
      assessment.assign_attributes(
        exit_number_pass: false,
        exit_sign_always_visible_pass: true,
        exit_sign_visible_pass: true)
      expect(assessment.has_critical_failures?).to be true
    end

    it "returns true when exit_sign_always_visible_pass fails" do
      assessment.assign_attributes(
        exit_number_pass: true,
        exit_sign_always_visible_pass: false,
        exit_sign_visible_pass: true)
      expect(assessment.has_critical_failures?).to be true
    end

    it "returns true when exit_sign_visible_pass fails" do
      assessment.assign_attributes(
        exit_number_pass: true,
        exit_sign_always_visible_pass: true,
        exit_sign_visible_pass: false)
      expect(assessment.has_critical_failures?).to be true
    end
  end

  describe "#critical_failure_summary" do
    it "lists all critical failures" do
      assessment.assign_attributes(
        exit_number_pass: false,
        exit_sign_always_visible_pass: false,
        exit_sign_visible_pass: false)
      expect(assessment.critical_failure_summary).to eq("Insufficient exits, Exits not clearly visible, Exit signs not visible")
    end

    it "lists only failed items" do
      assessment.assign_attributes(
        exit_number_pass: false,
        exit_sign_always_visible_pass: true,
        exit_sign_visible_pass: true)
      expect(assessment.critical_failure_summary).to eq("Insufficient exits")
    end
  end

  describe "factory traits" do
    it "creates valid passed assessment" do
      # Apply passed trait attributes
      assessment.assign_attributes(attributes_for(:enclosed_assessment, :passed).except(:inspection_id))
      expect(assessment).to be_valid
      expect(assessment.exit_number_pass).to be true
      expect(assessment.exit_sign_always_visible_pass).to be true
    end

    it "creates valid failed assessment" do
      # Apply failed trait attributes
      assessment.assign_attributes(attributes_for(:enclosed_assessment, :failed).except(:inspection_id))
      expect(assessment).to be_valid
      expect(assessment.exit_number_pass).to be false
      expect(assessment.exit_sign_always_visible_pass).to be false
    end
  end
end