module JsonTestHelpers
  # Fields that should never appear in JSON responses
  SENSITIVE_FIELDS = %w[
    user_id
    created_at
    updated_at
    is_seed
  ].freeze

  # Basic fields that should be in inspection JSON
  INSPECTION_BASIC_FIELDS = %w[
    inspection_date
    inspection_location
    passed
    complete
  ].freeze

  # Assessment types we expect
  ASSESSMENT_TYPES = %w[
    user_height_assessment
    structure_assessment
    anchorage_assessment
    materials_assessment
    fan_assessment
    enclosed_assessment
    slide_assessment
  ].freeze

  # System fields that should not appear in assessments
  ASSESSMENT_EXCLUDED_FIELDS = %w[
    inspection_id
    created_at
    updated_at
    id
  ].freeze

  # Get JSON response and parse it
  def get_json(path)
    get path
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include("application/json")
    JSON.parse(response.body)
  end

  # Get JSON and verify basic structure
  def get_inspection_json(inspection)
    json = get_json("/inspections/#{inspection.id}.json")
    verify_inspection_json_structure(json)
    json
  end

  # Verify inspection JSON has expected structure
  def verify_inspection_json_structure(json)
    # Check basic fields are included
    INSPECTION_BASIC_FIELDS.each do |field|
      expect(json).to have_key(field)
    end

    # Check sensitive fields are excluded
    SENSITIVE_FIELDS.each do |field|
      expect(json).not_to have_key(field)
    end
  end

  # Create inspection with complete assessments
  def create_complete_inspection(user: nil, unit: nil, **options)
    user ||= create(:user)
    unit ||= create(:unit, user: user)
    create(:inspection, :pdf_complete_test_data, user: user, unit: unit, **options)
  end

  # Verify assessment JSON structure
  def expect_assessment_json(json, assessment_type, expected_fields)
    expect(json["assessments"]).to be_present
    expect(json["assessments"][assessment_type]).to be_present

    assessment = json["assessments"][assessment_type]
    expected_fields.each do |field|
      expect(assessment).to have_key(field.to_s)
    end

    # Verify system fields are excluded
    ASSESSMENT_EXCLUDED_FIELDS.each do |field|
      expect(assessment).not_to have_key(field)
    end
  end

  # Verify all assessments are included
  def expect_all_assessments_present(json)
    # Only check assessments that should exist for this inspection
    expected_assessments = %w[user_height_assessment structure_assessment
      anchorage_assessment materials_assessment
      fan_assessment]

    expected_assessments.each do |assessment_type|
      expect(json["assessments"]).to have_key(assessment_type)
    end
  end
end

RSpec.configure do |config|
  config.include JsonTestHelpers, type: :request
end
