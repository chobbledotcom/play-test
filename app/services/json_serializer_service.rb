class JsonSerializerService
  def self.format_value(value)
    case value
    when Date, Time, DateTime
      value.strftime("%Y-%m-%d")
    else
      value
    end
  end

  def self.serialize_unit(unit, include_inspections: true)
    return nil unless unit

    unit_fields = Unit.column_names - PublicFieldFiltering::EXCLUDED_FIELDS

    data = {}
    unit_fields.each do |field|
      value = unit.send(field)
      data[field.to_sym] = format_value(value) unless value.nil?
    end

    if include_inspections
      completed_inspections = unit.inspections.complete.order(inspection_date: :desc)

      if completed_inspections.any?
        data[:inspection_history] = completed_inspections.map do |inspection|
          {
            inspection_date: format_value(inspection.inspection_date),
            passed: inspection.passed,
            complete: inspection.complete?,
            inspector_company: inspection.inspector_company&.name,
            unique_report_number: inspection.unique_report_number
          }
        end

        data[:total_inspections] = completed_inspections.count
        data[:last_inspection_date] = format_value(completed_inspections.first&.inspection_date)
        data[:last_inspection_passed] = completed_inspections.first&.passed
      end
    end

    base_url = ENV["BASE_URL"] || Rails.application.routes.default_url_options[:host] || "localhost:3000"
    data[:urls] = {
      report_pdf: "#{base_url}/units/#{unit.id}.pdf",
      report_json: "#{base_url}/units/#{unit.id}.json",
      qr_code: "#{base_url}/units/#{unit.id}.png"
    }

    data
  end

  def self.serialize_inspection(inspection)
    return nil unless inspection

    inspection_fields = Inspection.column_names - PublicFieldFiltering::EXCLUDED_FIELDS

    data = {}
    inspection_fields.each do |field|
      value = inspection.send(field)
      data[field.to_sym] = format_value(value) unless value.nil?
    end

    data[:complete] = inspection.complete?
    data[:passed] = inspection.passed? if inspection.complete?

    data[:inspector] = {
      name: inspection.user.name,
      rpii_inspector_number: inspection.user.rpii_inspector_number
    }

    base_url = ENV["BASE_URL"] || Rails.application.routes.default_url_options[:host] || "localhost:3000"
    data[:urls] = {
      report_pdf: "#{base_url}/inspections/#{inspection.id}.pdf",
      report_json: "#{base_url}/inspections/#{inspection.id}.json",
      qr_code: "#{base_url}/inspections/#{inspection.id}.png"
    }

    if inspection.unit
      data[:unit] = {
        id: inspection.unit.id,
        name: inspection.unit.name,
        serial: inspection.unit.serial,
        manufacturer: inspection.unit.manufacturer,
        operator: inspection.unit.operator
      }
    end

    assessments = {}

    inspection.each_applicable_assessment do |assessment_key, assessment_class, assessment|
      if assessment
        assessments[assessment_key] = serialize_assessment(assessment, assessment_class)
      end
    end

    data[:assessments] = assessments

    data
  end

  def self.serialize_assessment(assessment, klass)
    assessment_fields = klass.column_names - PublicFieldFiltering::EXCLUDED_FIELDS

    data = {}
    assessment_fields.each do |field|
      value = assessment.send(field)
      data[field.to_sym] = format_value(value) unless value.nil?
    end

    data
  end
end
