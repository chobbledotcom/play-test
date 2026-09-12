# typed: true
# frozen_string_literal: true

class UnitCsvExportService
  extend T::Sig
  include CsvExport

  ATTRIBUTES = %w[id name manufacturer serial].freeze

  sig { params(units: ActiveRecord::Relation).void }
  def initialize(units)
    @units = units
  end

  private

  sig { returns(ActiveRecord::Relation) }
  def records
    @units.order(created_at: :desc)
  end

  sig { returns(T::Array[String]) }
  def headers
    ATTRIBUTES
  end

  sig { params(unit: Unit).returns(T::Array[T.untyped]) }
  def row_for(unit)
    ATTRIBUTES.map { |attr| unit.send(attr) }
  end
end
