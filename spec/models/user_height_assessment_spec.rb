require "rails_helper"

RSpec.describe Assessments::UserHeightAssessment, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:assessment) { inspection.user_height_assessment }

  # Use shared examples for common behaviors
  it_behaves_like "an assessment model"
  it_behaves_like "has safety check methods", 5
  it_behaves_like "delegates to SafetyStandard", [:meets_height_requirements?, :calculate_user_capacity]

  describe "validations" do
    context "height measurements" do
      %w[containing_wall_height platform_height tallest_user_height].each do |field|
        include_examples "validates non-negative numeric field", field
      end
    end

    context "user capacity counts" do
      %w[users_at_1000mm users_at_1200mm users_at_1500mm users_at_1800mm].each do |field|
        include_examples "validates non-negative integer field", field
      end
    end

    context "play area dimensions" do
      %w[play_area_length play_area_width negative_adjustment].each do |field|
        include_examples "validates non-negative numeric field", field
      end
    end

    context "pass/fail assessments" do
      %w[height_requirements_pass permanent_roof_pass user_capacity_pass
        play_area_pass negative_adjustments_pass].each do |field|
        include_examples "validates boolean field", field
      end
    end

    context "comment fields" do
      %w[tallest_user_height_comment height_requirements_comment permanent_roof_pass_comment
        user_capacity_comment play_area_comment negative_adjustments_comment].each do |field|
        include_examples "validates comment field", field
      end
    end
  end

  describe "#complete?" do
    context "when all required fields are present and valid" do
      it "returns true" do
        assessment.update!(
          attributes_for(:user_height_assessment, :standard_test_values).merge(
            tallest_user_height_comment: "Good conditions",
            height_requirements_pass: true,
            permanent_roof_pass: true,
            user_capacity_pass: true,
            play_area_pass: true,
            negative_adjustments_pass: true
          )
        )
        expect(assessment.complete?).to be true
      end
    end

    context "when required fields are missing" do
      it "returns false" do
        assessment.containing_wall_height = nil
        expect(assessment.complete?).to be false
      end
    end

    context "when height measurements are invalid" do
      it "returns false when containing wall is lower than platform" do
        assessment.update!(
          containing_wall_height: 1.5,
          platform_height: 2.0,
          tallest_user_height: 1.8
        )
        expect(assessment.complete?).to be false
      end
    end
  end

  describe "#meets_height_requirements?" do
    context "with valid height data" do
      it "delegates to SafetyStandard" do
        assessment.tallest_user_height = 1.5
        assessment.containing_wall_height = 2.0

        expect(SafetyStandard).to receive(:meets_height_requirements?).with(1.5, 2.0).and_return(true)
        expect(assessment.meets_height_requirements?).to be true
      end
    end

    context "with missing height data" do
      it "returns false" do
        assessment.tallest_user_height = nil
        assessment.containing_wall_height = 2.0
        expect(assessment.meets_height_requirements?).to be false
      end
    end
  end

  describe "#total_user_capacity" do
    it "sums all user capacity counts" do
      assessment.users_at_1000mm = 10
      assessment.users_at_1200mm = 8
      assessment.users_at_1500mm = 6
      assessment.users_at_1800mm = 4

      expect(assessment.total_user_capacity).to eq(28)
    end

    it "handles nil values" do
      assessment.users_at_1000mm = 10
      assessment.users_at_1200mm = nil
      assessment.users_at_1500mm = 6
      assessment.users_at_1800mm = nil

      expect(assessment.total_user_capacity).to eq(16)
    end

    it "returns 0 when all values are nil" do
      assessment.users_at_1000mm = nil
      assessment.users_at_1200mm = nil
      assessment.users_at_1500mm = nil
      assessment.users_at_1800mm = nil

      expect(assessment.total_user_capacity).to eq(0)
    end
  end

  describe "#recommended_user_capacity" do
    context "with valid play area dimensions" do
      it "delegates to SafetyStandard" do
        assessment.play_area_length = 10.0
        assessment.play_area_width = 8.0
        assessment.negative_adjustment = 5.0

        expected_result = {users_1000mm: 50, users_1200mm: 37}
        expect(SafetyStandard).to receive(:calculate_user_capacity).with(10.0, 8.0, 5.0).and_return(expected_result)

        expect(assessment.recommended_user_capacity).to eq(expected_result)
      end
    end

    context "with missing dimensions" do
      it "returns empty hash" do
        assessment.play_area_length = nil
        assessment.play_area_width = 8.0

        expect(assessment.recommended_user_capacity).to eq({})
      end
    end
  end

  describe "edge cases" do
    it "handles very large dimensions" do
      assessment.update!(
        play_area_length: 999.99,
        play_area_width: 999.99,
        containing_wall_height: 999.99
      )

      expect(assessment).to be_valid
    end

    it "handles zero dimensions" do
      assessment.update!(
        play_area_length: 0,
        play_area_width: 0,
        containing_wall_height: 0
      )

      expect(assessment).to be_valid
    end

    it "handles decimal precision" do
      assessment.update!(
        containing_wall_height: 1.23456789,
        platform_height: 2.87654321
      )

      expect(assessment).to be_valid
      expect(assessment.containing_wall_height).to be_within(0.01).of(1.23)
    end
  end
end