# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dedicated assessment user-count limits", type: :model do
  {
    bungee_run: :bungee_assessment,
    catch_bed: :catch_bed_assessment,
    inflatable_ball_pool: :ball_pool_assessment,
    inflatable_game: :inflatable_game_assessment
  }.each do |type, key|
    context type.to_s do
      let(:unit) { create(:unit, unit_type: type) }
      let(:inspection) { create(:inspection, unit: unit, checklist_revision: 2) }
      let(:assessment) { inspection.public_send(key) }

      it "requires an actual count for a current checklist" do
        assessment.update!(attributes_for(key, :complete)
          .merge(maximum_users: nil))

        expect(assessment.incomplete_fields).to include(:maximum_users)
      end

      it "stores zero without inventing a minimum safe capacity" do
        assessment.update!(attributes_for(key, :complete)
          .merge(maximum_users: 0))

        expect(assessment.reload.maximum_users).to eq(0)
        expect(assessment.complete?).to be true
      end

      it "rejects a non-count value rather than judging a safety threshold" do
        assessment.maximum_users = -1
        expect(assessment).not_to be_valid

        assessment.maximum_users = "1.5"
        expect(assessment).not_to be_valid
      end

      it "does not add missing-count requirements to untouched legacy records" do
        inspection.update_column(:checklist_revision, nil)
        assessment.maximum_users = nil

        expect(assessment.form_schema.attribute_names)
          .not_to include(:maximum_users)
        expect(assessment.incomplete_fields).not_to include(:maximum_users)
      end
    end
  end
end
