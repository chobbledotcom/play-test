module AssessmentHelpers
  # Helper method to get or apply traits to existing assessments created by inspection callbacks
  # This avoids uniqueness constraint violations when testing assessment behavior
  def assessment_with_traits(inspection, assessment_type, *traits)
    # Get the existing assessment created by inspection callback
    existing_assessment = inspection.send("#{assessment_type}_assessment")

    # If no traits specified, just return the existing assessment
    return existing_assessment if traits.empty?

    # Apply traits from factory without the inspection_id to avoid conflicts
    trait_attributes = build(:"#{assessment_type}_assessment", *traits)
      .attributes
      .except("inspection_id")

    existing_assessment.assign_attributes(trait_attributes)
    existing_assessment
  end
end

RSpec.configure do |config|
  config.include AssessmentHelpers, type: :model
end
