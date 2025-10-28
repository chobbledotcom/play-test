# typed: false

require "rails_helper"

RSpec.describe User, "seed data methods" do
  let(:user) { create(:user) }

  describe "#has_seed_data?" do
    context "when user has no seed data" do
      it "returns false" do
        expect(user.has_seed_data?).to be false
      end
    end

    context "when user has seed units" do
      before { create(:unit, user: user, is_seed: true) }

      it "returns true" do
        expect(user.has_seed_data?).to be true
      end
    end

    context "when user has seed inspections" do
      before { create(:inspection, user: user, is_seed: true) }

      it "returns true" do
        expect(user.has_seed_data?).to be true
      end
    end

    context "when user has both seed units and inspections" do
      before do
        create(:unit, user: user, is_seed: true)
        create(:inspection, user: user, is_seed: true)
      end

      it "returns true" do
        expect(user.has_seed_data?).to be true
      end
    end

    context "when user only has non-seed data" do
      before do
        create(:unit, user: user, is_seed: false)
        create(:inspection, user: user, is_seed: false)
      end

      it "returns false" do
        expect(user.has_seed_data?).to be false
      end
    end
  end
end

RSpec.describe Unit, "seed data scopes" do
  describe ".seed_data" do
    it "returns only seed units" do
      seed_unit = create(:unit, is_seed: true)
      regular_unit = create(:unit, is_seed: false)

      expect(Unit.seed_data).to include(seed_unit)
      expect(Unit.seed_data).not_to include(regular_unit)
    end
  end

  describe ".non_seed_data" do
    it "returns only non-seed units" do
      seed_unit = create(:unit, is_seed: true)
      regular_unit = create(:unit, is_seed: false)

      expect(Unit.non_seed_data).not_to include(seed_unit)
      expect(Unit.non_seed_data).to include(regular_unit)
    end
  end
end

RSpec.describe Inspection, "seed data scopes" do
  describe ".seed_data" do
    it "returns only seed inspections" do
      seed_inspection = create(:inspection, is_seed: true)
      regular_inspection = create(:inspection, is_seed: false)

      expect(Inspection.seed_data).to include(seed_inspection)
      expect(Inspection.seed_data).not_to include(regular_inspection)
    end
  end

  describe ".non_seed_data" do
    it "returns only non-seed inspections" do
      seed_inspection = create(:inspection, is_seed: true)
      regular_inspection = create(:inspection, is_seed: false)

      expect(Inspection.non_seed_data).not_to include(seed_inspection)
      expect(Inspection.non_seed_data).to include(regular_inspection)
    end
  end
end
