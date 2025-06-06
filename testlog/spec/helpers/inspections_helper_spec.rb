require "rails_helper"

RSpec.describe InspectionsHelper, type: :helper do
  describe "#format_inspection_count" do
    it "formats the inspection count with limit if limit is positive" do
      user = double("User", inspections: double("Inspections", count: 5), inspection_limit: 10)
      expect(helper.format_inspection_count(user)).to eq("5 / 10 inspections")
    end

    it "formats the inspection count without limit if limit is zero" do
      user = double("User", inspections: double("Inspections", count: 5), inspection_limit: 0)
      expect(helper.format_inspection_count(user)).to eq("5 inspections")
    end
  end
end
