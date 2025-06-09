class JsonSerializerService
  def self.serialize_unit(unit, include_inspections: true)
    return nil unless unit

    # Use reflection to get all columns except excluded ones
    unit_fields = Unit.column_names - PublicFieldFiltering::EXCLUDED_FIELDS - PublicFieldFiltering::UNIT_EXCLUDED_FIELDS

    data = {}
    unit_fields.each do |field|
      value = unit.send(field)
      data[field.to_sym] = value unless value.nil?
    end

    # Include inspection history if requested
    if include_inspections
      completed_inspections = unit.inspections.complete.order(inspection_date: :desc)

      if completed_inspections.any?
        data[:inspection_history] = completed_inspections.map do |inspection|
          {
            inspection_date: inspection.inspection_date,
            passed: inspection.passed,
            complete: inspection.complete?,
            inspector_company: inspection.inspector_company&.name,
            unique_report_number: inspection.unique_report_number,
            inspection_location: inspection.inspection_location
          }
        end

        data[:total_inspections] = completed_inspections.count
        data[:last_inspection_date] = completed_inspections.first&.inspection_date
        data[:last_inspection_passed] = completed_inspections.first&.passed
      end
    end

    # Add public URLs
    base_url = ENV["BASE_URL"] || Rails.application.routes.default_url_options[:host] || "localhost:3000"
    data[:urls] = {
      report_pdf: "#{base_url}/u/#{unit.id}",
      report_json: "#{base_url}/u/#{unit.id}.json",
      qr_code: "#{base_url}/units/#{unit.id}/qr_code"
    }

    data
  end

  def self.serialize_inspection(inspection, include_assessments: true)
    return nil unless inspection

    # Use reflection to get all columns except excluded ones
    inspection_fields = Inspection.column_names - PublicFieldFiltering::EXCLUDED_FIELDS

    data = {}
    inspection_fields.each do |field|
      value = inspection.send(field)
      data[field.to_sym] = value unless value.nil?
    end

    # Add computed complete field
    data[:complete] = inspection.complete?

    # Add inspector company info
    if inspection.inspector_company.present?
      data[:inspector_company] = {
        name: inspection.inspector_company.name,
        rpii_registration_number: inspection.inspector_company.rpii_registration_number
      }
    end

    # Add unit info if present
    if inspection.unit.present?
      data[:unit] = {
        id: inspection.unit.id,
        name: inspection.unit.name,
        serial_number: inspection.unit.serial_number || inspection.unit.serial,
        manufacturer: inspection.unit.manufacturer,
        owner: inspection.unit.owner,
        has_slide: inspection.unit.has_slide?,
        is_totally_enclosed: inspection.unit.is_totally_enclosed?
      }
    end

    # Include assessment data if requested
    if include_assessments
      assessments = {}

      # Assessment types to include
      assessment_types = {
        user_height_assessment: UserHeightAssessment,
        slide_assessment: SlideAssessment,
        structure_assessment: StructureAssessment,
        anchorage_assessment: AnchorageAssessment,
        materials_assessment: MaterialsAssessment,
        fan_assessment: FanAssessment,
        enclosed_assessment: EnclosedAssessment
      }

      assessment_types.each do |association_name, klass|
        assessment = inspection.send(association_name)
        next unless assessment

        # Skip slide assessment if unit doesn't have slide
        next if association_name == :slide_assessment && !inspection.unit&.has_slide?

        # Skip enclosed assessment if unit isn't totally enclosed
        next if association_name == :enclosed_assessment && !inspection.unit&.is_totally_enclosed?

        assessments[association_name] = serialize_assessment(assessment, klass)
      end

      data[:assessments] = assessments if assessments.any?
    end

    # Add public URLs
    base_url = ENV["BASE_URL"] || Rails.application.routes.default_url_options[:host] || "localhost:3000"
    data[:urls] = {
      report_pdf: "#{base_url}/r/#{inspection.id}",
      report_json: "#{base_url}/r/#{inspection.id}.json",
      qr_code: "#{base_url}/inspections/#{inspection.id}/qr_code"
    }

    data
  end

  def self.serialize_assessment(assessment, klass)
    # Get class-specific exclusions
    class_excluded = PublicFieldFiltering::ASSESSMENT_EXCLUDED_FIELDS[klass.name] || []
    all_excluded = PublicFieldFiltering::EXCLUDED_FIELDS + class_excluded

    # Use reflection to get fields
    assessment_fields = klass.column_names - all_excluded

    data = {}
    assessment_fields.each do |field|
      value = assessment.send(field)
      data[field.to_sym] = value unless value.nil?
    end

    data
  end
end
