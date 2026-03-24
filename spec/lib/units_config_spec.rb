# typed: false

require "rails_helper"

RSpec.describe UnitsConfig do
  describe ".parse_unit_types" do
    it "returns empty array for nil" do
      expect(described_class.parse_unit_types(nil)).to eq([])
    end

    it "returns empty array for empty string" do
      expect(described_class.parse_unit_types("")).to eq([])
    end

    it "returns empty array for whitespace" do
      expect(described_class.parse_unit_types("  ")).to eq([])
    end

    it "parses comma-separated values" do
      result = described_class.parse_unit_types(
        "bouncy_castle,catch_bed"
      )
      expect(result).to eq(%w[bouncy_castle catch_bed])
    end

    it "strips whitespace from values" do
      result = described_class.parse_unit_types(
        " bouncy_castle , catch_bed "
      )
      expect(result).to eq(%w[bouncy_castle catch_bed])
    end
  end

  describe "#available_unit_types" do
    it "returns all types when enabled_unit_types is empty" do
      config = described_class.new(
        badges_enabled: false,
        reports_unbranded: false,
        pdf_filename_prefix: "",
        enabled_unit_types: []
      )
      expect(config.available_unit_types).to eq(
        Unit.unit_types.keys
      )
    end

    it "filters to only enabled types" do
      config = described_class.new(
        badges_enabled: false,
        reports_unbranded: false,
        pdf_filename_prefix: "",
        enabled_unit_types: %w[bouncy_castle catch_bed]
      )
      expect(config.available_unit_types).to eq(
        %w[bouncy_castle catch_bed]
      )
    end
  end

  describe "#unit_type_selection?" do
    it "returns true when no types configured" do
      config = described_class.new(
        badges_enabled: false,
        reports_unbranded: false,
        pdf_filename_prefix: "",
        enabled_unit_types: []
      )
      expect(config.unit_type_selection?).to be true
    end

    it "returns true when multiple types enabled" do
      config = described_class.new(
        badges_enabled: false,
        reports_unbranded: false,
        pdf_filename_prefix: "",
        enabled_unit_types: %w[bouncy_castle catch_bed]
      )
      expect(config.unit_type_selection?).to be true
    end

    it "returns false when only one type enabled" do
      config = described_class.new(
        badges_enabled: false,
        reports_unbranded: false,
        pdf_filename_prefix: "",
        enabled_unit_types: %w[bouncy_castle]
      )
      expect(config.unit_type_selection?).to be false
    end
  end

  describe ".from_env" do
    it "parses ENABLED_UNIT_TYPES from environment" do
      env = {
        "UNIT_BADGES" => "false",
        "UNIT_REPORTS_UNBRANDED" => "false",
        "PDF_FILENAME_PREFIX" => "",
        "ENABLED_UNIT_TYPES" => "bouncy_castle,catch_bed"
      }
      config = described_class.from_env(env)
      expect(config.enabled_unit_types).to eq(
        %w[bouncy_castle catch_bed]
      )
    end

    it "defaults to empty array when not set" do
      config = described_class.from_env({})
      expect(config.enabled_unit_types).to eq([])
    end
  end
end
