# typed: strict
# frozen_string_literal: true

# Typed configuration for unit-related settings
class UnitsConfig < T::Struct
  extend T::Sig

  # Whether to show QR code badges for units
  const :badges_enabled, T::Boolean

  # Whether unit reports should be unbranded (no logos/company info)
  const :reports_unbranded, T::Boolean

  sig { params(env: T::Hash[String, T.nilable(String)]).returns(UnitsConfig) }
  def self.from_env(env)
    new(
      badges_enabled: env["UNIT_BADGES"] == "true",
      reports_unbranded: env["UNIT_REPORTS_UNBRANDED"] == "true"
    )
  end
end
