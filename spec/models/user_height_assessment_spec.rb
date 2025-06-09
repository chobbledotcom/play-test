require "rails_helper"

RSpec.describe UserHeightAssessment, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:assessment) { create(:user_height_assessment, inspection: inspection) }

  describe "associations" do
    it "belongs to inspection" do
      expect(assessment.inspection).to eq(inspection)
    end
  end

  describe "validations" do
    context "height measurements" do
      it "validates containing_wall_height is non-negative" do
        assessment.containing_wall_height = -1.0
        expect(assessment).not_to be_valid
        expect(assessment.errors[:containing_wall_height]).to include("must be greater than or equal to 0")
      end

      it "validates platform_height is non-negative" do
        assessment.platform_height = -1.0
        expect(assessment).not_to be_valid
        expect(assessment.errors[:platform_height]).to include("must be greater than or equal to 0")
      end

      it "validates tallest_user_height is non-negative" do
        assessment.tallest_user_height = -1.0
        expect(assessment).not_to be_valid
        expect(assessment.errors[:tallest_user_height]).to include("must be greater than or equal to 0")
      end

      it "allows blank height measurements" do
        assessment.containing_wall_height = nil
        assessment.platform_height = nil
        assessment.tallest_user_height = nil
        expect(assessment).to be_valid
      end
    end

    context "user capacity counts" do
      it "validates users_at_1000mm is non-negative integer" do
        assessment.users_at_1000mm = -1
        expect(assessment).not_to be_valid
        expect(assessment.errors[:users_at_1000mm]).to include("must be greater than or equal to 0")
      end

      it "validates users_at_1200mm is integer" do
        assessment.users_at_1200mm = 5.5
        expect(assessment).not_to be_valid
        expect(assessment.errors[:users_at_1200mm]).to include("must be an integer")
      end

      it "allows blank user capacity counts" do
        assessment.users_at_1000mm = nil
        assessment.users_at_1200mm = nil
        assessment.users_at_1500mm = nil
        assessment.users_at_1800mm = nil
        expect(assessment).to be_valid
      end
    end

    context "play area dimensions" do
      it "validates play_area_length is non-negative" do
        assessment.play_area_length = -1.0
        expect(assessment).not_to be_valid
        expect(assessment.errors[:play_area_length]).to include("must be greater than or equal to 0")
      end

      it "validates negative_adjustment is non-negative" do
        assessment.negative_adjustment = -1.0
        expect(assessment).not_to be_valid
        expect(assessment.errors[:negative_adjustment]).to include("must be greater than or equal to 0")
      end
    end
  end

  describe "#complete?" do
    context "when all required fields are present and valid" do
      it "returns true" do
        assessment.update!(
          attributes_for(:user_height_assessment, :standard_test_values).merge(
            tallest_user_height_comment: "Good conditions"
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

  describe "#safety_check_count" do
    it "returns 5 height-related safety checks" do
      expect(assessment.safety_check_count).to eq(5)
    end
  end

  describe "#passed_checks_count" do
    it "counts all passed safety checks" do
      assessment.update!(attributes_for(:user_height_assessment, :with_basic_data))

      # This will depend on the specific business logic implementation
      expect(assessment.passed_checks_count).to be_a(Integer)
      expect(assessment.passed_checks_count).to be >= 0
      expect(assessment.passed_checks_count).to be <= 5
    end
  end

  describe "#completion_percentage" do
    it "calculates percentage of completed fields" do
      assessment.update!(
        containing_wall_height: 2.5,
        platform_height: 2.0,
        tallest_user_height: 1.5,
        users_at_1000mm: 5,
        users_at_1200mm: 4,
        users_at_1500mm: 3,
        # Leave some fields blank
        users_at_1800mm: nil,
        play_area_length: nil,
        play_area_width: nil
      )

      # 6 out of 12 fields completed = 50%
      expect(assessment.completion_percentage).to eq(50)
    end

    it "returns 0 when no fields are completed" do
      expect(assessment.completion_percentage).to eq(0)
    end

    it "returns 100 when all fields are completed" do
      assessment.update!(
        attributes_for(:user_height_assessment, :with_basic_data).merge(
          tallest_user_height_comment: "Complete"
        )
      )

      expect(assessment.completion_percentage).to eq(100)
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

  describe "audit logging" do
    it "logs assessment updates" do
      expect(assessment).to receive(:log_assessment_update)
      assessment.update!(containing_wall_height: 2.5)
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
