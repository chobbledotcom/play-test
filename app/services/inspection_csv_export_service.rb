# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "csv"

class InspectionCsvExportService
  extend T::Sig
  include CsvExport

  sig do
    params(
      inspections: T.any(
        ActiveRecord::Relation,
        T::Array[Inspection]
      )
    ).void
  end
  def initialize(inspections)
    @inspections = inspections
  end

  private

  sig { returns(T.untyped) }
  def records
    @inspections
  end

  sig { returns(T::Array[Symbol]) }
  def headers
    headers = %i[
      id complete_date created_at has_slide height height_comment
      indoor_only inspection_date inspection_type is_seed is_totally_enclosed
      length length_comment operator passed pdf_last_accessed_at
      risk_assessment updated_at width width_comment
    ]
    headers += %i[unit_name unit_serial unit_manufacturer unit_description]
    headers += %i[inspector_company_name]
    headers += %i[inspector_user_email]
    headers += %i[complete]

    headers
  end

  sig { params(inspection: Inspection).returns(T::Array[T.untyped]) }
  def row_for(inspection)
    headers.map do |header|
      case header
      in :unit_name then inspection.unit&.name
      in :unit_serial then inspection.unit&.serial
      in :unit_manufacturer then inspection.unit&.manufacturer
      in :unit_description then inspection.unit&.description
      in :inspector_company_name then inspection.inspector_company&.name
      in :inspector_user_email then inspection.user&.email
      in :complete then inspection.complete?
      else inspection.send(header) if inspection.respond_to?(header)
      end
    end
  end
end
