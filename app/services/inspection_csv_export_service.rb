class InspectionCsvExportService
  def initialize(inspections)
    @inspections = inspections
  end

  def generate
    CSV.generate(headers: true) do |csv|
      csv << headers

      @inspections.each do |inspection|
        csv << row_data(inspection)
      end
    end
  end

  private

  def headers
    # All inspection column names (excluding foreign keys we'll handle specially)
    excluded_columns = %w[user_id inspector_company_id unit_id]
    inspection_columns = Inspection.column_names - excluded_columns

    # Build comprehensive header list
    headers = inspection_columns
    headers += %w[unit_name unit_serial unit_manufacturer unit_operator unit_description]
    headers += %w[inspector_company_name]
    headers += %w[inspector_user_email]
    headers += %w[complete]

    headers
  end

  def row_data(inspection)
    headers.map do |header|
      case header
      in "unit_name" then inspection.unit&.name
      in "unit_serial" then inspection.unit&.serial
      in "unit_manufacturer" then inspection.unit&.manufacturer
      in "unit_operator" then inspection.unit&.operator
      in "unit_description" then inspection.unit&.description
      in "inspector_company_name" then inspection.inspector_company&.name
      in "inspector_user_email" then inspection.user&.email
      in "complete" then inspection.complete?
      else inspection.send(header) if inspection.respond_to?(header)
      end
    end
  end
end
