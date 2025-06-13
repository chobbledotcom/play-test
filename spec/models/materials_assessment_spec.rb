require "rails_helper"

RSpec.describe Assessments::MaterialsAssessment, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:assessment) { inspection.materials_assessment }

  # Use shared examples for common behaviors
  it_behaves_like "an assessment model"
  it_behaves_like "has safety check methods", 9  # 9 _pass columns in materials assessment
  it_behaves_like "delegates to SafetyStandard", [:valid_rope_diameter?]

  describe "constants" do
    it "defines material checks in alphabetical order" do
      expect(Assessments::MaterialsAssessment::MATERIAL_CHECKS).to eq([
        "artwork_pass", "clamber_netting_pass", "fabric_strength_pass",
        "fire_retardant_pass", "retention_netting_pass", "ropes_pass",
        "thread_pass", "windows_pass", "zips_pass"
      ])
    end

    it "defines critical material checks" do
      expect(Assessments::MaterialsAssessment::CRITICAL_MATERIAL_CHECKS).to eq([
        "fabric_strength_pass", "fire_retardant_pass", "thread_pass"
      ])
    end
  end

  describe "validations" do
    context "rope size" do
      include_examples "validates non-negative numeric field", "ropes"
    end

    context "material checks" do
      Assessments::MaterialsAssessment::MATERIAL_CHECKS.each do |field|
        include_examples "validates boolean field", field
      end
    end

    context "comment fields" do
      Assessments::MaterialsAssessment::MATERIAL_CHECKS.map { |check| check.sub("_pass", "_comment") }.each do |field|
        include_examples "validates comment field", field
      end
      include_examples "validates comment field", "ropes_comment"
    end
  end

  describe "#complete?" do
    it "returns true when all requirements are met" do
      Assessments::MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.ropes = 25.0
      expect(assessment.complete?).to be true
    end

    it "returns false when material assessments are incomplete" do
      Assessments::MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.fabric_strength_pass = nil
      assessment.ropes = 25.0
      expect(assessment.complete?).to be false
    end

    it "returns false when rope specifications are missing" do
      Assessments::MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
      assessment.ropes = nil
      expect(assessment.complete?).to be false
    end
  end

  describe "#has_critical_failures?" do
    it "returns true when any critical material check fails" do
      assessment.fabric_strength_pass = false
      assessment.fire_retardant_pass = true
      assessment.thread_pass = true
      expect(assessment.has_critical_failures?).to be true
    end

    it "returns false when all critical checks pass" do
      assessment.fabric_strength_pass = true
      assessment.fire_retardant_pass = true
      assessment.thread_pass = true
      expect(assessment.has_critical_failures?).to be false
    end

    it "returns false when critical checks are nil" do
      assessment.fabric_strength_pass = nil
      assessment.fire_retardant_pass = nil
      assessment.thread_pass = nil
      expect(assessment.has_critical_failures?).to be false
    end
  end

  describe "#material_compliance_summary" do
    it "returns comprehensive compliance data" do
      assessment.fabric_strength_pass = true
      assessment.fire_retardant_pass = false
      assessment.thread_pass = true
      assessment.ropes_pass = true
      assessment.clamber_netting_pass = true
      assessment.ropes = 25.0

      allow(assessment).to receive(:ropes_compliant?).and_return(true)

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
      assessment.fabric_strength_pass = true
      assessment.fire_retardant_pass = true
      assessment.thread_pass = true

      expect(assessment.critical_material_status).to eq("All critical materials compliant")
    end

    it "lists failed critical materials" do
      assessment.fabric_strength_pass = false
      assessment.fire_retardant_pass = false
      assessment.thread_pass = true

      status = assessment.critical_material_status
      expect(status).to include("Critical failures:")
      expect(status).to include("Fabric strength pass")
      expect(status).to include("Fire retardant pass")
    end
  end

  describe "#material_test_requirements" do
    it "returns empty array when all materials pass" do
      assessment.fabric_strength_pass = true
      assessment.fire_retardant_pass = true
      assessment.thread_pass = true
      assessment.ropes = 25.0
      allow(assessment).to receive(:ropes_compliant?).and_return(true)

      expect(assessment.material_test_requirements).to be_empty
    end

    it "lists requirements for failed materials" do
      assessment.fabric_strength_pass = false
      assessment.fire_retardant_pass = false
      assessment.thread_pass = false
      assessment.ropes = 10.0
      allow(assessment).to receive(:ropes_compliant?).and_return(false)

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
      assessment.ropes_pass = true
      assessment.clamber_netting_pass = true
      assessment.retention_netting_pass = true
      assessment.zips_pass = true
      assessment.windows_pass = true
      assessment.artwork_pass = true

      expect(assessment.non_critical_issues).to be_empty
    end

    it "lists failed non-critical checks" do
      assessment.ropes_pass = false
      assessment.clamber_netting_pass = false
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
        Assessments::MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
        expect(assessment.send(:material_assessments_complete?)).to be true
      end

      it "returns false when any material check is nil" do
        Assessments::MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", true) }
        assessment.fabric_strength_pass = nil
        expect(assessment.send(:material_assessments_complete?)).to be false
      end
    end

    describe "#rope_specifications_present?" do
      it "returns true when ropes is present" do
        assessment.ropes = 25.0
        expect(assessment.send(:rope_specifications_present?)).to be true
      end

      it "returns false when ropes is nil" do
        assessment.ropes = nil
        expect(assessment.send(:rope_specifications_present?)).to be false
      end
    end

    describe "#ropes_compliant?" do
      it "delegates to SafetyStandard" do
        assessment.ropes = 25.0
        expect(SafetyStandard).to receive(:valid_rope_diameter?).with(25.0)
        assessment.send(:ropes_compliant?)
      end
    end
  end

  describe "edge cases" do
    it "handles zero rope size" do
      assessment.ropes = 0
      expect(assessment).to be_valid
    end

    it "handles very large rope size" do
      assessment.ropes = 999.99
      expect(assessment).to be_valid
    end

    it "handles all materials failing" do
      Assessments::MaterialsAssessment::MATERIAL_CHECKS.each { |check| assessment.send("#{check}=", false) }
      expect(assessment.passed_checks_count).to eq(0)
      expect(assessment.has_critical_failures?).to be true
    end

    it "handles mixed critical and non-critical failures" do
      assessment.fabric_strength_pass = false  # critical
      assessment.fire_retardant_pass = true  # critical
      assessment.thread_pass = true  # critical
      assessment.ropes_pass = false  # non-critical
      assessment.clamber_netting_pass = false  # non-critical

      expect(assessment.has_critical_failures?).to be true
      expect(assessment.non_critical_issues).to include("Rope size pass", "Clamber pass")
    end

    it "handles decimal rope sizes" do
      assessment.ropes = 22.5
      expect(assessment).to be_valid
    end
  end
end