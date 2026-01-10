# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "csv"

class InspectionCsvExportService
  extend T::Sig

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

  sig { returns(String) }
  def generate
    CSV.generate(headers: true) do |csv|
      csv << headers

      @inspections.each do |inspection|
        csv << row_data(inspection)
      end
    end
  end

  private

  sig { returns(T::Array[String]) }
  def headers
    excluded_columns = %i[user_id inspector_company_id unit_id]
    inspection_columns = Inspection.column_name_syms - excluded_columns

    headers = inspection_columns
    headers += %i[unit_name unit_serial unit_manufacturer unit_description]
    headers += %i[inspector_company_name]
    headers += %i[inspector_user_email]
    headers += %i[complete]

    headers
  end

  sig { params(inspection: Inspection).returns(T::Array[T.untyped]) }
  def row_data(inspection)
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
