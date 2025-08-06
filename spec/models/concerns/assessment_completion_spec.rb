# typed: false

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
          :containing_wall_height
        )
        pass_fields.each do |field|
          expect(incomplete).to include(field)
        end
      end
    end

    context "with a partially complete assessment" do
      before do
        assessment.update!(
          containing_wall_height: 2.5
        )
      end

      it "only returns incomplete fields" do
        expect(incomplete).not_to include(
          :containing_wall_height
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
          users_at_1000mm: 5,
          users_at_1200mm: 10,
          users_at_1500mm: 8,
          users_at_1800mm: 2,
          custom_user_height_comment: "Test comments",
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

  describe "#incomplete_fields_grouped" do
    let(:inspection) { create(:inspection) }
    let(:assessment) { inspection.materials_assessment }

    context "when both value and pass fields are missing" do
      before do
        assessment.update!(ropes: nil, ropes_pass: nil)
      end

      it "groups them together under the base field" do
        grouped = assessment.incomplete_fields_grouped

        expect(grouped[:ropes]).to be_present
        expect(grouped[:ropes][:fields]).to contain_exactly(:ropes, :ropes_pass)
        expect(grouped[:ropes][:partial]).to eq("number_pass_fail_na_comment")
      end
    end

    context "when only pass field is missing" do
      before do
        assessment.update!(ropes: 10, ropes_pass: nil)
      end

      it "returns only the pass field" do
        grouped = assessment.incomplete_fields_grouped

        expect(grouped[:ropes_pass]).to be_present
        expect(grouped[:ropes_pass][:fields]).to eq([:ropes_pass])
      end
    end

    context "when only value field is missing" do
      before do
        assessment.update!(ropes: nil, ropes_pass: 1)
      end

      it "returns only the value field" do
        grouped = assessment.incomplete_fields_grouped

        expect(grouped[:ropes]).to be_present
        expect(grouped[:ropes][:fields]).to eq([:ropes])
      end
    end

    context "when pass field is set to NA" do
      before do
        assessment.update!(ropes: nil, ropes_pass: "na")
      end

      it "does not include the value field in incomplete fields" do
        expect(assessment.incomplete_fields).not_to include(:ropes)
      end

      it "does not include the pass field in incomplete fields (NA is a valid selection)" do
        expect(assessment.incomplete_fields).not_to include(:ropes_pass)
      end

      it "does not show either field as incomplete in grouped results" do
        grouped = assessment.incomplete_fields_grouped
        expect(grouped[:ropes]).to be_nil
        expect(grouped[:ropes_pass]).to be_nil
      end
    end

    context "when a pass-only field is set to NA" do
      before do
        assessment.update!(retention_netting_pass: "na")
      end

      it "does not include the field in incomplete fields (NA is a valid selection)" do
        expect(assessment.incomplete_fields).not_to include(:retention_netting_pass)
      end
    end

    context "when pass field is set to pass or fail" do
      before do
        assessment.update!(ropes: nil, ropes_pass: "pass")
      end

      it "includes the value field in incomplete fields" do
        expect(assessment.incomplete_fields).to include(:ropes)
      end

      it "does not include the pass field in incomplete fields" do
        expect(assessment.incomplete_fields).not_to include(:ropes_pass)
      end
    end
  end
end
