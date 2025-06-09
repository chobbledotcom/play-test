require "rails_helper"

RSpec.describe MaterialsAssessment, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:assessment) { create(:materials_assessment, inspection: inspection) }

  describe "associations" do
    it "belongs to inspection" do
      expect(assessment.inspection).to eq(inspection)
    end
  end

  describe "constants" do
    it "defines material checks" do
      expect(MaterialsAssessment::MATERIAL_CHECKS).to eq([
        "rope_size_pass", "clamber_pass", "retention_netting_pass",
        "zips_pass", "windows_pass", "artwork_pass", "thread_pass",
        "fabric_pass", "fire_retardant_pass"
      ])
    end

    it "defines critical material checks" do
      expect(MaterialsAssessment::CRITICAL_MATERIAL_CHECKS).to eq([
        "fabric_pass", "fire_retardant_pass", "thread_pass"
      ])
    end
  end

  describe "validations" do
    context "rope size" do
      it "validates rope_size is non-negative" do
        assessment.rope_size = -1.0
        expect(assessment).not_to be_valid
        expect(assessment.errors[:rope_size]).to include("must be greater than or equal to 0")
      end

      it "allows blank rope_size" do
        assessment.rope_size = nil
        expect(assessment).to be_valid
      end
    end

    context "material checks" do
      MaterialsAssessment::MATERIAL_CHECKS.each do |check|
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
      MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.rope_size = 25.0
      expect(assessment.complete?).to be true
    end

    it "returns false when material assessments are incomplete" do
      MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.fabric_pass = nil
      assessment.rope_size = 25.0
      expect(assessment.complete?).to be false
    end

    it "returns false when rope specifications are missing" do
      MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.rope_size = nil
      expect(assessment.complete?).to be false
    end
  end

  describe "#has_critical_failures?" do
    it "returns true when any critical material check fails" do
      assessment.fabric_pass = false
      assessment.fire_retardant_pass = true
      assessment.thread_pass = true
      expect(assessment.has_critical_failures?).to be true
    end

    it "returns false when all critical checks pass" do
      assessment.fabric_pass = true
      assessment.fire_retardant_pass = true
      assessment.thread_pass = true
      expect(assessment.has_critical_failures?).to be false
    end

    it "returns false when critical checks are nil" do
      assessment.fabric_pass = nil
      assessment.fire_retardant_pass = nil
      assessment.thread_pass = nil
      expect(assessment.has_critical_failures?).to be false
    end
  end

  describe "#safety_check_count" do
    it "returns the number of material checks" do
      expect(assessment.safety_check_count).to eq(MaterialsAssessment::MATERIAL_CHECKS.length)
    end
  end

  describe "#passed_checks_count" do
    it "counts all passed material checks" do
      assessment.rope_size_pass = true
      assessment.clamber_pass = false
      assessment.fabric_pass = true
      assessment.fire_retardant_pass = true
      assessment.thread_pass = false

      expect(assessment.passed_checks_count).to eq(3)
    end

    it "returns 0 when no checks are passed" do
      MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", false) }
      expect(assessment.passed_checks_count).to eq(0)
    end

    it "handles nil values" do
      assessment.rope_size_pass = true
      assessment.clamber_pass = nil
      assessment.fabric_pass = true
      expect(assessment.passed_checks_count).to eq(2)
    end
  end

  describe "#completion_percentage" do
    it "calculates percentage including rope_size" do
      MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.rope_size = 25.0
      expect(assessment.completion_percentage).to eq(100)
    end

    it "returns 0 when no fields are completed" do
      expect(assessment.completion_percentage).to eq(0)
    end

    it "calculates partial completion correctly" do
      assessment.rope_size_pass = true
      assessment.fabric_pass = true
      assessment.rope_size = 25.0
      # 3 out of 10 fields = 30%
      expect(assessment.completion_percentage).to eq(30)
    end
  end

  describe "#material_compliance_summary" do
    it "returns comprehensive compliance data" do
      assessment.fabric_pass = true
      assessment.fire_retardant_pass = false
      assessment.thread_pass = true
      assessment.rope_size_pass = true
      assessment.clamber_pass = true
      assessment.rope_size = 25.0

      allow(assessment).to receive(:rope_size_compliant?).and_return(true)

      summary = assessment.material_compliance_summary

      expect(summary[:critical_passed]).to eq(2)
      expect(summary[:critical_total]).to eq(3)
      expect(summary[:overall_passed]).to eq(4)
      expect(summary[:overall_total]).to eq(9)
      expect(summary[:rope_compliant]).to be true
    end
  end

  describe "#critical_material_status" do
    it "returns success message when all critical materials pass" do
      assessment.fabric_pass = true
      assessment.fire_retardant_pass = true
      assessment.thread_pass = true

      expect(assessment.critical_material_status).to eq("All critical materials compliant")
    end

    it "lists failed critical materials" do
      assessment.fabric_pass = false
      assessment.fire_retardant_pass = false
      assessment.thread_pass = true

      status = assessment.critical_material_status
      expect(status).to include("Critical failures:")
      expect(status).to include("Fabric pass")
      expect(status).to include("Fire retardant pass")
    end
  end

  describe "#material_test_requirements" do
    it "returns empty array when all materials pass" do
      assessment.fabric_pass = true
      assessment.fire_retardant_pass = true
      assessment.thread_pass = true
      assessment.rope_size = 25.0
      allow(assessment).to receive(:rope_size_compliant?).and_return(true)

      expect(assessment.material_test_requirements).to be_empty
    end

    it "lists requirements for failed materials" do
      assessment.fabric_pass = false
      assessment.fire_retardant_pass = false
      assessment.thread_pass = false
      assessment.rope_size = 10.0
      allow(assessment).to receive(:rope_size_compliant?).and_return(false)

      requirements = assessment.material_test_requirements
      expect(requirements).to include("Fabric tensile strength: 1850N minimum")
      expect(requirements).to include("Fabric tear strength: 350N minimum")
      expect(requirements).to include("Fire retardancy: EN 71-3 compliance")
      expect(requirements).to include("Thread tensile strength: 88N minimum")
      expect(requirements).to include("Rope diameter: 18-45mm range")
    end
  end

  describe "#non_critical_issues" do
    it "returns empty array when all non-critical checks pass" do
      assessment.rope_size_pass = true
      assessment.clamber_pass = true
      assessment.retention_netting_pass = true
      assessment.zips_pass = true
      assessment.windows_pass = true
      assessment.artwork_pass = true

      expect(assessment.non_critical_issues).to be_empty
    end

    it "lists failed non-critical checks" do
      assessment.rope_size_pass = false
      assessment.clamber_pass = false
      assessment.retention_netting_pass = true

      issues = assessment.non_critical_issues
      expect(issues).to include("Rope size pass")
      expect(issues).to include("Clamber pass")
      expect(issues).not_to include("Retention netting pass")
    end
  end

  describe "private methods" do
    describe "#material_assessments_complete?" do
      it "returns true when all material checks are present" do
        MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
        expect(assessment.send(:material_assessments_complete?)).to be true
      end

      it "returns false when any material check is nil" do
        MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
        assessment.fabric_pass = nil
        expect(assessment.send(:material_assessments_complete?)).to be false
      end
    end

    describe "#rope_specifications_present?" do
      it "returns true when rope_size is present" do
        assessment.rope_size = 25.0
        expect(assessment.send(:rope_specifications_present?)).to be true
      end

      it "returns false when rope_size is nil" do
        assessment.rope_size = nil
        expect(assessment.send(:rope_specifications_present?)).to be false
      end
    end

    describe "#rope_size_compliant?" do
      it "delegates to SafetyStandard" do
        assessment.rope_size = 25.0
        expect(SafetyStandard).to receive(:valid_rope_diameter?).with(25.0)
        assessment.send(:rope_size_compliant?)
      end
    end
  end

  describe "audit logging" do
    it "logs assessment updates" do
      expect(assessment).to receive(:log_assessment_update)
      assessment.update!(rope_size: 25.0)
    end

    it "does not log when no changes are made" do
      assessment.update!(rope_size: 25.0)
      expect(assessment).not_to receive(:log_assessment_update)
      assessment.save
    end
  end

  describe "edge cases" do
    it "handles zero rope size" do
      assessment.rope_size = 0
      expect(assessment).to be_valid
    end

    it "handles very large rope size" do
      assessment.rope_size = 999.99
      expect(assessment).to be_valid
    end

    it "handles all materials failing" do
      MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", false) }
      expect(assessment.passed_checks_count).to eq(0)
      expect(assessment.has_critical_failures?).to be true
    end

    it "handles mixed critical and non-critical failures" do
      assessment.fabric_pass = false  # critical
      assessment.fire_retardant_pass = true  # critical
      assessment.thread_pass = true  # critical
      assessment.rope_size_pass = false  # non-critical
      assessment.clamber_pass = false  # non-critical

      expect(assessment.has_critical_failures?).to be true
      expect(assessment.non_critical_issues).to include("Rope size pass", "Clamber pass")
    end

    it "handles decimal rope sizes" do
      assessment.rope_size = 22.5
      expect(assessment).to be_valid
    end
  end
end
