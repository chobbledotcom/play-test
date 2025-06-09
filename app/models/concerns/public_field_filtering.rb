# Shared concern for defining which fields should be excluded from public output
# Used by both PDF generation and JSON serialization to ensure consistency
module PublicFieldFiltering
  extend ActiveSupport::Concern

  # System/metadata fields to exclude from public outputs
  EXCLUDED_FIELDS = %w[
    id
    created_at
    updated_at
    pdf_last_accessed_at
    user_id
    unit_id
    inspector_company_id
    inspector_signature
    signature_timestamp
    inspection_id
    complete_date
  ].freeze

  # Computed fields to exclude from public outputs
  EXCLUDED_COMPUTED_FIELDS = %w[
    reinspection_date
  ].freeze

  # Unit-specific exclusions
  UNIT_EXCLUDED_FIELDS = %w[
    notes
  ].freeze

  # Assessment-specific exclusions (matching PDF behavior from pdf_field_coverage_spec.rb)
  ASSESSMENT_EXCLUDED_FIELDS = {
    "StructureAssessment" => %w[unit_pressure_value],
    "AnchorageAssessment" => %w[num_anchors_comment anchor_accessories_comment anchor_degree_comment anchor_type_comment pull_strength_comment],
    "MaterialsAssessment" => %w[rope_size_comment thread_comment fabric_comment fire_retardant_comment],
    "FanAssessment" => %w[fan_size_comment blower_flap_comment blower_finger_comment pat_comment blower_visual_comment blower_serial],
    "EnclosedAssessment" => %w[exit_number_comment exit_visible_comment]
  }.freeze

  class_methods do
    def public_fields
      column_names - EXCLUDED_FIELDS - ((self == Unit) ? UNIT_EXCLUDED_FIELDS : [])
    end

    def excluded_fields_for_assessment(klass_name)
      EXCLUDED_FIELDS + (ASSESSMENT_EXCLUDED_FIELDS[klass_name] || [])
    end
  end
end
