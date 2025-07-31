require "rails_helper"

RSpec.describe ValidationConfigurable do
  describe "YAML-based validations" do
    context "for UserHeightAssessment" do
      let(:assessment) { Assessments::UserHeightAssessment.new }

      it "applies min validation from YAML for containing_wall_height" do
        assessment.containing_wall_height = -1
        expect(assessment).not_to be_valid
        expect(assessment.errors[:containing_wall_height]).to include("must be greater than or equal to 0")
      end

      it "applies max validation from YAML for containing_wall_height" do
        assessment.containing_wall_height = 51
        expect(assessment).not_to be_valid
        expect(assessment.errors[:containing_wall_height]).to include("must be less than or equal to 50")
      end

      it "allows valid values for containing_wall_height" do
        assessment.containing_wall_height = 25
        assessment.valid?
        expect(assessment.errors[:containing_wall_height]).to be_empty
      end

      it "applies integer validation for users_at_1000mm" do
        assessment.users_at_1000mm = 5.5
        expect(assessment).not_to be_valid
        expect(assessment.errors[:users_at_1000mm]).to include("must be an integer")
      end

      it "allows blank values" do
        assessment.containing_wall_height = nil
        assessment.valid?
        expect(assessment.errors[:containing_wall_height]).to be_empty
      end
    end

    context "for Inspection" do
      let(:user) { create(:user) }
      let(:unit) { create(:unit) }
      let(:inspection) { Inspection.new(user: user, unit: unit, inspection_date: Date.today) }

      it "applies min validation from YAML for width" do
        inspection.width = -1
        expect(inspection).not_to be_valid
        expect(inspection.errors[:width]).to include("must be greater than or equal to 0")
      end

      it "applies max validation from YAML for width" do
        inspection.width = 201
        expect(inspection).not_to be_valid
        expect(inspection.errors[:width]).to include("must be less than or equal to 200")
      end

      it "applies validations for height with different max value" do
        inspection.height = 51
        expect(inspection).not_to be_valid
        expect(inspection.errors[:height]).to include("must be less than or equal to 50")
      end
    end
  end
end
