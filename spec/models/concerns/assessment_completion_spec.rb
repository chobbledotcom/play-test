require "rails_helper"

RSpec.describe AssessmentCompletion, type: :model do
  let(:inspection) { create(:inspection) }
  let(:assessment) { inspection.user_height_assessment }
  let(:incomplete) { assessment.incomplete_fields }
  let(:pass_fields) do
    assessment.class.column_names
      .select { |col| col.end_with?("_pass") }
      .map(&:to_sym)
  end

  describe "#incomplete_fields" do
    context "with a new assessment" do
      it "returns all required fields as incomplete" do
        expect(incomplete).to include(
          :containing_wall_height,
          :platform_height,
          :tallest_user_height
        )
        pass_fields.each do |field|
          expect(incomplete).to include(field)
        end
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
        expect(incomplete).not_to include(
          :containing_wall_height,
          :platform_height,
          :tallest_user_height
        )
        pass_fields.each do |field|
          expect(incomplete).to include(field)
        end
      end
    end

    context "with a complete assessment" do
      before do
        assessment.update!(
          containing_wall_height: 2.5,
          platform_height: 1.5,
          tallest_user_height: 1.8,
          has_permanent_roof: false,
          users_at_1000mm: 5,
          users_at_1200mm: 10,
          users_at_1500mm: 8,
          users_at_1800mm: 2,
          play_area_length: 10.0,
          play_area_width: 8.0,
          negative_adjustment: 0.0
        )
      end

      it "returns an empty array" do
        expect(incomplete).to be_empty
        expect(assessment).to be_complete
      end
    end
  end
end
