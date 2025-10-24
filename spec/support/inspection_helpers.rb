# typed: false

module InspectionHelpers
  include DeprecationHelper

  # DEPRECATED: Use create(:inspection, :completed) instead
  def create_completed_inspection(**options)
    print_deprecation(
      "create_completed_inspection is deprecated. Use create(:inspection, :completed) instead."
    )

    traits = options.delete(:traits) || []
    traits = [:completed] + Array(traits)
    create(:inspection, *traits, **options)
  end
end

RSpec.configure do |config|
  config.include InspectionHelpers, type: :feature
  config.include InspectionHelpers, type: :request
  config.include InspectionHelpers, type: :model
  config.include InspectionHelpers, type: :service
  config.include InspectionHelpers, type: :helper
end
