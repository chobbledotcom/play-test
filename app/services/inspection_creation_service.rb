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

  COPY_FROM_LAST_INSPECTION_FIELDS = %i[
    has_slide
    is_totally_enclosed
    length
    width
    height
  ]

  def build_inspection(unit)
    last_inspection = unit&.last_inspection
    copy_fields = {}
    if last_inspection
      copy_fields = COPY_FROM_LAST_INSPECTION_FIELDS.map do |field|
        [field, last_inspection.send(field)]
      end.to_h
    end

    @user.inspections.build(
      unit: unit,
      inspection_date: Date.current,
      inspector_company_id: @user.inspection_company_id,
      **copy_fields
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
    message_key = unit.nil? ? "created_without_unit" : "created"
    {
      success: true,
      inspection: inspection,
      message: I18n.t("inspections.messages.#{message_key}"),
      redirect_path: "/inspections/#{inspection.id}/edit"
    }
  end

  def failure_result(inspection)
    error_messages = inspection.errors.full_messages.join(", ")
    redirect_path = build_failure_redirect_path(inspection)

    {
      success: false,
      error_type: :validation_failed,
      message: I18n.t("inspections.errors.creation_failed",
        errors: error_messages),
      redirect_path: redirect_path
    }
  end

  def build_failure_redirect_path(inspection)
    inspection.unit.present? ? "/units/#{inspection.unit.id}" : "/"
  end
end
