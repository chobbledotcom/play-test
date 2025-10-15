# typed: false

require "rails_helper"

RSpec.describe SeedDataService do
  let(:user) { create(:user) }

  describe ".add_seeds_for_user" do
    context "when user has no seed data" do
      shared_examples "basic seed creation" do
        it "returns true on success" do
          result = described_class.add_seeds_for_user(
            user,
            unit_count: 1,
            inspection_count: 1
          )
          expect(result).to be true
        end

        it "creates complete inspections with all assessments" do
          described_class.add_seeds_for_user(
            user,
            unit_count: 1,
            inspection_count: 2
          )

          inspection = user.inspections.seed_data.complete.first
          expect(inspection.user_height_assessment).to be_present
          expect(inspection.structure_assessment).to be_present
          expect(inspection.anchorage_assessment).to be_present
          expect(inspection.materials_assessment).to be_present
          expect(inspection.fan_assessment).to be_present

          if inspection.has_slide?
            expect(inspection.slide_assessment).to be_present
          end

          if inspection.is_totally_enclosed?
            expect(inspection.enclosed_assessment).to be_present
          end
        end
      end

      context "when UNIT_BADGES is enabled" do
        before do
          allow(Rails.configuration.units).to receive(:badges_enabled)
            .and_return(true)
        end

        include_examples "basic seed creation"

        it "creates badges for seed units" do
          count = 3
          described_class.add_seeds_for_user(
            user,
            unit_count: count,
            inspection_count: 1
          )

          seed_units = user.units.seed_data
          expect(seed_units.count).to eq(3)

          seed_units.each do |unit|
            expect(Badge.exists?(id: unit.id)).to be true
          end
        end

        it "creates a badge batch for seed badges" do
          initial_batch_count = BadgeBatch.count
          count = 3

          described_class.add_seeds_for_user(
            user,
            unit_count: count,
            inspection_count: 1
          )

          expect(BadgeBatch.count).to eq(initial_batch_count + 1)

          batch = BadgeBatch.last
          expect(batch.note).to include("Seed data badges")
          expect(batch.note).to include(user.email)
        end

        it "associates seed unit badges with the badge batch" do
          count = 3
          described_class.add_seeds_for_user(
            user,
            unit_count: count,
            inspection_count: 1
          )

          batch = BadgeBatch.last
          seed_units = user.units.seed_data

          seed_units.each do |unit|
            badge = Badge.find(unit.id)
            expect(badge.badge_batch).to eq(batch)
          end
        end
      end

      context "when UNIT_BADGES is disabled" do
        before do
          allow(Rails.configuration.units).to receive(:badges_enabled)
            .and_return(false)
        end

        include_examples "basic seed creation"

        it "does not create badges for seed units" do
          initial_badge_count = Badge.count
          count = 3

          described_class.add_seeds_for_user(
            user,
            unit_count: count,
            inspection_count: 1
          )

          expect(Badge.count).to eq(initial_badge_count)
        end

        it "does not create badge batches" do
          initial_batch_count = BadgeBatch.count
          count = 3

          described_class.add_seeds_for_user(
            user,
            unit_count: count,
            inspection_count: 1
          )

          expect(BadgeBatch.count).to eq(initial_batch_count)
        end
      end
    end

    context "when user already has seed data" do
      before do
        create(:unit, user: user, is_seed: true)
      end

      it "raises an error" do
        expect { described_class.add_seeds_for_user(user) }
          .to raise_error(RuntimeError, "User already has seed data")
      end
    end

    context "when creation fails" do
      before do
        allow_any_instance_of(Unit).to receive(:save!)
          .and_raise(ActiveRecord::RecordInvalid.new)
      end

      it "rolls back all changes" do
        initial_unit_count = user.units.count
        initial_inspection_count = user.inspections.count

        expect { described_class.add_seeds_for_user(user) }
          .to raise_error(ActiveRecord::RecordInvalid)

        expect(user.units.count).to eq(initial_unit_count)
        expect(user.inspections.count).to eq(initial_inspection_count)
      end
    end
  end

  describe ".delete_seeds_for_user" do
    shared_examples "seed deletion" do
      context "when user has seed data" do
        before do
          count = 1
          described_class.add_seeds_for_user(
            user,
            unit_count: count,
            inspection_count: 1
          )
        end

        it "returns true on success" do
          expect(described_class.delete_seeds_for_user(user)).to be true
        end
      end

      context "when deletion fails" do
        before do
          count = 1
          described_class.add_seeds_for_user(
            user,
            unit_count: count,
            inspection_count: 1
          )
          allow_any_instance_of(ActiveRecord::Relation)
            .to receive(:destroy_all)
            .and_raise(StandardError)
        end

        it "raises an error" do
          expect { described_class.delete_seeds_for_user(user) }
            .to raise_error(StandardError)
        end
      end
    end

    context "when UNIT_BADGES is enabled" do
      before do
        allow(Rails.configuration.units).to receive(:badges_enabled)
          .and_return(true)
      end

      include_examples "seed deletion"
    end

    context "when UNIT_BADGES is disabled" do
      before do
        allow(Rails.configuration.units).to receive(:badges_enabled)
          .and_return(false)
      end

      include_examples "seed deletion"
    end
  end
end
