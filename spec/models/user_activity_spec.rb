require "rails_helper"

RSpec.describe User, "#is_active?", type: :model do
  subject { build(:user, active_until: active_until).is_active? }

  context "when active_until is nil" do
    let(:active_until) { nil }
    it { is_expected.to be true }
  end

  context "when active_until is today" do
    let(:active_until) { Date.current }
    it { is_expected.to be true }
  end

  context "when active_until is in future" do
    let(:active_until) { Date.current + 1.day }
    it { is_expected.to be true }
  end

  context "when active_until is in past" do
    let(:active_until) { Date.current - 1.day }
    it { is_expected.to be false }
  end

  it "aliases can_create_inspection? to is_active?" do
    user = build(:user, active_until: Date.current - 1.day)
    expect(user.can_create_inspection?).to eq(user.is_active?)
  end
end
