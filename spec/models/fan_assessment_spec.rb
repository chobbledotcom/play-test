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
end
