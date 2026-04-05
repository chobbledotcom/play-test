# typed: strict
# frozen_string_literal: true

# Typed configuration for unit-related settings
class UnitsConfig < T::Struct
  extend T::Sig

  # Whether to show QR code badges for units
  const :badges_enabled, T::Boolean

  # Whether unit reports should be unbranded (no logos/company info)
  const :reports_unbranded, T::Boolean

  # Prefix for PDF filenames (defaults to empty string)
  const :pdf_filename_prefix, String

  # Allowed unit types (empty array means all types allowed)
  const :enabled_unit_types, T::Array[String]

  sig { params(env: T::Hash[String, T.nilable(String)]).returns(UnitsConfig) }
  def self.from_env(env)
    new(
      badges_enabled: env["UNIT_BADGES"] == "true",
      reports_unbranded: env["UNIT_REPORTS_UNBRANDED"] == "true",
      pdf_filename_prefix: env["PDF_FILENAME_PREFIX"] || "",
      enabled_unit_types: parse_unit_types(env["ENABLED_UNIT_TYPES"])
    )
  end

  sig { params(value: T.nilable(String)).returns(T::Array[String]) }
  def self.parse_unit_types(value)
    return [] if value.nil? || value.strip.empty?
    value.split(",").map(&:strip).reject(&:empty?)
  end

  # Returns the unit types available for selection
  sig { returns(T::Array[String]) }
  def available_unit_types
    all_types = Unit.unit_types.keys
    return all_types if enabled_unit_types.empty?
    all_types.select { enabled_unit_types.include?(it) }
  end

  sig { returns(T::Boolean) }
  def unit_type_selection?
    enabled_unit_types.empty? || enabled_unit_types.length > 1
  end
end
