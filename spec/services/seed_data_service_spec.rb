require "rails_helper"

RSpec.describe SeedDataService do
  let(:user) { create(:user) }

  describe ".add_seeds_for_user" do
    context "when user has no seed data" do
      it "returns true on success" do
        result = described_class.add_seeds_for_user(user, unit_count: 1, inspection_count: 1)
        expect(result).to be true
      end

      it "creates inspections with all assessments" do
        described_class.add_seeds_for_user(user, unit_count: 2, inspection_count: 1)

        complete_inspection = user.inspections.seed_data.complete.first
        expect(complete_inspection).to be_present
        expect(complete_inspection.user_height_assessment).to be_present
        expect(complete_inspection.structure_assessment).to be_present
        expect(complete_inspection.anchorage_assessment).to be_present
        expect(complete_inspection.materials_assessment).to be_present
        expect(complete_inspection.fan_assessment).to be_present

        if complete_inspection.has_slide?
          expect(complete_inspection.slide_assessment).to be_present
        end

        if complete_inspection.is_totally_enclosed?
          expect(complete_inspection.enclosed_assessment).to be_present
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
    context "when user has seed data" do
      before do
        described_class.add_seeds_for_user(user, unit_count: 1, inspection_count: 1)
      end

      it "returns true on success" do
        expect(described_class.delete_seeds_for_user(user)).to be true
      end
    end

    context "when deletion fails" do
      before do
        described_class.add_seeds_for_user(user, unit_count: 1, inspection_count: 1)
        allow_any_instance_of(ActiveRecord::Relation).to receive(:destroy_all)
          .and_raise(StandardError)
      end

      it "raises an error" do
        expect { described_class.delete_seeds_for_user(user) }
          .to raise_error(StandardError)
      end
    end
  end
end
