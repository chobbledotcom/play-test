module InspectionHelpers
  # Create a properly completed inspection with all assessments filled
  # This is the recommended way to create complete inspections in tests
  #
  # Examples:
  #   create_completed_inspection
  #   create_completed_inspection(passed: false)
  #   create_completed_inspection(user: existing_user)
  #   create_completed_inspection(unit: existing_unit)
  #   create_completed_inspection(traits: [:with_slide])
  def create_completed_inspection(**options)
    # Extract traits from options
    traits = options.delete(:traits) || []

    # Always ensure :completed is included
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
