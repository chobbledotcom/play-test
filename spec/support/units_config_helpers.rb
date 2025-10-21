# typed: false
# frozen_string_literal: true

module UnitsConfigHelpers
  # Enables unit badges feature with optional unbranded reports
  def enable_unit_badges(unbranded: false)
    set_units_config(badges_enabled: true, unbranded: unbranded)
  end

  # Disables unit badges feature
  def disable_unit_badges
    set_units_config(badges_enabled: false)
  end

  # Temporarily enables unit badges for the duration of a block
  # Automatically restores previous state after the block
  def with_unit_badges_enabled(unbranded: false)
    previous_config = Rails.configuration.units
    enable_unit_badges(unbranded: unbranded)
    yield
  ensure
    Rails.configuration.units = previous_config
  end

  # Temporarily disables unit badges for the duration of a block
  # Automatically restores previous state after the block
  def with_unit_badges_disabled
    previous_config = Rails.configuration.units
    disable_unit_badges
    yield
  ensure
    Rails.configuration.units = previous_config
  end

  private

  # Internal helper to set the UnitsConfig
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
