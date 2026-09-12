# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe SentryUserTaggingService, type: :service do
  after { Current.reset }

  it "tags the event with the signed-in user" do
    user = create(:user)
    Current.user = user
    event = Struct.new(:user).new

    result = described_class.tag(event)

    expect(result).to equal(event)
    expect(event.user).to eq({id: user.id, email: user.email})
  end

  it "leaves the event unchanged when nobody is signed in" do
    event = Struct.new(:user).new

    result = described_class.tag(event)

    expect(result).to equal(event)
    expect(event.user).to be_nil
  end
end
