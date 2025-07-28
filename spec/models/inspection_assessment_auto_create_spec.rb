require "rails_helper"

RSpec.describe "Inspection assessment auto-creation", type: :model do
  let(:inspection) { create(:inspection) }

  describe "auto-creation behavior" do
    it "creates assessment when accessed directly" do
      materials = inspection.materials_assessment
      expect(materials).to be_a(Assessments::MaterialsAssessment)
      expect(inspection.materials_assessment).to be_persisted
    end

    it "creates all assessment types on direct access" do
      inspection.assessment_types.each do |assessment_name, assessment_class|
        assessment = inspection.send(assessment_name)
        expect(assessment).to be_a(assessment_class)
        expect(assessment).to be_persisted
      end
    end
  end

  describe "safe navigation with ? methods" do
    it "does not create assessment when using ? method" do
      expect { inspection.materials_assessment? }.not_to change {
        Assessments::MaterialsAssessment.count
      }
    end

    it "returns nil for non-existent assessment with ? method" do
      expect(inspection.materials_assessment?).to be_nil
    end

    it "returns existing assessment with ? method" do
      # Create the assessment first
      assessment = inspection.materials_assessment

      # Now the ? method should return it without creating a new one
      expect(inspection.materials_assessment?).to eq(assessment)
    end

    it "works with safe navigation operator" do
      # Should not create assessment and return nil
      expect(inspection.materials_assessment?&.ropes).to be_nil

      # Verify no assessment was created for this inspection
      expect(inspection.materials_assessment?).to be_nil
    end

    it "works with safe navigation on existing assessment" do
      # Create assessment with passed = true
      inspection.materials_assessment.update!(ropes: 10)

      # Safe navigation should work
      expect(inspection.materials_assessment?&.ropes).to eq(10)
    end
  end

  describe "mixed usage" do
    it "? method finds assessment created by direct access" do
      # Direct access creates it
      created = inspection.user_height_assessment

      # ? method should find the same one
      found = inspection.user_height_assessment?

      expect(found).to eq(created)
      expect(found).to be_persisted
    end
  end
end
