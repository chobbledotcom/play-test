# typed: false
# frozen_string_literal: true

# Wrapper service for backward compatibility with tests
# Now delegates to Blueprinter serializers
class JsonSerializerService
  def self.format_value(value)
    case value
    when Date, Time, DateTime
      value.strftime(JsonDateTransformer::API_DATE_FORMAT)
    else
      value
    end
  end

  def self.serialize_unit(unit, include_inspections: true)
    return nil unless unit

    json_str = if include_inspections
      UnitBlueprint.render_with_inspections(unit)
    else
      UnitBlueprint.render(unit, view: :default)
    end
    JSON.parse(json_str, symbolize_names: true)
  end

  def self.serialize_inspection(inspection)
    return nil unless inspection

    JSON.parse(InspectionBlueprint.render(inspection), symbolize_names: true)
  end

  def self.serialize_assessment(assessment, klass)
    excluded = PublicFieldFiltering::EXCLUDED_FIELDS
    assessment_fields = klass.column_name_syms - excluded

    data = {}
    assessment_fields.each do |field|
      value = assessment.send(field)
      data[field.to_sym] = format_value(value) unless value.nil?
    end

    data
  end
end
