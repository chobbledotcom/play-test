require "rails_helper"

RSpec.describe SlideAssessment, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:assessment) { create(:slide_assessment, inspection: inspection) }

  describe "associations" do
    it "belongs to inspection" do
      expect(assessment.inspection).to eq(inspection)
    end
  end

  describe "validations" do
    context "slide measurements" do
      %w[slide_platform_height slide_wall_height runout_value
        slide_first_metre_height slide_beyond_first_metre_height].each do |measurement|
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

    context "pass/fail assessments" do
      %w[clamber_netting_pass runout_pass slip_sheet_pass].each do |check|
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
  end

  describe "#complete?" do
    it "returns true when all requirements are met" do
      assessment.update!(
        slide_platform_height: 2.0,
        slide_wall_height: 1.5,
        runout_value: 3.0,
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
        runout_value: 3.0,
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
        runout_value: 3.0,
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
        assessment.runout_value = 4.0
        assessment.slide_platform_height = 2.0

        expect(SafetyStandard).to receive(:meets_runout_requirements?).with(4.0, 2.0).and_return(true)
        expect(assessment.meets_runout_requirements?).to be true
      end
    end

    context "with missing data" do
      it "returns false when runout_value is missing" do
        assessment.runout_value = nil
        assessment.slide_platform_height = 2.0
        expect(assessment.meets_runout_requirements?).to be false
      end

      it "returns false when slide_platform_height is missing" do
        assessment.runout_value = 4.0
        assessment.slide_platform_height = nil
        expect(assessment.meets_runout_requirements?).to be false
      end
    end
  end

  describe "#safety_check_count" do
    it "returns 3 safety checks" do
      expect(assessment.safety_check_count).to eq(3)
    end
  end

  describe "#passed_checks_count" do
    it "counts all passed safety checks" do
      assessment.update!(
        clamber_netting_pass: true,
        runout_pass: false,
        slip_sheet_pass: true
      )
      expect(assessment.passed_checks_count).to eq(2)
    end

    it "returns 0 when no checks are passed" do
      assessment.update!(
        clamber_netting_pass: false,
        runout_pass: false,
        slip_sheet_pass: false
      )
      expect(assessment.passed_checks_count).to eq(0)
    end

    it "handles nil values" do
      assessment.update!(
        clamber_netting_pass: true,
        runout_pass: nil,
        slip_sheet_pass: false
      )
      expect(assessment.passed_checks_count).to eq(1)
    end
  end

  describe "#completion_percentage" do
    it "calculates percentage of completed fields" do
      assessment.update!(
        slide_platform_height: 2.0,
        slide_wall_height: 1.5,
        runout_value: 3.0,
        slide_first_metre_height: 1.0,
        slide_beyond_first_metre_height: 0.8,
        clamber_netting_pass: true,
        runout_pass: true,
        slip_sheet_pass: true,
        slide_permanent_roof: false,
        slide_platform_height_comment: "Good condition"
      )
      expect(assessment.completion_percentage).to eq(100)
    end

    it "returns 0 when no fields are completed" do
      expect(assessment.completion_percentage).to eq(0)
    end

    it "calculates partial completion correctly" do
      assessment.update!(
        slide_platform_height: 2.0,
        slide_wall_height: 1.5,
        runout_value: 3.0,
        clamber_netting_pass: true,
        runout_pass: true
        # 5 out of 10 fields = 50%
      )
      expect(assessment.completion_percentage).to eq(50)
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
    it "returns 'Not Assessed' when runout_value is missing" do
      assessment.runout_value = nil
      expect(assessment.runout_compliance_status).to eq("Not Assessed")
    end

    it "returns 'Compliant' when requirements are met" do
      assessment.runout_value = 4.0
      assessment.slide_platform_height = 2.0
      allow(assessment).to receive(:meets_runout_requirements?).and_return(true)
      expect(assessment.runout_compliance_status).to eq("Compliant")
    end

    it "returns detailed non-compliance message when requirements not met" do
      assessment.runout_value = 2.0
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
          runout_value: 3.0
        )
        expect(assessment.send(:slide_measurements_present?)).to be true
      end

      it "returns false when any measurement is missing" do
        assessment.update!(
          slide_platform_height: 2.0,
          slide_wall_height: nil,
          runout_value: 3.0
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

  describe "audit logging" do
    it "logs assessment updates" do
      expect(assessment).to receive(:log_assessment_update)
      assessment.update!(slide_platform_height: 2.0)
    end

    it "does not log when no changes are made" do
      assessment.update!(slide_platform_height: 2.0)
      expect(assessment).not_to receive(:log_assessment_update)
      assessment.save
    end
  end

  describe "edge cases" do
    it "handles zero measurements" do
      assessment.update!(
        slide_platform_height: 0,
        slide_wall_height: 0,
        runout_value: 0
      )
      expect(assessment).to be_valid
    end

    it "handles very large measurements" do
      assessment.update!(
        slide_platform_height: 999.99,
        slide_wall_height: 999.99,
        runout_value: 999.99
      )
      expect(assessment).to be_valid
    end

    it "handles decimal precision correctly" do
      assessment.update!(
        slide_platform_height: 2.123456,
        runout_value: 4.987654
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
      expect(assessment.safety_check_count).to eq(3)
    end
  end
end
