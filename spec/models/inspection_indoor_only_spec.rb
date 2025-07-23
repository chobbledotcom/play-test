require "rails_helper"

RSpec.describe Inspection, type: :model do
  describe "#applicable_assessments with indoor_only field" do
    let(:inspection) { create(:inspection) }

    context "when indoor_only is false (outdoor unit)" do
      before { inspection.update!(indoor_only: false) }

      it "includes anchorage_assessment in applicable assessments" do
        assessment_types = inspection.applicable_assessments.keys
        expect(assessment_types).to include(:anchorage_assessment)
      end
    end

    context "when indoor_only is true (indoor unit)" do
      before { inspection.update!(indoor_only: true) }

      it "excludes anchorage_assessment from applicable assessments" do
        assessment_types = inspection.applicable_assessments.keys
        expect(assessment_types).not_to include(:anchorage_assessment)
      end

      it "still includes other assessments" do
        assessment_types = inspection.applicable_assessments.keys
        expect(assessment_types).to include(
          :user_height_assessment,
          :structure_assessment,
          :materials_assessment,
          :fan_assessment
        )
      end
    end

    context "when has_slide is true" do
      before { inspection.update!(has_slide: true, indoor_only: true) }

      it "includes slide_assessment regardless of indoor_only" do
        assessment_types = inspection.applicable_assessments.keys
        expect(assessment_types).to include(:slide_assessment)
      end
    end

    context "when is_totally_enclosed is true" do
      before { inspection.update!(is_totally_enclosed: true, indoor_only: true) }

      it "includes enclosed_assessment regardless of indoor_only" do
        assessment_types = inspection.applicable_assessments.keys
        expect(assessment_types).to include(:enclosed_assessment)
      end
    end
  end

  describe "indoor_only field requirement" do
    it "includes indoor_only in required fields" do
      required_fields = Inspection::REQUIRED_TO_COMPLETE_FIELDS
      expect(required_fields).to include(:indoor_only)
    end

    it "is included in USER_EDITABLE_PARAMS" do
      expect(Inspection::USER_EDITABLE_PARAMS).to include(:indoor_only)
    end
  end
end
