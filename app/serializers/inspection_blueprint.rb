# typed: strict
# frozen_string_literal: true

class InspectionBlueprint < Blueprinter::Base
  extend T::Sig
  include DynamicPublicFields

  DATE_FIELDS = T.let(
    %i[complete_date inspection_date].freeze, T::Array[Symbol]
  )

  sig do
    params(
      object: T.untyped,
      options: T::Hash[T.untyped, T.untyped]
    ).returns(String)
  end
  def self.render(object, options = {})
    define_public_fields_for(Inspection, date_fields: DATE_FIELDS)
    super
  end

  field :complete do |inspection|
    inspection.complete?
  end

  field :passed do |inspection|
    inspection.passed? if inspection.complete?
  end

  field :inspector do |inspection|
    {
      name: inspection.user.name,
      rpii_inspector_number: inspection.user.rpii_inspector_number
    }
  end

  field :urls do |inspection|
    base_url = Rails.configuration.app.base_url
    {
      report_pdf: "#{base_url}/inspections/#{inspection.id}.pdf",
      report_json: "#{base_url}/inspections/#{inspection.id}.json",
      qr_code: "#{base_url}/inspections/#{inspection.id}.png"
    }
  end

  field :unit do |inspection|
    if inspection.unit
      {
        id: inspection.unit.id,
        name: inspection.unit.name,
        serial: inspection.unit.serial,
        manufacturer: inspection.unit.manufacturer,
        operator: inspection.unit.operator
      }
    end
  end

  field :assessments do |inspection|
    assessments = {}
    inspection.each_applicable_assessment do |key, klass, assessment|
      next unless assessment

      assessment_data = {}

      public_fields =
        klass.column_name_syms -
        PublicFieldFiltering::EXCLUDED_FIELDS

      public_fields.each do |field|
        value = assessment.send(field)
        assessment_data[field] = value unless value.nil?
      end

      assessments[key] = assessment_data
    end
    assessments
  end

  # Use transformer to format dates
  transform JsonDateTransformer
end
