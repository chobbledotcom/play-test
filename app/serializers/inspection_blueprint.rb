# typed: strict
# frozen_string_literal: true

class InspectionBlueprint < Blueprinter::Base
  extend T::Sig
  include DynamicPublicFields

  dynamic_fields_for Inspection,
    date_fields: %i[complete_date inspection_date],
    excluded_fields: %i[checklist_revision],
    revision_fields: %i[
      has_air_jugglers has_ancillary_equipment has_ball_pool has_blower
      has_containing_walls has_fencing has_inflatable_bed inspection_location
    ]

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
        operator: inspection.operator
      }
    end
  end

  field :assessments do |inspection|
    assessments = {}
    inspection.each_applicable_assessment do |key, klass, assessment|
      next unless assessment

      assessment_data = {}

      public_fields =
        (assessment.form_schema(user: nil).attribute_names &
          klass.column_name_syms) - PublicFieldFiltering::EXCLUDED_FIELDS

      public_fields.each do |field|
        value = assessment.send(field)
        if !inspection.current_checklist? &&
            klass.legacy_boolean_outcome_fields.include?(field) &&
            !value.nil?
          value = case value
          when "pass" then true
          when "fail" then false
          else value
          end
        end
        assessment_data[field] = value unless value.nil?
      end

      assessments[key] = assessment_data
    end
    assessments
  end

  # Use transformer to format dates
  transform JsonDateTransformer
end
