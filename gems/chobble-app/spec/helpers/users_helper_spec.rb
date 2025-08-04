require "rails_helper"

RSpec.describe UsersHelper, type: :helper do
  describe "#admin_status" do
    it "returns 'Yes' for admin users" do
      user = double("User", admin?: true)
      expect(helper.admin_status(user)).to eq("Yes")
    end

    it "returns 'No' for non-admin users" do
      user = double("User", admin?: false)
      expect(helper.admin_status(user)).to eq("No")
    end
  end

  describe "#inspection_count" do
    it "returns singular form for 1 inspection" do
      inspections = double("Inspections", count: 1)
      user = double("User", inspections: inspections)
      expect(helper.inspection_count(user)).to eq("1 inspection")
    end

    it "returns plural form for 0 inspections" do
      inspections = double("Inspections", count: 0)
      user = double("User", inspections: inspections)
      expect(helper.inspection_count(user)).to eq("0 inspections")
    end

    it "returns plural form for multiple inspections" do
      inspections = double("Inspections", count: 5)
      user = double("User", inspections: inspections)
      expect(helper.inspection_count(user)).to eq("5 inspections")
    end
  end

  describe "#format_job_time" do
    it "returns 'Never' for nil time" do
      expect(helper.format_job_time(nil)).to eq("Never")
    end

    it "formats time correctly" do
      time = 2.hours.ago
      expect(helper.format_job_time(time)).to eq("about 2 hours ago")
    end
  end
end
