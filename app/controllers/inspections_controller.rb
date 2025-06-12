class InspectionsController < ApplicationController
  include InspectionTurboStreams
  include PublicViewable

  skip_before_action :require_login, only: %i[show]
  before_action :set_inspection, except: %i[create index]
  before_action :check_inspection_owner, except: %i[create index show]
  before_action :validate_unit_ownership, only: %i[update]
  before_action :redirect_if_complete, except: %i[create destroy index mark_draft show]
  before_action :no_index

  def index
    # Load all inspections in one query to avoid N+1
    all_inspections = filtered_inspections_query_without_order.to_a

    # Partition into draft and complete in memory
    @draft_inspections = all_inspections
      .select { it.complete_date.nil? }
      .sort_by(&:created_at)

    @complete_inspections = all_inspections
      .select { it.complete_date.present? }
      .sort_by { -it.created_at.to_i }

    @title = build_index_title
    @has_any_inspections = all_inspections.any?
    load_inspection_locations

    respond_to do |format|
      format.html
      format.csv do
        csv_data = InspectionCsvExportService.new(@complete_inspections).generate
        send_data csv_data,
          filename: "inspections-#{Date.today}.csv"
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render_show_html }
      format.pdf { send_inspection_pdf }
      format.png { send_inspection_qr_code }
      format.json { render json: JsonSerializerService.serialize_inspection(@inspection) }
    end
  end

  def create
    unit_id = params[:unit_id] || inspection_params[:unit_id]

    result = InspectionCreationService.new(current_user, unit_id: unit_id).create

    if result[:success]
      flash[:notice] = result[:message]
      redirect_to edit_inspection_path(result[:inspection])
    else
      flash[:alert] = result[:message]
      redirect_to result[:redirect_path]
    end
  end

  def edit
    # Build assessments if they don't exist yet
    # and pre-fill with inspection attributes
    @inspection.build_assessments_with_attributes
    load_inspection_locations
  end

  def update
    if @inspection.update(inspection_params)
      handle_successful_update
    else
      handle_failed_update
    end
  end

  def destroy
    if @inspection.complete? && !current_user.admin?
      alert_message = I18n.t("inspections.messages.delete_complete_denied")
      redirect_to @inspection.preferred_path, alert: alert_message
      return
    end

    @inspection.destroy
    redirect_to inspections_path, notice: I18n.t("inspections.messages.deleted")
  end

  def replace_dimensions
    if @inspection.unit
      @inspection.copy_attributes_from(@inspection.unit)

      if @inspection.save
        flash[:notice] = t("inspections.messages.dimensions_replaced")
      else
        error_messages = @inspection.errors.full_messages.join(", ")
        flash[:alert] = t("inspections.messages.dimensions_replace_failed", errors: error_messages)
      end
    else
      flash[:alert] = t("inspections.messages.no_unit_for_dimensions")
    end

    tab_param = params[:tab] || "general"
    redirect_to edit_inspection_path(@inspection, tab: tab_param)
  end

  def select_unit
    @units = current_user.units
      .search(params[:search])
      .by_manufacturer(params[:manufacturer])
      .order(:name)
    @title = t("inspections.titles.select_unit")

    render :select_unit
  end

  def update_unit
    unit = current_user.units.find_by(id: params[:unit_id])

    unless unit
      flash[:alert] = t("inspections.errors.invalid_unit")
      redirect_to select_unit_inspection_path(@inspection) and return
    end

    # Update the inspection with the new unit and copy all dimensions
    @inspection.unit = unit
    @inspection.copy_attributes_from(unit)

    if @inspection.save
      flash[:notice] = t("inspections.messages.unit_changed", unit_name: unit.name)
      redirect_to edit_inspection_path(@inspection)
    else
      error_messages = @inspection.errors.full_messages.join(", ")
      flash[:alert] = t("inspections.messages.unit_change_failed", errors: error_messages)
      redirect_to select_unit_inspection_path(@inspection)
    end
  end

  def complete
    # Check if inspection can be completed
    validation_errors = @inspection.validate_completeness

    if validation_errors.any?
      error_list = validation_errors.join(", ")
      flash[:alert] = t("inspections.messages.cannot_complete", errors: error_list)
      redirect_to edit_inspection_path(@inspection)
      return
    end

    begin
      @inspection.complete!(current_user)
      flash[:notice] = t("inspections.messages.marked_complete")
      redirect_to @inspection
    rescue => e
      error_message = e.message
      flash[:alert] = t("inspections.messages.completion_failed", error: error_message)
      redirect_to edit_inspection_path(@inspection)
    end
  end

  def mark_draft
    if @inspection.update(complete_date: nil)
      flash[:notice] = t("inspections.messages.marked_in_progress")
    else
      error_messages = @inspection.errors.full_messages.join(", ")
      flash[:alert] = t("inspections.messages.mark_in_progress_failed", errors: error_messages)
    end
    redirect_to edit_inspection_path(@inspection)
  end

  private

  def filtered_inspections_query_without_order = current_user.inspections
    .includes(:unit, :inspector_company)
    .search(params[:query])
    .filter_by_result(params[:result])
    .filter_by_unit(params[:unit_id])
    .filter_by_owner(params[:owner])
    .filter_by_inspection_location(params[:inspection_location])

  def inspection_params = InspectionParamsService.new(params).permitted_params

  def no_index = response.set_header("X-Robots-Tag", "noindex,nofollow")

  def set_inspection
    @inspection = Inspection
      .includes(
        :user,
        :inspector_company,
        :anchorage_assessment,
        :enclosed_assessment,
        :fan_assessment,
        :materials_assessment,
        :slide_assessment,
        :structure_assessment,
        :user_height_assessment,
        unit: {photo_attachment: :blob}
      )
      .find_by(id: params[:id]&.upcase)

    unless @inspection
      # Always return 404 for non-existent resources regardless of login status
      head :not_found
    end
  end

  def check_inspection_owner
    return if current_user && @inspection.user_id == current_user.id

    flash[:alert] = I18n.t("inspections.errors.access_denied")
    redirect_to inspections_path
  end

  def redirect_if_complete
    return unless @inspection&.complete?

    flash[:notice] = I18n.t("inspections.messages.cannot_edit_complete")
    redirect_to @inspection
  end

  def build_index_title
    title = I18n.t("inspections.titles.index")
    return title unless params[:result]

    status = case params[:result]
    in "passed" then I18n.t("inspections.status.passed")
    in "failed" then I18n.t("inspections.status.failed")
    else params[:result]
    end
    "#{title} - #{status}"
  end

  def validate_unit_ownership
    return unless inspection_params[:unit_id]

    unit = current_user.units.find_by(id: inspection_params[:unit_id])
    return if unit

    # Unit ID not found or doesn't belong to user - security issue
    flash[:alert] = I18n.t("inspections.errors.invalid_unit")
    render :edit, status: :unprocessable_entity
  end

  def handle_successful_update
    respond_to do |format|
      format.html do
        flash[:notice] = I18n.t("inspections.messages.updated")
        redirect_to @inspection
      end
      format.json { render json: {status: I18n.t("shared.api.success"), inspection: @inspection} }
      format.turbo_stream { render turbo_stream: success_turbo_streams }
    end
  end

  def handle_failed_update
    respond_to do |format|
      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: {status: I18n.t("shared.api.error"), errors: @inspection.errors.full_messages} }
      format.turbo_stream { render turbo_stream: error_turbo_streams }
    end
  end

  def send_inspection_pdf
    pdf_data = PdfGeneratorService.generate_inspection_report(@inspection)
    @inspection.update(pdf_last_accessed_at: Time.current)

    send_data pdf_data.render,
      filename: "#{@inspection.unit&.serial || @inspection.id}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def send_inspection_qr_code
    qr_code_png = QrCodeService.generate_qr_code(@inspection)

    send_data qr_code_png,
      filename: "#{@inspection.unit&.serial || @inspection.id}_QR.png",
      type: "image/png",
      disposition: "inline"
  end

  # PublicViewable implementation
  def check_resource_owner
    check_inspection_owner
  end

  def owns_resource?
    @inspection && current_user && @inspection.user_id == current_user.id
  end

  def pdf_filename
    "#{@inspection.unit&.serial || @inspection.id}.pdf"
  end

  def resource_pdf_url
    inspection_path(@inspection, format: :pdf)
  end

  def load_inspection_locations
    # Use already loaded inspections to avoid extra query
    all_inspections = (@draft_inspections || []) + (@complete_inspections || [])
    @inspection_locations = all_inspections
      .map(&:inspection_location)
      .compact
      .reject(&:blank?)
      .uniq
      .sort
  end
end

