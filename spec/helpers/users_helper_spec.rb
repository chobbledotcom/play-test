# typed: false

require "rails_helper"

RSpec.describe UsersHelper, type: :helper do
  describe "#admin_status" do
    it "returns 'Yes' for admin users" do
      user = create(:user, :admin)
      expect(helper.admin_status(user)).to eq("Yes")
    end

    it "returns 'No' for non-admin users" do
      user = create(:user)
      expect(helper.admin_status(user)).to eq("No")
    end
  end

  describe "#inspection_count" do
    it "returns singular form for 1 inspection" do
      user = create(:user)
      create(:inspection, user: user)
      expect(helper.inspection_count(user)).to eq("1 inspection")
    end

    it "returns plural form for 0 inspections" do
      user = create(:user)
      expect(helper.inspection_count(user)).to eq("0 inspections")
    end

    it "returns plural form for multiple inspections" do
      user = create(:user)
      5.times { create(:inspection, user: user) }
      expect(helper.inspection_count(user)).to eq("5 inspections")
    end
  end

  describe "#user_activity_indicator" do
    it "shows days remaining for active users" do
      user = create(:user, active_until: Date.current + 30.days)
      result = helper.user_activity_indicator(user)
      expect(result).to include(I18n.t("users.status.active", days: 30))
      expect(result).to include('value="active"')
    end

    it "shows days since expiry for inactive users" do
      user = create(:user, :inactive_user)
      result = helper.user_activity_indicator(user)
      expect(result).to include(I18n.t("users.status.inactive", days: 1))
      expect(result).to include('value="inactive"')
    end

    it "renders nothing when active_until is nil" do
      user = create(:user)
      user.update_column(:active_until, nil)
      result = helper.user_activity_indicator(user)
      expect(result).to eq("")
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
