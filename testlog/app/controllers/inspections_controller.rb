class InspectionsController < ApplicationController
  before_action :set_inspection, except: [:index, :search, :overdue, :create]
  before_action :check_inspection_owner, except: [:index, :search, :overdue, :create, :report, :qr_code]
  before_action :redirect_if_complete, except: [:show, :mark_draft, :report, :qr_code, :index, :search, :overdue, :create, :destroy]
  before_action :no_index
  skip_before_action :require_login, only: [:report, :qr_code]

  def index
    # Base filtered query
    filtered_inspections = current_user.inspections
      .search(params[:query])
      .filter_by_result(params[:result])
      .filter_by_unit(params[:unit_id])
      .order(created_at: :desc)

    # Split into draft and complete
    @draft_inspections = filtered_inspections.draft
    @complete_inspections = filtered_inspections.complete

    @title = build_index_title

    respond_to do |format|
      format.html
      format.csv { send_data inspections_to_csv, filename: "inspections-#{Date.today}.csv" }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        pdf_data = PdfGeneratorService.generate_inspection_report(@inspection)
        @inspection.update(pdf_last_accessed_at: Time.current)

        send_data pdf_data.render,
          filename: "PAT_Report_#{@inspection.serial}.pdf",
          type: "application/pdf",
          disposition: "inline"
      end
    end
  end

  def new
    unless current_user.inspection_company_id.present?
      flash[:alert] = current_user.inspection_company_required_message
      redirect_to root_path and return
    end

    unless current_user.can_create_inspection?
      flash[:alert] = current_user.inspection_company_required_message
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
      flash[:alert] = current_user.inspection_company_required_message
      redirect_to unit_id.present? ? unit_path(unit_id) : root_path and return
    end

    unless current_user.can_create_inspection?
      flash[:alert] = current_user.inspection_company_required_message
      redirect_to unit_id.present? ? unit_path(unit_id) : root_path and return
    end

    if unit_id.present?
      # Securely handle unit association
      unit = current_user.units.find_by(id: unit_id)
      if unit.nil?
        flash[:alert] = I18n.t("inspections.errors.invalid_unit")
        redirect_to root_path and return
      end
    end

    # Create minimal inspection with just the unit and default values
    @inspection = current_user.inspections.build(
      unit: unit,
      inspection_date: Date.current,
      status: "draft",
      inspector_company_id: current_user.inspection_company_id,
      inspection_location: current_user.default_inspection_location
    )

    # Copy dimensions from unit before saving
    @inspection.send(:copy_unit_values)

    if @inspection.save
      if Rails.env.production?
        NtfyService.notify("new inspection by #{current_user.email}")
      end

      flash[:notice] = if unit.nil?
        I18n.t("inspections.messages.created_without_unit")
      else
        I18n.t("inspections.messages.created")
      end
      redirect_to edit_inspection_path(@inspection)
    else
      flash[:alert] = I18n.t("inspections.errors.creation_failed", errors: @inspection.errors.full_messages.join(", "))
      redirect_to unit.present? ? unit_path(unit) : root_path
    end
  end

  def edit
    # Build assessments if they don't exist yet and pre-fill with inspection attributes
    @inspection.build_assessments_with_attributes
  end

  def update
    params = inspection_params

    # Securely handle unit association
    if params[:unit_id].present?
      unit = current_user.units.find_by(id: params[:unit_id])

      if unit.nil?
        # Unit ID not found or doesn't belong to user - security issue
        flash[:alert] = I18n.t("inspections.errors.invalid_unit")
        render :edit, status: :unprocessable_entity and return
      end
    end

    if @inspection.update(params)
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t("inspections.messages.updated")
          redirect_to @inspection
        end
        format.json { render json: {status: "success", message: t("inspections.autosave.saved")} }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("inspection_progress_#{@inspection.id}",
              html: "<span class='value'>#{helpers.assessment_completion_percentage(@inspection)}%</span>"),
            turbo_stream.replace("completion_issues_#{@inspection.id}",
              partial: "inspections/completion_issues",
              locals: {inspection: @inspection}),
            turbo_stream.replace("inspection_save_message",
              partial: "shared/save_message",
              locals: {
                dom_id: "inspection_save_message",
                success: true,
                success_message: t("inspections.messages.updated")
              }),
            turbo_stream.replace("assessment_save_message",
              partial: "shared/save_message",
              locals: {
                dom_id: "assessment_save_message",
                success: true,
                success_message: t("inspections.messages.updated")
              })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: {status: "error", errors: @inspection.errors.full_messages} }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("inspection_progress_#{@inspection.id}",
              html: "<span class='value'>#{helpers.assessment_completion_percentage(@inspection)}%</span>"),
            turbo_stream.replace("completion_issues_#{@inspection.id}",
              partial: "inspections/completion_issues",
              locals: {inspection: @inspection}),
            turbo_stream.replace("inspection_save_message",
              partial: "shared/save_message",
              locals: {
                dom_id: "inspection_save_message",
                errors: @inspection.errors.full_messages,
                error_message: t("shared.messages.save_failed")
              }),
            turbo_stream.replace("assessment_save_message",
              partial: "shared/save_message",
              locals: {
                dom_id: "assessment_save_message",
                errors: @inspection.errors.full_messages,
                error_message: t("shared.messages.save_failed")
              })
          ]
        end
      end
    end
  end

  def destroy
    if @inspection.status == "complete" && !current_user.admin?
      redirect_to @inspection.preferred_path, alert: I18n.t("inspections.messages.delete_complete_denied")
      return
    end

    @inspection.destroy
    redirect_to inspections_path, notice: I18n.t("inspections.messages.deleted")
  end

  def replace_dimensions
    if @inspection.unit.present?
      @inspection.copy_attributes_from(@inspection.unit)

      if @inspection.save
        flash[:notice] = t("inspections.messages.dimensions_replaced")
      else
        flash[:alert] = t("inspections.messages.dimensions_replace_failed", errors: @inspection.errors.full_messages.join(", "))
      end
    else
      flash[:alert] = t("inspections.messages.no_unit_for_dimensions")
    end

    redirect_to edit_inspection_path(@inspection, tab: params[:tab] || "general")
  end

  def select_unit
    @units = current_user.units
    @title = t("inspections.titles.select_unit")

    # Apply the same filters as the units index
    if params[:search].present?
      @units = @units.where("name LIKE ? OR serial LIKE ? OR manufacturer LIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    if params[:manufacturer].present?
      @units = @units.where(manufacturer: params[:manufacturer])
    end

    if params[:has_slide].present?
      @units = @units.where(has_slide: params[:has_slide] == "true")
    end

    @units = @units.order(:name)

    render :select_unit
  end

  def update_unit
    unit = current_user.units.find_by(id: params[:unit_id])

    if unit.nil?
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
      flash[:alert] = t("inspections.messages.unit_change_failed", errors: @inspection.errors.full_messages.join(", "))
      redirect_to select_unit_inspection_path(@inspection)
    end
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

  def complete
    # Check if inspection can be completed
    validation_errors = @inspection.validate_completeness

    if validation_errors.any?
      flash[:alert] = t("inspections.messages.cannot_complete", errors: validation_errors.join(", "))
      redirect_to edit_inspection_path(@inspection)
      return
    end

    begin
      @inspection.complete!(current_user)
      flash[:notice] = t("inspections.messages.marked_complete")
      redirect_to @inspection
    rescue => e
      flash[:alert] = t("inspections.messages.completion_failed", error: e.message)
      redirect_to edit_inspection_path(@inspection)
    end
  end

  def mark_draft
    if @inspection.update(status: "draft")
      flash[:notice] = t("inspections.messages.marked_draft")
    else
      flash[:alert] = t("inspections.messages.mark_draft_failed", errors: @inspection.errors.full_messages.join(", "))
    end
    redirect_to edit_inspection_path(@inspection)
  end

  private

  def inspection_params
    # Get the base params with permitted top-level attributes
    inspection_specific_params = [:inspection_date, :inspection_location, :passed, :comments, :unit_id, :inspector_company_id, :unique_report_number]
    base_params = params.require(:inspection).permit(inspection_specific_params + Inspection::PERMITTED_COPYABLE_ATTRIBUTES)

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
        flash[:alert] = I18n.t("inspections.errors.not_found")
        redirect_to inspections_path and return
      end
    end
  end

  def check_inspection_owner
    unless @inspection.user_id == current_user.id
      flash[:alert] = I18n.t("inspections.errors.access_denied")
      redirect_to inspections_path and return
    end
  end

  def redirect_if_complete
    if @inspection&.status == "complete"
      flash[:notice] = I18n.t("inspections.messages.cannot_edit_complete")
      redirect_to @inspection and return
    end
  end

  def inspections_to_csv
    CSV.generate(headers: true) do |csv|
      # Get headers dynamically
      headers = csv_headers
      csv << headers

      # Export whatever inspections are already filtered by the index action
      @complete_inspections.includes(:unit, :inspector_company, :user).each do |inspection|
        csv << csv_row_data(inspection, headers)
      end
    end
  end

  def csv_headers
    headers = []

    # All inspection column names (excluding foreign keys we'll handle specially)
    excluded_columns = %w[user_id inspector_company_id unit_id]
    inspection_columns = Inspection.column_names - excluded_columns
    headers += inspection_columns

    # Related model data with prefixes
    headers += %w[unit_name unit_serial unit_manufacturer unit_owner unit_description]
    headers += %w[inspector_company_name]
    headers += %w[inspector_user_email]

    headers
  end

  def csv_row_data(inspection, headers)
    headers.map do |header|
      case header
      # Unit fields
      when "unit_name" then inspection.unit&.name
      when "unit_serial" then inspection.unit&.serial
      when "unit_manufacturer" then inspection.unit&.manufacturer
      when "unit_owner" then inspection.unit&.owner
      when "unit_description" then inspection.unit&.description

      # Inspector company
      when "inspector_company_name" then inspection.inspector_company&.name

      # User (inspector) fields
      when "inspector_user_email" then inspection.user&.email

      # All other fields are direct inspection attributes
      else
        inspection.send(header) if inspection.respond_to?(header)
      end
    end
  end

  def build_index_title
    title = "Inspections"
    title += " - #{(params[:result] == "passed") ? "Passed" : "Failed"}" if params[:result].present?
    title
  end
end
