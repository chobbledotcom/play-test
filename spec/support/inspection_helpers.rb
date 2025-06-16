module InspectionHelpers
  # DEPRECATED: Use create(:inspection, :completed) instead
  def create_completed_inspection(**options)
    warn <<~MSG
      [DEPRECATION] create_completed_inspection is deprecated and will be removed in the next version.
      Use create(:inspection, :completed) instead.
      
      Examples:
        create(:inspection, :completed)
        create(:inspection, :completed, user: user)
        create(:inspection, :completed, :without_slide)
    MSG

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
