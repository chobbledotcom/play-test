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
    unless current_user.can_create_inspection?
      flash[:danger] = "You have reached your inspection limit of #{current_user.inspection_limit}. Please contact an administrator."
      redirect_to inspections_path and return
    end

    @inspection = Inspection.new
    @inspection.inspection_date = Date.today
    @inspection.reinspection_date = Date.today + 1.year

    # Handle pre-selected unit
    if params[:unit_id].present?
      unit = current_user.units.find_by(id: params[:unit_id])
      if unit
        @inspection.unit_id = unit.id
        @inspection.name = unit.name
        @inspection.serial = unit.serial
        @inspection.location = unit.location
        @inspection.manufacturer = unit.manufacturer
      end
    end
  end

  def create
    unless current_user.can_create_inspection?
      flash[:danger] = "You have reached your inspection limit of #{current_user.inspection_limit}. Please contact an administrator."
      redirect_to inspections_path and return
    end

    params = inspection_params

    # Securely handle unit association - unit is now required
    if params[:unit_id].present?
      unit = current_user.units.find_by(id: params[:unit_id])

      if unit.nil?
        # Unit ID not found or doesn't belong to user - security issue
        flash[:danger] = "Invalid unit selection"
        @inspection = current_user.inspections.build
        render :new, status: :unprocessable_entity and return
      end
    else
      # Unit is required
      flash[:danger] = "Unit selection is required"
      @inspection = current_user.inspections.build
      render :new, status: :unprocessable_entity and return
    end

    @inspection = current_user.inspections.build(params)

    if @inspection.save
      if Rails.env.production?
        NtfyService.notify("new inspection by #{current_user.email}")
      end

      flash_and_redirect("created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
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
      :inspection_date, :reinspection_date, :inspector,
      :location, :passed, :comments, :unit_id, :place_inspected,
      :inspector_company_id, :rpii_registration_number,
      :unique_report_number, :inspection_company_name, :status
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
    flash[:success] = "Inspection record #{action}"
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
