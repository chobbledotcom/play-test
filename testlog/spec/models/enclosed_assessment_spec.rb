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
end
