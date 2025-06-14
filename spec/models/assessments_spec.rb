require "rails_helper"

RSpec.describe "Assessment Models", type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  Inspection::ASSESSMENT_TYPES.each do |assessment_name, assessment_class|
    describe assessment_class do
      let(:assessment) { inspection.send(assessment_name) }

      it_behaves_like "an assessment model"
      it_behaves_like "has safety check methods"
    end
  end
end
