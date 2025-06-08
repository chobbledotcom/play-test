class InspectionsController < ApplicationController
  before_action :set_inspection, only: [:show, :edit, :update, :destroy, :report, :qr_code, :replace_dimensions]
  before_action :check_inspection_owner, only: [:show, :edit, :update, :destroy, :replace_dimensions]
  before_action :check_inspection_finalized, only: [:edit, :update, :replace_dimensions]
  before_action :check_inspection_finalized_for_delete, only: [:destroy]
  before_action :check_inspection_complete, only: [:report, :qr_code]
  before_action :no_index
  skip_before_action :require_login, only: [:report, :qr_code]

  def index
    @inspections = current_user.inspections.order(created_at: :desc)
    @title = "Inspections"

    respond_to do |format|
      format.html
      format.csv { send_data inspections_to_csv, filename: "inspections-#{Date.today}.csv" }
    end
  end

  def show
  end

  def new
    unless current_user.inspection_company_id.present?
      flash[:danger] = current_user.inspection_company_required_message
      redirect_to root_path and return
    end

    unless current_user.can_create_inspection?
      flash[:danger] = current_user.inspection_company_required_message
      redirect_to inspections_path and return
    end

    @inspection = Inspection.new
    @inspection.inspection_date = Date.today

    # Handle pre-selected unit
    if params[:unit_id].present?
      unit = current_user.units.find_by(id: params[:unit_id])
      if unit
        @inspection.unit_id = unit.id
      end
    end
  end

  def create
    # Handle unit_id from URL parameter (from unit show page button)
    unit_id = params[:unit_id] || inspection_params[:unit_id]
    unit = nil

    unless current_user.inspection_company_id.present?
      flash[:danger] = current_user.inspection_company_required_message
      redirect_to unit_id.present? ? unit_path(unit_id) : root_path and return
    end

    unless current_user.can_create_inspection?
      flash[:danger] = current_user.inspection_company_required_message
      redirect_to unit_id.present? ? unit_path(unit_id) : root_path and return
    end

    if unit_id.present?
      # Securely handle unit association
      unit = current_user.units.find_by(id: unit_id)
      if unit.nil?
        flash[:danger] = I18n.t("inspections.errors.invalid_unit")
        redirect_to root_path and return
      end
    end

    # Create minimal inspection with just the unit and default values
    @inspection = current_user.inspections.build(
      unit: unit,
      inspection_date: Date.current,
      status: "draft",
      inspector_company_id: current_user.inspection_company_id
    )

    # Copy dimensions from unit before saving
    @inspection.send(:copy_unit_values)

    if @inspection.save
      if Rails.env.production?
        NtfyService.notify("new inspection by #{current_user.email}")
      end

      flash[:success] = if unit.nil?
        I18n.t("inspections.messages.created_without_unit")
      else
        I18n.t("inspections.messages.created")
      end
      redirect_to edit_inspection_path(@inspection)
    else
      flash[:danger] = I18n.t("inspections.errors.creation_failed", errors: @inspection.errors.full_messages.join(", "))
      redirect_to unit.present? ? unit_path(unit) : root_path
    end
  end

  def edit
    # Build assessments if they don't exist yet and pre-fill with inspection dimensions
    unless @inspection.user_height_assessment
      @inspection.build_user_height_assessment(
        containing_wall_height: @inspection.containing_wall_height,
        platform_height: @inspection.platform_height,
        user_height: @inspection.user_height,
        permanent_roof: @inspection.permanent_roof,
        users_at_1000mm: @inspection.users_at_1000mm,
        users_at_1200mm: @inspection.users_at_1200mm,
        users_at_1500mm: @inspection.users_at_1500mm,
        users_at_1800mm: @inspection.users_at_1800mm,
        play_area_length: @inspection.play_area_length,
        play_area_width: @inspection.play_area_width,
        negative_adjustment: @inspection.negative_adjustment
      )
    end

    unless @inspection.slide_assessment
      @inspection.build_slide_assessment(
        slide_platform_height: @inspection.slide_platform_height,
        slide_wall_height: @inspection.slide_wall_height,
        runout_value: @inspection.runout_value,
        slide_first_metre_height: @inspection.slide_first_metre_height,
        slide_beyond_first_metre_height: @inspection.slide_beyond_first_metre_height,
        slide_permanent_roof: @inspection.slide_permanent_roof
      )
    end

    unless @inspection.structure_assessment
      @inspection.build_structure_assessment(
        stitch_length: @inspection.stitch_length,
        unit_pressure_value: @inspection.unit_pressure_value,
        blower_tube_length: @inspection.blower_tube_length,
        step_size_value: @inspection.step_size_value,
        fall_off_height_value: @inspection.fall_off_height_value,
        trough_depth_value: @inspection.trough_depth_value,
        trough_width_value: @inspection.trough_width_value
      )
    end

    unless @inspection.anchorage_assessment
      @inspection.build_anchorage_assessment(
        num_low_anchors: @inspection.num_low_anchors,
        num_high_anchors: @inspection.num_high_anchors
      )
    end

    unless @inspection.materials_assessment
      @inspection.build_materials_assessment(
        rope_size: @inspection.rope_size
      )
    end

    unless @inspection.fan_assessment
      @inspection.build_fan_assessment
    end

    unless @inspection.enclosed_assessment
      @inspection.build_enclosed_assessment(
        exit_number: @inspection.exit_number
      )
    end
  end

  def update
    params = inspection_params

    # Securely handle unit association
    if params[:unit_id].present?
      unit = current_user.units.find_by(id: params[:unit_id])

      if unit.nil?
        # Unit ID not found or doesn't belong to user - security issue
        flash[:danger] = "Invalid unit selection"
        render :edit, status: :unprocessable_entity and return
      end
    end

    if @inspection.update(params)
      respond_to do |format|
        format.html do
          flash[:success] = I18n.t("inspections.messages.updated")
          redirect_to @inspection
        end
        format.json { render json: {status: "success", message: t("inspections.autosave.saved")} }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("inspection_progress_#{@inspection.id}",
              html: "<span class='value'>#{helpers.assessment_completion_percentage(@inspection)}%</span>"),
            turbo_stream.replace("finalization_issues_#{@inspection.id}",
              partial: "inspections/finalization_issues",
              locals: {inspection: @inspection})
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: {status: "error", errors: @inspection.errors.full_messages} }
        format.turbo_stream do
          # For now, just update the progress and issues on error too
          render turbo_stream: [
            turbo_stream.replace("inspection_progress_#{@inspection.id}",
              html: "<span class='value'>#{helpers.assessment_completion_percentage(@inspection)}%</span>"),
            turbo_stream.replace("autosave_status",
              html: "<div class='error' style='display: inline;'>Save failed</div>")
          ]
        end
      end
    end
  end

  def destroy
    @inspection.destroy
    flash[:success] = I18n.t("inspections.messages.deleted")
    redirect_to inspections_path
  end

  def replace_dimensions
    if @inspection.unit.present?
      @inspection.copy_dimensions_from(@inspection.unit)

      if @inspection.save
        flash[:success] = t("inspections.messages.dimensions_replaced")
      else
        flash[:danger] = t("inspections.messages.dimensions_replace_failed", errors: @inspection.errors.full_messages.join(", "))
      end
    else
      flash[:danger] = t("inspections.messages.no_unit_for_dimensions")
    end

    redirect_to edit_inspection_path(@inspection, tab: params[:tab] || "general")
  end

  def search
    @inspections = params[:query].present? ?
      current_user.inspections.search(params[:query]) :
      current_user.inspections
  end

  def overdue
    @inspections = current_user.inspections.overdue.order(created_at: :desc)
    @title = "Overdue Inspections"
    render :index
  end

  def report
    pdf_data = PdfGeneratorService.generate_inspection_report(@inspection)

    @inspection.update(pdf_last_accessed_at: Time.current)

    send_data pdf_data.render,
      filename: "PAT_Report_#{@inspection.serial}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def qr_code
    qr_code_png = QrCodeService.generate_qr_code(@inspection)

    send_data qr_code_png,
      filename: "PAT_Report_QR_#{@inspection.serial}.png",
      type: "image/png",
      disposition: "inline"
  end

  private

  def inspection_params
    # Get the base params with permitted top-level attributes
    base_params = params.require(:inspection).permit(
      :inspection_date, :inspection_location, :passed, :comments, :unit_id,
      :inspector_company_id, :unique_report_number, :status, :has_slide,
      # Dimension comment fields
      :width_comment, :length_comment, :height_comment,
      :num_low_anchors_comment, :num_high_anchors_comment,
      :exit_number_comment, :rope_size_comment,
      :slide_platform_height_comment, :slide_wall_height_comment, :runout_value_comment,
      :slide_first_metre_height_comment, :slide_beyond_first_metre_height_comment,
      :slide_permanent_roof_comment,
      :containing_wall_height_comment, :platform_height_comment,
      :permanent_roof_comment, :play_area_length_comment, :play_area_width_comment,
      :negative_adjustment_comment
    )

    # For each assessment, permit all attributes except timestamps and inspection_id
    assessment_types = %w[
      user_height_assessment
      slide_assessment
      structure_assessment
      anchorage_assessment
      materials_assessment
      fan_assessment
      enclosed_assessment
    ]

    assessment_types.each do |assessment_type|
      next unless params[:inspection]["#{assessment_type}_attributes"].present?

      # Permit all fields except the ones we want to block
      assessment_params = params[:inspection]["#{assessment_type}_attributes"]
      cleaned_params = assessment_params.permit!.except("created_at", "updated_at", "inspection_id")

      base_params["#{assessment_type}_attributes"] = cleaned_params
    end

    base_params
  end

  def no_index
    response.set_header("X-Robots-Tag", "noindex,nofollow")
  end

  def set_inspection
    # Try exact match first, then case-insensitive match for user-friendly URLs
    @inspection = Inspection.find_by(id: params[:id]) ||
      Inspection.find_by("UPPER(id) = ?", params[:id].upcase)

    unless @inspection
      if action_name.in?(["report", "qr_code"])
        # For public report access, return 404 instead of redirect
        render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
      else
        flash[:danger] = "Inspection record not found"
        redirect_to inspections_path and return
      end
    end
  end

  def check_inspection_owner
    unless @inspection.user_id == current_user.id
      flash[:danger] = "Access denied"
      redirect_to inspections_path and return
    end
  end

  def inspections_to_csv
    attributes = %w[id name serial inspection_date reinspection_date inspector location passed comments manufacturer]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      current_user.inspections.order(created_at: :desc).each do |inspection|
        row = attributes.map { |attr| inspection.send(attr) }
        csv << row
      end
    end
  end

  def check_inspection_complete
    unless @inspection.status == "completed" || @inspection.status == "finalized"
      render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
    end
  end

  def check_inspection_finalized
    if @inspection.status == "finalized" && !current_user.admin?
      flash[:danger] = I18n.t("inspections.errors.finalized_no_edit")
      redirect_to inspection_path(@inspection)
    end
  end

  def check_inspection_finalized_for_delete
    if @inspection.status == "finalized" && !current_user.admin?
      flash[:danger] = I18n.t("inspections.errors.finalized_no_delete")
      redirect_to inspection_path(@inspection)
    end
  end
end
