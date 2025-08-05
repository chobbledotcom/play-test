# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "RSpec-Sorbet Integration" do
  describe "Sorbet matchers" do
    it "can use rspec-sorbet matchers" do
      # Test that rspec-sorbet is loaded and working
      expect(defined?(RSpec::Sorbet)).to be_truthy
    end

    it "has Sorbet runtime available" do
      # Check that Sorbet runtime is available
      expect(defined?(T)).to be_truthy
    end
  end
end
