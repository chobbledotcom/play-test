# typed: strict
# frozen_string_literal: true

class UnitBlueprint < Blueprinter::Base
  extend T::Sig
  include DynamicPublicFields

  dynamic_fields_for Unit, date_fields: %i[manufacture_date]

  # Add URLs (available in all views)
  field :urls do |unit|
    base_url = Rails.configuration.app.base_url
    {
      report_pdf: "#{base_url}/units/#{unit.id}.pdf",
      report_json: "#{base_url}/units/#{unit.id}.json",
      qr_code: "#{base_url}/units/#{unit.id}.png"
    }
  end

  sig { params(unit: Unit).returns(String) }
  def self.render_with_inspections(unit)
    json = JSON.parse(render(unit, view: :default), symbolize_names: true)
    completed = unit.inspections.complete.order(inspection_date: :desc)
    add_inspection_history(json, completed) if completed.any?
    JsonDateTransformer.new.transform_value(json).to_json
  end

  sig do
    params(
      json: T::Hash[Symbol, T.untyped],
      completed: T.untyped
    ).void
  end
  def self.add_inspection_history(json, completed)
    json[:inspection_history] = completed.map do |inspection|
      {
        inspection_date: inspection.inspection_date,
        passed: inspection.passed,
        complete: inspection.complete?,
        inspector_company: inspection.inspector_company&.name
      }
    end
    json[:total_inspections] = completed.count
    json[:last_inspection_date] = completed.first&.inspection_date
    json[:last_inspection_passed] = completed.first&.passed
  end

  # Use transformer to format dates
  transform JsonDateTransformer
end
