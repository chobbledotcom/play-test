require "rails_helper"

RSpec.describe Assessments::SlideAssessment, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:assessment) { inspection.slide_assessment }

  # Use shared examples for common behaviors
  it_behaves_like "an assessment model"
  it_behaves_like "has safety check methods"
  it_behaves_like "delegates to SafetyStandard", [:calculate_required_runout, :meets_runout_requirements?]

  describe "validations" do
    context "slide measurements" do
      %w[slide_platform_height slide_wall_height runout
        slide_first_metre_height slide_beyond_first_metre_height].each do |field|
        include_examples "validates non-negative numeric field", field
      end
    end

    context "pass/fail assessments" do
      %w[clamber_netting_pass runout_pass slip_sheet_pass].each do |field|
        include_examples "validates boolean field", field
      end
    end

    context "comment fields" do
      %w[slide_platform_height_comment slide_wall_height_comment runout_comment
        clamber_netting_comment runout_comment slip_sheet_comment].each do |field|
        include_examples "validates comment field", field
      end
    end
  end

  describe "#complete?" do
    it "returns true when all requirements are met" do
      assessment.update!(
        slide_platform_height: 2.0,
        slide_wall_height: 1.5,
        runout: 3.0,
        clamber_netting_pass: true,
        runout_pass: true,
        slip_sheet_pass: true
      )
      expect(assessment.complete?).to be true
    end

    it "returns false when slide measurements are missing" do
      assessment.update!(
        slide_platform_height: nil,
        slide_wall_height: 1.5,
        runout: 3.0,
        clamber_netting_pass: true,
        runout_pass: true,
        slip_sheet_pass: true
      )
      expect(assessment.complete?).to be false
    end

    it "returns false when safety assessments are incomplete" do
      assessment.update!(
        slide_platform_height: 2.0,
        slide_wall_height: 1.5,
        runout: 3.0,
        clamber_netting_pass: true,
        runout_pass: nil,
        slip_sheet_pass: true
      )
      expect(assessment.complete?).to be false
    end
  end

  describe "#meets_runout_requirements?" do
    context "with valid data" do
      it "delegates to SafetyStandard" do
        assessment.runout = 4.0
        assessment.slide_platform_height = 2.0

        expect(SafetyStandard).to receive(:meets_runout_requirements?).with(4.0, 2.0).and_return(true)
        expect(assessment.meets_runout_requirements?).to be true
      end
    end

    context "with missing data" do
      it "returns false when runout is missing" do
        assessment.runout = nil
        assessment.slide_platform_height = 2.0
        expect(assessment.meets_runout_requirements?).to be false
      end

      it "returns false when slide_platform_height is missing" do
        assessment.runout = 4.0
        assessment.slide_platform_height = nil
        expect(assessment.meets_runout_requirements?).to be false
      end
    end
  end

  describe "#required_runout_length" do
    it "delegates to SafetyStandard when platform height is present" do
      assessment.slide_platform_height = 2.0
      expect(SafetyStandard).to receive(:calculate_required_runout).with(2.0).and_return(4.0)
      expect(assessment.required_runout_length).to eq(4.0)
    end

    it "returns nil when platform height is missing" do
      assessment.slide_platform_height = nil
      expect(assessment.required_runout_length).to be_nil
    end
  end

  describe "#runout_compliance_status" do
    it "returns 'Not Assessed' when runout is missing" do
      assessment.runout = nil
      expect(assessment.runout_compliance_status).to eq("Not Assessed")
    end

    it "returns 'Compliant' when requirements are met" do
      assessment.runout = 4.0
      assessment.slide_platform_height = 2.0
      allow(assessment).to receive(:meets_runout_requirements?).and_return(true)
      expect(assessment.runout_compliance_status).to eq("Compliant")
    end

    it "returns detailed non-compliance message when requirements not met" do
      assessment.runout = 2.0
      assessment.slide_platform_height = 2.0
      allow(assessment).to receive(:meets_runout_requirements?).and_return(false)
      allow(assessment).to receive(:required_runout_length).and_return(4.0)
      expect(assessment.runout_compliance_status).to eq("Non-Compliant (Requires 4.0m minimum)")
    end
  end

  describe "private methods" do
    describe "#slide_measurements_present?" do
      it "returns true when all measurements are present" do
        assessment.update!(
          slide_platform_height: 2.0,
          slide_wall_height: 1.5,
          runout: 3.0
        )
        expect(assessment.send(:slide_measurements_present?)).to be true
      end

      it "returns false when any measurement is missing" do
        assessment.update!(
          slide_platform_height: 2.0,
          slide_wall_height: nil,
          runout: 3.0
        )
        expect(assessment.send(:slide_measurements_present?)).to be false
      end
    end

    describe "#safety_assessments_complete?" do
      it "returns true when all safety checks are present" do
        assessment.update!(
          clamber_netting_pass: true,
          runout_pass: false,
          slip_sheet_pass: true
        )
        expect(assessment.send(:safety_assessments_complete?)).to be true
      end

      it "returns false when any safety check is nil" do
        assessment.update!(
          clamber_netting_pass: true,
          runout_pass: nil,
          slip_sheet_pass: true
        )
        expect(assessment.send(:safety_assessments_complete?)).to be false
      end
    end
  end

  describe "edge cases" do
    it "handles zero measurements" do
      assessment.update!(
        slide_platform_height: 0,
        slide_wall_height: 0,
        runout: 0
      )
      expect(assessment).to be_valid
    end

    it "handles very large measurements" do
      assessment.update!(
        slide_platform_height: 999.99,
        slide_wall_height: 999.99,
        runout: 999.99
      )
      expect(assessment).to be_valid
    end

    it "handles decimal precision correctly" do
      assessment.update!(
        slide_platform_height: 2.123456,
        runout: 4.987654
      )
      expect(assessment).to be_valid
    end

    it "handles mixed pass/fail states" do
      assessment.update!(
        clamber_netting_pass: true,
        runout_pass: false,
        slip_sheet_pass: true
      )
      expect(assessment.passed_checks_count).to eq(2)
      expect(assessment.pass_columns_count).to eq(3)
    end
  end
end
