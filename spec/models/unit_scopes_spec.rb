require "rails_helper"

RSpec.describe Unit, type: :model do
  describe "filter scopes" do
    let(:user) { create(:user) }
    let!(:airquee_unit) { create(:unit, user: user, manufacturer: "Airquee") }
    let!(:other_unit) { create(:unit, user: user, manufacturer: "Other Brand") }
    let!(:stef_unit) { create(:unit, user: user, owner: "Stef's Castles") }
    let!(:other_owner_unit) { create(:unit, user: user, owner: "Other Owner") }

    describe ".by_manufacturer" do
      it "filters by manufacturer when provided" do
        expect(user.units.by_manufacturer("Airquee")).to contain_exactly(airquee_unit)
      end

      it "returns all units when nil is passed" do
        expect(user.units.by_manufacturer(nil)).to match_array(user.units)
      end

      it "returns all units when empty string is passed" do
        expect(user.units.by_manufacturer("")).to match_array(user.units)
      end

      it "returns empty when non-existent manufacturer is passed" do
        expect(user.units.by_manufacturer("NonExistent")).to be_empty
      end
    end

    describe ".by_owner" do
      it "filters by owner when provided" do
        expect(user.units.by_owner("Stef's Castles")).to contain_exactly(stef_unit)
      end

      it "returns all units when nil is passed" do
        expect(user.units.by_owner(nil)).to match_array(user.units)
      end

      it "returns all units when empty string is passed" do
        expect(user.units.by_owner("")).to match_array(user.units)
      end

      it "returns empty when non-existent owner is passed" do
        expect(user.units.by_owner("NonExistent")).to be_empty
      end
    end
  end
end
