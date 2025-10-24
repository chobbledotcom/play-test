# typed: false

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

  # Reflection helpers for assessment fields
  def pass_fields(assessment_class = described_class)
    assessment_class.column_names.select { |col| col.end_with?("_pass") }
  end

  def comment_fields(assessment_class = described_class)
    assessment_class.column_names.select { |col| col.end_with?("_comment") }
  end

  def set_all_pass_fields(assessment, value)
    pass_fields(assessment.class).each do |field|
      assessment.send("#{field}=", value)
    end
  end
end

RSpec.configure do |config|
  config.include AssessmentHelpers, type: :model
end
