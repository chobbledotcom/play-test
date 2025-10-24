# typed: true
# frozen_string_literal: true

class UnitCsvExportService
  extend T::Sig

  ATTRIBUTES = %w[id name manufacturer serial].freeze

  sig { params(units: ActiveRecord::Relation).void }
  def initialize(units)
    @units = units
  end

  sig { returns(String) }
  def generate
    CSV.generate(headers: true) do |csv|
      csv << ATTRIBUTES

      @units.order(created_at: :desc).each do |unit|
        csv << ATTRIBUTES.map { |attr| unit.send(attr) }
      end
    end
  end
end
