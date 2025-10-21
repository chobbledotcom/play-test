# typed: false
# frozen_string_literal: true

module UnitsConfigHelpers
  # Use with around hook to temporarily enable unit badges
  # Example:
  #   around { |example| with_unit_badges_enabled(&example) }
  def with_unit_badges_enabled(unbranded: false, &block)
    previous_config = Rails.configuration.units
    set_units_config(badges_enabled: true, unbranded: unbranded)
    block.call
  ensure
    Rails.configuration.units = previous_config
  end

  # Use with around hook to temporarily disable unit badges
  # Example:
  #   around { |example| with_unit_badges_disabled(&example) }
  def with_unit_badges_disabled(&block)
    previous_config = Rails.configuration.units
    set_units_config(badges_enabled: false)
    block.call
  ensure
    Rails.configuration.units = previous_config
  end

  private

  def set_units_config(badges_enabled:, unbranded: false)
    config = UnitsConfig.new(
      badges_enabled: badges_enabled,
      reports_unbranded: unbranded,
      pdf_filename_prefix: ""
    )
    Rails.configuration.units = config
  end
end

RSpec.configure do |config|
  config.include UnitsConfigHelpers
end
