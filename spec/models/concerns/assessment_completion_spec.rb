require "rails_helper"

RSpec.describe AssessmentCompletion, type: :model do
  let(:inspection) { create(:inspection) }
  let(:assessment) { inspection.user_height_assessment }

  describe "#incomplete_fields" do
    context "with a new assessment" do
      it "returns all required fields as incomplete" do
        incomplete = assessment.incomplete_fields

        expect(incomplete).to be_an(Array)
        expect(incomplete).not_to be_empty

        # Should include required measurements
        expect(incomplete.map { |f| f[:field] }).to include(
          :containing_wall_height,
          :platform_height,
          :tallest_user_height
        )

        # Should include pass/fail assessments
        expect(incomplete.map { |f| f[:field] }).to include(
          :height_requirements_pass,
          :permanent_roof_pass,
          :user_capacity_pass,
          :play_area_pass,
          :negative_adjustments_pass
        )
      end

      it "returns field info with labels and types" do
        incomplete = assessment.incomplete_fields
        field_info = incomplete.find { |f| f[:field] == :height_requirements_pass }

        expect(field_info).to include(
          field: :height_requirements_pass,
          type: :pass_fail
        )
        expect(field_info[:label]).to be_present
      end
    end

    context "with a partially complete assessment" do
      before do
        assessment.update!(
          containing_wall_height: 2.5,
          platform_height: 1.5,
          tallest_user_height: 1.8
        )
      end

      it "only returns incomplete fields" do
        incomplete = assessment.incomplete_fields

        # Should not include completed measurements
        expect(incomplete.map { |f| f[:field] }).not_to include(
          :containing_wall_height,
          :platform_height,
          :tallest_user_height
        )

        # Should still include uncompleted pass/fail assessments
        expect(incomplete.map { |f| f[:field] }).to include(
          :height_requirements_pass,
          :permanent_roof_pass,
          :user_capacity_pass,
          :play_area_pass,
          :negative_adjustments_pass
        )
      end
    end

    context "with a complete assessment" do
      before do
        assessment.update!(
          containing_wall_height: 2.5,
          platform_height: 1.5,
          tallest_user_height: 1.8,
          users_at_1000mm: 5,
          users_at_1200mm: 10,
          users_at_1500mm: 8,
          users_at_1800mm: 2,
          play_area_length: 10.0,
          play_area_width: 8.0,
          negative_adjustment: 0.0,
          permanent_roof: false,
          height_requirements_pass: true,
          permanent_roof_pass: false,
          user_capacity_pass: true,
          play_area_pass: true,
          negative_adjustments_pass: true
        )
      end

      it "returns an empty array" do
        incomplete = assessment.incomplete_fields
        expect(incomplete).to be_empty
        expect(assessment).to be_complete
      end
    end
  end
end
