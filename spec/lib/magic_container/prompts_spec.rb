# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe MagicContainer::Prompts do
  subject(:prompts) { described_class.new(input:, output:) }

  let(:input) { StringIO.new }
  let(:output) { StringIO.new }

  describe "#ask" do
    it "returns the default when the answer is blank" do
      answer = described_class.new(
        input: StringIO.new("\n"), output:
      ).ask("Name", default: "play-test")

      expect(answer).to eq("play-test")
    end

    it "returns the typed answer" do
      answer = described_class.new(
        input: StringIO.new("custom-name\n"), output:
      ).ask("Name", default: "play-test")

      expect(answer).to eq("custom-name")
    end

    it "re-asks until a required question is answered" do
      answer = described_class.new(
        input: StringIO.new("\nfinally\n"), output:
      ).ask("Name")

      expect(answer).to eq("finally")
      expect(output.string).to include("A value is required")
    end

    it "treats a blank default as optional" do
      answer = described_class.new(
        input: StringIO.new("\n"), output:
      ).ask("Name", default: "")

      expect(answer).to eq("")
    end
  end

  describe "#secret" do
    it "reads the value and notes it was hidden" do
      answer = described_class.new(
        input: StringIO.new("secret-value\n"), output:
      ).secret("Token")

      expect(answer).to eq("secret-value")
      expect(output.string).to include("(hidden input)")
    end
  end

  describe "#select" do
    let(:choices) { [["Docker Hub (docker.io)", "7"], ["GHCR (ghcr.io)", "9"]] }

    it "returns the value of the numbered choice" do
      answer = described_class.new(
        input: StringIO.new("2\n"), output:
      ).select("Registry", choices)

      expect(answer).to eq("9")
    end

    it "defaults to the first choice" do
      answer = described_class.new(
        input: StringIO.new("\n"), output:
      ).select("Registry", choices)

      expect(answer).to eq("7")
    end

    it "asks again when the number is out of range" do
      answer = described_class.new(
        input: StringIO.new("99\n1\n"), output:
      ).select("Registry", choices)

      expect(answer).to eq("7")
      expect(output.string).to include("Not a valid choice")
    end
  end

  describe "#confirm" do
    it "accepts yes" do
      answer = described_class.new(
        input: StringIO.new("y\n"), output:
      ).confirm("Proceed?")

      expect(answer).to be true
    end

    it "accepts no" do
      answer = described_class.new(
        input: StringIO.new("n\n"), output:
      ).confirm("Proceed?")

      expect(answer).to be false
    end

    it "falls back to the default on a blank answer" do
      answer = described_class.new(
        input: StringIO.new("\n"), output:
      ).confirm("Proceed?", default: false)

      expect(answer).to be false
    end
  end
end
