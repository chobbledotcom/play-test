# typed: strict
# frozen_string_literal: true

class UnitBlueprint < Blueprinter::Base
  extend T::Sig

  # Define public fields dynamically to avoid database access at load time
  sig { returns(T.nilable(T::Boolean)) }
  def self.define_public_fields
    return if @fields_defined

    Unit.column_name_syms.each do |column|
      next if PublicFieldFiltering::EXCLUDED_FIELDS.include?(column)

      if %i[manufacture_date].include?(column)
        field column do |unit|
          value = unit.send(column)
          value&.strftime(JsonDateTransformer::API_DATE_FORMAT)
        end
      else
        field column
      end
    end
    @fields_defined = true
  end

  # Override render to ensure fields are defined
  sig { params(object: T.untyped, options: T::Hash[T.untyped, T.untyped]).returns(String) }
  def self.render(object, options = {})
    define_public_fields
    super
  end

  # Add URLs (available in all views)
  field :urls do |unit|
    base_url = Rails.configuration.app.base_url
    {
      report_pdf: "#{base_url}/units/#{unit.id}.pdf",
      report_json: "#{base_url}/units/#{unit.id}.json",
      qr_code: "#{base_url}/units/#{unit.id}.png"
    }
  end

  # Override render to handle inspection fields conditionally
  sig { params(unit: Unit).returns(String) }
  def self.render_with_inspections(unit)
    json = JSON.parse(render(unit, view: :default), symbolize_names: true)

    completed = unit.inspections.complete.order(inspection_date: :desc)

    if completed.any?
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

    # Apply date transformation
    transformer = JsonDateTransformer.new
    json = transformer.transform_value(json)

    json.to_json
  end

  # Use transformer to format dates
  transform JsonDateTransformer
end
