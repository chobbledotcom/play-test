module AssessmentController
  extend ActiveSupport::Concern
  include UserActivityCheck
  include InspectionTurboStreams

  included do
    before_action :set_inspection
    before_action :check_inspection_owner
    before_action :require_user_active
    before_action :set_assessment
    before_action :set_previous_inspection
  end

  def update
    if @assessment.update(assessment_params)
      @assessment.reload  # Ensure we have fresh data for turbo streams
      handle_successful_update
    else
      handle_failed_update
    end
  end

  private

  def handle_successful_update
    respond_to do |format|
      format.html do
        flash[:notice] = I18n.t("inspections.messages.updated")
        redirect_to @inspection
      end
      format.json do
        success_response = {
          status: I18n.t("shared.api.success"),
          inspection: @inspection
        }
        render json: success_response
      end
      format.turbo_stream { render turbo_stream: success_turbo_streams }
    end
  end

  def handle_failed_update
    respond_to do |format|
      format.html { render_edit_with_errors }
      format.json do
        render json: {errors: @assessment.errors}, status: :unprocessable_entity
      end
      format.turbo_stream { render turbo_stream: error_turbo_streams }
    end
  end

  def render_edit_with_errors
    params[:tab] = assessment_type
    @inspection.association(assessment_association).target = @assessment
    load_inspection_locations
    render "inspections/edit", status: :unprocessable_entity
  end

  def set_inspection
    @inspection = Inspection
      .includes(
        :user,
        :inspector_company,
        :unit,
        *Inspection::ASSESSMENT_TYPES.keys
      )
      .find(params[:inspection_id])
  end

  def check_inspection_owner
    head :not_found unless @inspection.user == current_user
  end

  def set_assessment
    @assessment = @inspection.send(assessment_association)
  end

  # Default implementation that permits all attributes except sensitive ones
  # Can be overridden in including controllers if needed
  def assessment_params
    params.require(param_key).permit(permitted_attributes)
  end

  def param_key
    # e.g. "FanAssessmentsController" -> :assessments_fan_assessment
    :"assessments_#{controller_name.singularize}"
  end

  def permitted_attributes
    # Get all attributes except sensitive ones
    excluded_attrs = %w[id inspection_id created_at updated_at]
    assessment_class.attribute_names - excluded_attrs
  end

  # Automatically derive from controller name
  def assessment_association
    # e.g. "MaterialsAssessmentsController" -> "materials_assessment"
    controller_name.singularize
  end

  # Automatically derive from controller name
  def assessment_type
    # e.g. "MaterialsAssessmentsController" -> "materials"
    controller_name.singularize.sub(/_assessment$/, "")
  end

  # Automatically derive from controller name
  def assessment_class
    # e.g. "MaterialsAssessmentsController" -> Assessments::MaterialsAssessment
    "Assessments::#{controller_name.singularize.camelize}".constantize
  end

  def load_inspection_locations
    @inspection_locations = []
  end

  def set_previous_inspection
    return unless @inspection.unit

    @previous_inspection = @inspection.unit.last_inspection
  end

  def handle_inactive_user_redirect
    redirect_to edit_inspection_path(@inspection)
  end
end
