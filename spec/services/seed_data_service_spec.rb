require "rails_helper"

RSpec.describe SeedDataService do
  let(:user) { create(:user) }

  describe ".add_seeds_for_user" do
    context "when user has no seed data" do
      it "creates 20 seed units" do
        expect { described_class.add_seeds_for_user(user) }
          .to change { user.units.count }.by(20)

        expect(user.units.seed_data.count).to eq(20)
        expect(user.units.non_seed_data.count).to eq(0)
      end

      it "creates 5 inspections per unit" do
        expect { described_class.add_seeds_for_user(user) }
          .to change { user.inspections.count }.by(100)

        expect(user.inspections.seed_data.count).to eq(100)
      end

      it "creates units with varied manufacturers and descriptions" do
        described_class.add_seeds_for_user(user)

        units = user.units.seed_data
        manufacturers = units.pluck(:manufacturer).uniq
        descriptions = units.pluck(:description).uniq

        expect(manufacturers.count).to be > 1
        expect(descriptions.count).to be > 1
        expect(units.count).to be > 0
      end

      it "creates inspections with proper date spacing" do
        described_class.add_seeds_for_user(user)

        unit = user.units.seed_data.first
        inspections = unit.inspections.order(:inspection_date)

        inspections.each_cons(2) do |older, newer|
          # DateTime subtraction gives seconds, divide by seconds per day
          days_between = ((newer.inspection_date - older.inspection_date) / 1.day).to_i
          expect(days_between).to eq(364)
        end
      end

      it "creates complete inspections with all assessments" do
        described_class.add_seeds_for_user(user)

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

      it "creates half of units with incomplete most recent inspection" do
        described_class.add_seeds_for_user(user)

        units = user.units.seed_data
        units_with_incomplete_recent = 0
        units_with_all_complete = 0

        units.each do |unit|
          most_recent_inspection = unit.inspections.order(inspection_date: :desc).first
          if most_recent_inspection.complete?
            units_with_all_complete += 1
          else
            units_with_incomplete_recent += 1
          end
        end

        # Half should have incomplete most recent inspections (even indexed units)
        expect(units_with_incomplete_recent).to eq(10)
        expect(units_with_all_complete).to eq(10)
      end

      it "returns true on success" do
        expect(described_class.add_seeds_for_user(user)).to be true
      end
    end

    context "when user already has seed data" do
      before do
        create(:unit, user: user, is_seed: true)
      end

      it "does not create any new data" do
        expect { described_class.add_seeds_for_user(user) }
          .to raise_error(RuntimeError, "User already has seed data")

        # Verify counts didn't change
        expect(user.units.count).to eq(1)
        expect(user.inspections.count).to eq(0)
      end

      it "raises an error" do
        expect { described_class.add_seeds_for_user(user) }
          .to raise_error(RuntimeError, "User already has seed data")
      end
    end

    context "when creation fails" do
      before do
        allow_any_instance_of(Unit).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new)
      end

      it "rolls back all changes" do
        initial_unit_count = user.units.count
        initial_inspection_count = user.inspections.count

        expect { described_class.add_seeds_for_user(user) }
          .to raise_error(ActiveRecord::RecordInvalid)

        # Verify rollback occurred
        expect(user.units.count).to eq(initial_unit_count)
        expect(user.inspections.count).to eq(initial_inspection_count)
      end

      it "raises an error" do
        expect { described_class.add_seeds_for_user(user) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe ".delete_seeds_for_user" do
    context "when user has seed data" do
      before do
        described_class.add_seeds_for_user(user)
      end

      it "deletes all seed units" do
        expect { described_class.delete_seeds_for_user(user) }
          .to change { user.units.seed_data.count }.from(20).to(0)
      end

      it "deletes all seed inspections" do
        expect { described_class.delete_seeds_for_user(user) }
          .to change { user.inspections.seed_data.count }.from(100).to(0)
      end

      it "does not delete non-seed data" do
        regular_unit = create(:unit, user: user, is_seed: false)
        regular_inspection = create(:inspection, user: user, unit: regular_unit, is_seed: false)

        described_class.delete_seeds_for_user(user)

        expect(user.units.non_seed_data).to include(regular_unit)
        expect(user.inspections.non_seed_data).to include(regular_inspection)
      end

      it "returns true on success" do
        expect(described_class.delete_seeds_for_user(user)).to be true
      end

      it "preserves non-seed data when deleting seeds" do
        # Create some non-seed data
        regular_unit = create(:unit, user: user, is_seed: false, name: "Regular Unit")
        regular_inspection = create(:inspection, user: user, unit: regular_unit, is_seed: false)

        # Delete seed data
        described_class.delete_seeds_for_user(user)

        # Non-seed data should still exist
        expect(user.units.non_seed_data).to include(regular_unit)
        expect(user.inspections.non_seed_data).to include(regular_inspection)

        # Verify counts
        expect(user.units.count).to eq(1)
        expect(user.inspections.count).to eq(1)
      end
    end

    context "when deletion fails" do
      before do
        described_class.add_seeds_for_user(user)
        allow_any_instance_of(ActiveRecord::Relation).to receive(:destroy_all).and_raise(StandardError)
      end

      it "raises an error" do
        expect { described_class.delete_seeds_for_user(user) }
          .to raise_error(StandardError)
      end
    end
  end

  describe "castle image reuse" do
    it "reuses existing blobs for castle images" do
      # First user creates the blobs
      described_class.add_seeds_for_user(user)
      initial_blob_count = ActiveStorage::Blob.count

      # Second user should reuse the same blobs
      second_user = create(:user)
      described_class.add_seeds_for_user(second_user)

      expect(ActiveStorage::Blob.count).to eq(initial_blob_count)
    end

    it "allows individual units to change their images" do
      described_class.add_seeds_for_user(user)

      unit1 = user.units.seed_data.first
      unit2 = user.units.seed_data.second

      # Both might have the same image initially
      original_blob1 = unit1.photo.blob
      original_blob2 = unit2.photo.blob

      # Change unit1's image
      new_image = Rack::Test::UploadedFile.new(
        Rails.root.join("spec/fixtures/files/test_image.jpg"),
        "image/jpeg"
      )
      unit1.photo.attach(new_image)

      # unit1 should have a new image
      expect(unit1.reload.photo.blob).not_to eq(original_blob1)

      # unit2 should still have its original image
      expect(unit2.reload.photo.blob).to eq(original_blob2)
    end
  end
end
