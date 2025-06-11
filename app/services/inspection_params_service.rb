class InspectionParamsService
  INSPECTION_SPECIFIC_PARAMS = %i[
    inspection_date inspection_location passed comments unit_id
    inspector_company_id unique_report_number
  ].freeze

  ASSESSMENT_TYPES = %w[
    user_height_assessment slide_assessment structure_assessment
    anchorage_assessment materials_assessment fan_assessment
    enclosed_assessment
  ].freeze

  SYSTEM_ATTRIBUTES = %w[inspection_id created_at updated_at].freeze

  def initialize(params)
    @params = params
  end

  def permitted_params
    base_params = build_base_params
    add_assessment_params(base_params)
    base_params
  end

  private

  def build_base_params
    copyable_attributes = Inspection.new.copyable_attributes_via_reflection
    permitted_attributes = INSPECTION_SPECIFIC_PARAMS + copyable_attributes
    @params.require(:inspection).permit(*permitted_attributes)
  end

  def add_assessment_params(base_params)
    ASSESSMENT_TYPES.each do |assessment_type|
      assessment_key = "#{assessment_type}_attributes"
      next unless @params[:inspection][assessment_key].present?

      permitted_attrs = assessment_permitted_attributes(assessment_type)
      next unless permitted_attrs.any?

      base_params[assessment_key] = @params[:inspection][assessment_key].permit(*permitted_attrs)
    end
  end

  def assessment_permitted_attributes(assessment_type)
    model_class = assessment_type.camelize.constantize
    all_attributes = model_class.column_names
    (all_attributes - SYSTEM_ATTRIBUTES).map { it.to_sym }
  rescue NameError
    []
  end
end
