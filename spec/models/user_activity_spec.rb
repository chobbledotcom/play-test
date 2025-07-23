require "rails_helper"

RSpec.describe User, "#is_active?", type: :model do
  subject { build(:user, active_until: active_until).is_active? }

  context "when active_until is nil" do
    let(:active_until) { nil }
    it { is_expected.to be true }
  end

  context "when active_until is today" do
    let(:active_until) { Date.current }
    it { is_expected.to be false }

    it "becomes inactive at midnight" do
      # User with active_until set to today should be inactive
      user = build(:user, active_until: Date.current)
      expect(user.is_active?).to be false
    end
  end

  context "when active_until is tomorrow" do
    let(:active_until) { Date.current + 1.day }
    it { is_expected.to be true }

    it "remains active until midnight tomorrow" do
      user = build(:user, active_until: Date.current + 1.day)
      expect(user.is_active?).to be true
    end
  end

  context "when active_until is in past" do
    let(:active_until) { Date.current - 1.day }
    it { is_expected.to be false }
  end

  context "when active_until is far future (simulating activation)" do
    let(:active_until) { Date.current + 1000.years }
    it { is_expected.to be true }
  end

  it "aliases can_create_inspection? to is_active?" do
    user = build(:user, active_until: Date.current - 1.day)
    expect(user.can_create_inspection?).to eq(user.is_active?)
  end
end
