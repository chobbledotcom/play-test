# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Solid Queue recurring configuration" do
  let(:config) { YAML.safe_load_file(Rails.root.join("config/recurring.yml")) }

  it "loads as valid YAML" do
    expect(config).to be_a(Hash)
  end

  it "uses plain string arguments for the backup job" do
    expect(config.dig("development", "backup", "args")).to eq(["both"])
    expect(config.dig("test", "backup", "args")).to eq(["s3"])
    expect(config.dig("production", "backup", "args")).to eq(["s3"])

    %w[development test production].each do |env|
      args = config.dig(env, "backup", "args")
      expect(args).to all(be_a(String))
    end
  end
end
