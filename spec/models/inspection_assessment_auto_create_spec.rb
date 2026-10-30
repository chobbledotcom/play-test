# typed: false

require "rails_helper"

RSpec.describe "Inspection assessment reads", type: :model do
  let(:inspection) { create(:inspection) }

  describe "reading missing assessments" do
    it "builds an unsaved assessment when accessed directly" do
      inspection
      expect { inspection.materials_assessment }.not_to change {
        Assessments::MaterialsAssessment.count
      }
      expect(inspection.materials_assessment)
        .to be_a(Assessments::MaterialsAssessment)
      expect(inspection.materials_assessment).to be_new_record
    end

    it "does not persist any assessment types on direct access" do
      inspection.assessment_types.each do |assessment_name, assessment_class|
        expect { inspection.public_send(assessment_name) }.not_to change {
          assessment_class.count
        }
        assessment = inspection.public_send(assessment_name)
        expect(assessment).to be_a(assessment_class)
        expect(assessment).to be_new_record
      end
    end

    it "leaves legacy revision and timestamps unchanged while reading gaps" do
      inspection.update_column(:checklist_revision, nil)
      original_attributes = inspection.reload.attributes

      inspection.applicable_tabs
      inspection.incomplete_fields
      inspection.each_applicable_assessment do |_, _, assessment|
        expect(assessment).to be_new_record
      end

      expect(inspection.reload.attributes).to eq(original_attributes)
      expect(inspection.materials_assessment?).to be_nil
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

    it "returns a saved assessment with ? method" do
      assessment = inspection.materials_assessment
      assessment.save!

      expect(inspection.reload.materials_assessment?).to eq(assessment)
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
    it "? method returns the in-memory assessment without persisting it" do
      built = inspection.user_height_assessment
      found = inspection.user_height_assessment?

      expect(found).to equal(built)
      expect(found).to be_new_record
      expect(inspection.reload.user_height_assessment?).to be_nil
    end
  end
end
