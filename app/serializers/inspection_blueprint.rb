# typed: false
# frozen_string_literal: true

class InspectionBlueprint < Blueprinter::Base
  # Define public fields dynamically to avoid database access at load time
  def self.define_public_fields
    return if @fields_defined
    Inspection.column_names.each do |column|
      next if PublicFieldFiltering::EXCLUDED_FIELDS.include?(column)
      # Special handling for date/time fields
      if %w[inspection_date complete_date].include?(column)
        field column.to_sym do |inspection|
          value = inspection.send(column)
          value&.strftime(JsonDateTransformer::API_DATE_FORMAT)
        end
      else
        field column.to_sym
      end
    end
    @fields_defined = true
  end

  # Override render to ensure fields are defined
  def self.render(object, options = {})
    define_public_fields
    super
  end

  # Add computed fields
  field :complete do |inspection|
    inspection.complete?
  end

  field :passed do |inspection|
    inspection.passed? if inspection.complete?
  end

  # Add inspector info
  field :inspector do |inspection|
    {
      name: inspection.user.name,
      rpii_inspector_number: inspection.user.rpii_inspector_number
    }
  end

  # Add URLs
  field :urls do |inspection|
    base_url = ENV["BASE_URL"]
    {
      report_pdf: "#{base_url}/inspections/#{inspection.id}.pdf",
      report_json: "#{base_url}/inspections/#{inspection.id}.json",
      qr_code: "#{base_url}/inspections/#{inspection.id}.png"
    }
  end

  # Add unit info
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

  # Add assessments
  field :assessments do |inspection|
    assessments = {}
    inspection.each_applicable_assessment do |key, klass, assessment|
      if assessment
        # Use dynamic fields based on the assessment class
        assessment_data = {}
        public_fields = klass.column_names -
          PublicFieldFiltering::EXCLUDED_FIELDS
        public_fields.each do |field|
          value = assessment.send(field)
          assessment_data[field.to_sym] = value unless value.nil?
        end
        assessments[key] = assessment_data
      end
    end
    assessments
  end

  # Use transformer to format dates
  transform JsonDateTransformer
end
