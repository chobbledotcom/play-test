# typed: true
# frozen_string_literal: true

# Shared CSV generation for export services: one mechanism for turning a
# collection into CSV via headers + per-record rows
module CsvExport
  extend ActiveSupport::Concern

  def generate
    CSV.generate(headers: true) do |csv|
      csv << headers

      records.each { |record| csv << row_for(record) }
    end
  end
end
