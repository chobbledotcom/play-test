# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Current, type: :model do
  after { Current.reset }

  it "defaults to no user" do
    expect(Current.user).to be_nil
  end

  it "stores the signed-in user" do
    user = create(:user)

    Current.user = user

    expect(Current.user).to eq(user)
  end

  it "clears the user on reset so requests stay isolated" do
    Current.user = create(:user)

    Current.reset

    expect(Current.user).to be_nil
  end
end
