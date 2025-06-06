class InspectionsController < ApplicationController
  before_action :set_inspection, only: [:show, :edit, :update, :destroy, :certificate, :qr_code]
  before_action :check_inspection_owner, only: [:show, :edit, :update, :destroy]
  before_action :no_index
  skip_before_action :require_login, only: [:certificate, :qr_code]

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
    unless current_user.inspection_company_id.present?
      flash[:danger] = current_user.inspection_company_required_message
      redirect_to root_path and return
    end

    unless current_user.can_create_inspection?
      flash[:danger] = current_user.inspection_company_required_message
      redirect_to root_path and return
    end

    # Handle unit_id from URL parameter (from unit show page button)
    unit_id = params[:unit_id] || inspection_params[:unit_id]

    unless unit_id.present?
      flash[:danger] = I18n.t("inspections.errors.unit_required")
      redirect_to root_path and return
    end

    # Securely handle unit association
    unit = current_user.units.find_by(id: unit_id)
    if unit.nil?
      flash[:danger] = I18n.t("inspections.errors.invalid_unit")
      redirect_to root_path and return
    end

    # Create minimal inspection with just the unit and default values
    @inspection = current_user.inspections.build(
      unit: unit,
      inspection_date: Date.current,
      status: "draft",
      inspector_company_id: current_user.inspection_company_id
    )

    if @inspection.save
      if Rails.env.production?
        NtfyService.notify("new inspection by #{current_user.email}")
      end

      flash[:success] = I18n.t("inspections.messages.created")
      redirect_to edit_inspection_path(@inspection)
    else
      flash[:danger] = I18n.t("inspections.errors.creation_failed", errors: @inspection.errors.full_messages.join(", "))
      redirect_to unit_path(unit)
    end
  end

  def edit
    # Build assessments if they don't exist yet
    @inspection.build_user_height_assessment unless @inspection.user_height_assessment
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
        format.html { flash_and_redirect("updated") }
        format.json { render json: {status: "success", message: t("inspections.autosave.saved")} }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: {status: "error", errors: @inspection.errors.full_messages} }
      end
    end
  end

  def destroy
    @inspection.destroy
    flash_and_redirect("deleted")
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

  def certificate
    pdf_data = PdfGeneratorService.generate_inspection_certificate(@inspection)

    @inspection.update(pdf_last_accessed_at: Time.current)

    send_data pdf_data.render,
      filename: "PAT_Certificate_#{@inspection.serial}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def qr_code
    qr_code_png = QrCodeService.generate_qr_code(@inspection)

    send_data qr_code_png,
      filename: "PAT_Certificate_QR_#{@inspection.serial}.png",
      type: "image/png",
      disposition: "inline"
  end

  private

  def inspection_params
    params.require(:inspection).permit(
      :inspection_date, :inspection_location, :passed, :comments, :unit_id,
      :inspector_company_id, :unique_report_number, :status,
      user_height_assessment_attributes: [
        :id, :containing_wall_height, :platform_height, :user_height, :permanent_roof,
        :users_at_1000mm, :users_at_1200mm, :users_at_1500mm, :users_at_1800mm,
        :play_area_length, :play_area_width, :negative_adjustment, :user_height_comment
      ]
    )
  end

  def no_index
    response.set_header("X-Robots-Tag", "noindex,nofollow")
  end

  def set_inspection
    # Try exact match first, then case-insensitive match for user-friendly URLs
    @inspection = Inspection.find_by(id: params[:id]) ||
      Inspection.find_by("UPPER(id) = ?", params[:id].upcase)

    unless @inspection
      if action_name.in?(["certificate", "qr_code"])
        # For public certificate access, return 404 instead of redirect
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

  def flash_and_redirect(action)
    flash[:success] = I18n.t("inspections.messages.#{action}")
    redirect_to (action == "deleted") ? inspections_path : @inspection
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
end
