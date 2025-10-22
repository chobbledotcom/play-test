# typed: strict
# frozen_string_literal: true

# Shared concern for defining which fields should be excluded from public output
# Used by both PDF generation and JSON serialization to ensure consistency
module PublicFieldFiltering
  extend T::Sig
  extend T::Helpers
  extend ActiveSupport::Concern
  include ColumnNameSyms

  # System/metadata fields to exclude from public outputs (shared)
  EXCLUDED_FIELDS = %i[
    id
    created_at
    updated_at
    pdf_last_accessed_at
    user_id
    unit_id
    inspector_company_id
    inspection_id
    is_seed
  ].freeze

  # Additional fields to exclude from PDFs specifically
  PDF_EXCLUDED_FIELDS = %i[
    complete_date
    inspection_date
  ].freeze

  # Fields excluded from PDFs (combines shared + PDF-specific)
  PDF_TOTAL_EXCLUDED_FIELDS = (EXCLUDED_FIELDS + PDF_EXCLUDED_FIELDS).freeze

  # Computed fields to exclude from public outputs
  EXCLUDED_COMPUTED_FIELDS = %i[
    reinspection_date
  ].freeze

  class_methods do
    extend T::Sig

    sig { returns(T::Array[Symbol]) }
    def public_fields
      column_name_syms - EXCLUDED_FIELDS
    end

    sig { params(klass_name: T.untyped).returns(T::Array[Symbol]) }
    def excluded_fields_for_assessment(klass_name)
      EXCLUDED_FIELDS
    end
  end
end
