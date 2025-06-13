module AssessmentController
  extend ActiveSupport::Concern
  include UserActivityCheck

  included do
    before_action :set_inspection
    before_action :check_inspection_owner
    before_action :require_user_active
    before_action :set_assessment
  end

  def update
    if @assessment.update(assessment_params)
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t("inspections.messages.updated")
          redirect_to @inspection
        end
        format.json { render json: {status: I18n.t("shared.api.success"), inspection: @inspection} }
        format.turbo_stream { render_save_message(I18n.t("inspections.messages.updated")) }
      end
    else
      respond_to do |format|
        format.html do
          # Set the correct tab for the edit view
          params[:tab] = assessment_type
          # Ensure the inspection has the assessment with errors
          @inspection.association(assessment_association).target = @assessment
          # Load necessary data for the edit view
          load_inspection_locations
          render "inspections/edit", status: :unprocessable_entity
        end
        format.json { render json: {errors: @assessment.errors}, status: :unprocessable_entity }
        format.turbo_stream { render_error_message(@assessment.errors.full_messages.join(", ")) }
      end
    end
  end

  private

  def set_inspection
    @inspection = Inspection
      .includes(
        :user,
        :inspector_company,
        :unit,
        :anchorage_assessment,
        :user_height_assessment,
        :slide_assessment,
        :structure_assessment,
        :materials_assessment,
        :fan_assessment,
        :enclosed_assessment
      )
      .find(params[:inspection_id])
  end

  def check_inspection_owner
    return if @inspection.user == current_user

    respond_to do |format|
      format.html do
        flash[:alert] = I18n.t("inspections.errors.access_denied")
        redirect_to inspections_path
      end
      format.json { render json: {error: I18n.t("inspections.errors.access_denied")}, status: :forbidden }
      format.turbo_stream { render_error_message(I18n.t("inspections.errors.access_denied")) }
    end
  end

  def set_assessment
    @assessment = @inspection.send(assessment_association)
  end

  # This method must be implemented by including controllers
  def assessment_params
    raise NotImplementedError, "#{self.class.name} must implement #assessment_params"
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
    # e.g. "MaterialsAssessmentsController" -> MaterialsAssessment
    controller_name.singularize.camelize.constantize
  end

  def load_inspection_locations
    # This is needed when rendering the inspections/edit view
    # For now, just set an empty array since we're only editing one inspection
    @inspection_locations = []
  end

  def render_save_message(message, type: "success")
    render turbo_stream: turbo_stream.replace("form_save_message",
      partial: "shared/save_message",
      locals: {message: message, type: type})
  end

  def render_error_message(message)
    render_save_message(message, type: "error")
  end
end
