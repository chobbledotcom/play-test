# Shared concern for defining which fields should be excluded from public output
# Used by both PDF generation and JSON serialization to ensure consistency
module PublicFieldFiltering
  extend ActiveSupport::Concern

  # System/metadata fields to exclude from public outputs (shared)
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
    is_seed
  ].freeze

  # Additional fields to exclude from PDFs specifically
  PDF_EXCLUDED_FIELDS = %w[
    complete_date
    inspection_date
    unique_report_number
    general_notes
    recommendations
    inspection_location
  ].freeze

  # Fields excluded from PDFs (combines shared + PDF-specific)
  PDF_TOTAL_EXCLUDED_FIELDS = (EXCLUDED_FIELDS + PDF_EXCLUDED_FIELDS).freeze

  # Computed fields to exclude from public outputs
  EXCLUDED_COMPUTED_FIELDS = %w[
    reinspection_date
  ].freeze

  # Unit-specific exclusions
  UNIT_EXCLUDED_FIELDS = %w[
    notes
  ].freeze

  class_methods do
    def public_fields
      column_names - EXCLUDED_FIELDS - ((self == Unit) ? UNIT_EXCLUDED_FIELDS : [])
    end

    def excluded_fields_for_assessment(klass_name)
      EXCLUDED_FIELDS
    end
  end
end
