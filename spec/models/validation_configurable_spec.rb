# typed: false

require "rails_helper"

RSpec.describe ValidationConfigurable do
  describe "YAML-based validations" do
    context "for UserHeightAssessment" do
      let(:assessment) { create(:inspection).user_height_assessment }

      it "applies min validation from YAML for containing_wall_height" do
        assessment.containing_wall_height = -1
        expect(assessment).not_to be_valid
        expect(assessment.errors[:containing_wall_height])
          .to include(I18n.t("errors.messages.greater_than_or_equal_to", count: 0))
      end

      it "applies max validation from YAML for containing_wall_height" do
        assessment.containing_wall_height = 51
        expect(assessment).not_to be_valid
        expect(assessment.errors[:containing_wall_height])
          .to include(I18n.t("errors.messages.less_than_or_equal_to", count: 50))
      end

      it "allows valid values for containing_wall_height" do
        assessment.containing_wall_height = 25
        assessment.valid?
        expect(assessment.errors[:containing_wall_height]).to be_empty
      end

      it "applies integer validation for users_at_1000mm" do
        assessment.users_at_1000mm = 5.5
        expect(assessment).not_to be_valid
        expect(assessment.errors[:users_at_1000mm])
          .to include(I18n.t("errors.messages.not_an_integer"))
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
      let(:inspection) { Inspection.new(user: user, unit: unit, inspection_date: Time.zone.today) }

      it "applies min validation from YAML for width" do
        inspection.width = -1
        expect(inspection).not_to be_valid
        expect(inspection.errors[:width])
          .to include(I18n.t("errors.messages.greater_than_or_equal_to", count: 0))
      end

      it "applies max validation from YAML for width" do
        inspection.width = 201
        expect(inspection).not_to be_valid
        expect(inspection.errors[:width])
          .to include(I18n.t("errors.messages.less_than_or_equal_to", count: 200))
      end

      it "applies validations for height with different max value" do
        inspection.height = 51
        expect(inspection).not_to be_valid
        expect(inspection.errors[:height])
          .to include(I18n.t("errors.messages.less_than_or_equal_to", count: 50))
      end
    end

    context "for numeric composite assessment fields" do
      let(:assessment) { create(:inspection).fan_assessment }

      it "accepts fractional decimal measurements" do
        assessment.blower_tube_length = 1.75
        assessment.valid?

        expect(assessment.errors[:blower_tube_length]).to be_empty
      end

      it "rejects malformed data rather than silently casting it" do
        assessment.blower_tube_length = "not a measurement"
        assessment.valid?

        expect(assessment.errors[:blower_tube_length])
          .to include(I18n.t("errors.messages.not_a_number"))
      end

      it "does not validate an omitted N/A measurement" do
        assessment.blower_tube_length = nil
        assessment.blower_tube_length_pass = "na"
        assessment.valid?

        expect(assessment.errors[:blower_tube_length]).to be_empty
        expect(assessment.incomplete_fields)
          .not_to include(:blower_tube_length, :blower_tube_length_pass)
      end
    end

    context "for hidden component measurements" do
      let(:unit) { create(:unit, unit_type: :play_zone) }
      let(:inspection) do
        create(:inspection, unit: unit, has_slide: false)
      end
      let(:assessment) { inspection.play_zone_assessment }

      it "does not let a hidden measurement block saving" do
        assessment.slide_gradient = -1
        assessment.valid?

        expect(assessment.errors[:slide_gradient]).to be_empty
      end
    end
  end
end
