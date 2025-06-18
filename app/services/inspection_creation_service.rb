class InspectionCreationService
  def initialize(user, params = {})
    @user = user
    @unit_id = params[:unit_id]
  end

  def create
    unit = find_and_validate_unit if @unit_id.present?
    return invalid_unit_result if @unit_id.present? && unit.nil?

    inspection = build_inspection(unit)

    if inspection.save
      notify_if_production(inspection)
      success_result(inspection, unit)
    else
      failure_result(inspection)
    end
  end

  private

  def find_and_validate_unit
    @user.units.find_by(id: @unit_id)
  end

  def build_inspection(unit)
    @user.inspections.build(
      unit: unit,
      inspection_date: Date.current,
      inspector_company_id: @user.inspection_company_id,
      inspection_location: @user.default_inspection_location
    )
  end

  def notify_if_production(inspection)
    return unless Rails.env.production?
    NtfyService.notify("new inspection by #{@user.email}")
  end


  def invalid_unit_result
    {
      success: false,
      error_type: :invalid_unit,
      message: I18n.t("inspections.errors.invalid_unit"),
      redirect_path: "/"
    }
  end

  def success_result(inspection, unit)
    {
      success: true,
      inspection: inspection,
      message: unit.nil? ? I18n.t("inspections.messages.created_without_unit") : I18n.t("inspections.messages.created"),
      redirect_path: "/inspections/#{inspection.id}/edit"
    }
  end

  def failure_result(inspection)
    error_messages = inspection.errors.full_messages.join(", ")
    {
      success: false,
      error_type: :validation_failed,
      message: I18n.t("inspections.errors.creation_failed", errors: error_messages),
      redirect_path: inspection.unit.present? ? "/units/#{inspection.unit.id}" : "/"
    }
  end
end
