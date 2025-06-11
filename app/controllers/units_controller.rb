class UnitsController < ApplicationController
  before_action :set_unit, only: %i[show edit update destroy report qr_code]
  before_action :check_unit_owner, only: [:show, :edit, :update, :destroy]
  before_action :require_inspection_company, only: [:new, :create]
  before_action :no_index
  skip_before_action :require_login, only: [:report, :qr_code]

  def index
    @units = current_user.units.with_attached_photo.order(created_at: :desc)

    # Apply search
    @units = @units.search(params[:query]) if params[:query].present?

    # Apply filters
    @units = @units.overdue if params[:status] == "overdue"
    if params[:manufacturer].present?
      @units = @units.where(manufacturer: params[:manufacturer])
    end
    @units = @units.where(owner: params[:owner]) if params[:owner].present?

    @title = "Units"
    @title += " - Overdue" if params[:status] == "overdue"
    @title += " - #{params[:manufacturer]}" if params[:manufacturer].present?
    @title += " - #{params[:owner]}" if params[:owner].present?

    respond_to do |format|
      format.html
      format.csv { send_data unit_to_csv, filename: "unit-#{Date.today}.csv" }
    end
  end

  def show
    @inspections = @unit.inspections
      .includes(:inspector_company)
      .order(inspection_date: :desc)

    respond_to do |format|
      format.html
      format.pdf do
        pdf_data = PdfGeneratorService.generate_unit_report(@unit)

        send_data pdf_data.render,
          filename: "#{@unit.serial}.pdf",
          type: "application/pdf",
          disposition: "inline"
      end
      format.json do
        unit_data = {
          id: @unit.id,
          name: @unit.name,
          serial: @unit.serial,
          manufacturer: @unit.manufacturer,
          has_slide: @unit.has_slide
        }
        render json: unit_data
      end
    end
  end

  def new
    @unit = Unit.new
  end

  def create
    @unit = current_user.units.build(unit_params)

    if @unit.save
      flash[:notice] = I18n.t("units.messages.created")
      redirect_to @unit
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @unit.update(unit_params)
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t("units.messages.updated")
          redirect_to @unit
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("unit_save_message",
              partial: "shared/save_message",
              locals: {
                dom_id: "unit_save_message",
                success: true,
                success_message: t("units.messages.updated")
              })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json do
          error_data = {status: "error", errors: @unit.errors.full_messages}
          render json: error_data
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("unit_save_message",
              partial: "shared/save_message",
              locals: {
                dom_id: "unit_save_message",
                errors: @unit.errors.full_messages,
                error_message: t("shared.messages.save_failed")
              })
          ]
        end
      end
    end
  end

  def destroy
    if @unit.destroy
      flash[:notice] = I18n.t("units.messages.deleted")
      redirect_to units_path
    else
      error_message = @unit.errors.full_messages.first ||
        I18n.t("units.messages.delete_failed")
      flash[:alert] = error_message
      redirect_to @unit
    end
  end

  def report
    respond_to do |format|
      format.html do
        pdf_data = PdfGeneratorService.generate_unit_report(@unit)

        send_data pdf_data.render,
          filename: "#{@unit.serial}.pdf",
          type: "application/pdf",
          disposition: "inline"
      end

      format.pdf do
        pdf_data = PdfGeneratorService.generate_unit_report(@unit)

        send_data pdf_data.render,
          filename: "#{@unit.serial}.pdf",
          type: "application/pdf",
          disposition: "inline"
      end

      format.json do
        render json: JsonSerializerService.serialize_unit(@unit)
      end
    end
  end

  def qr_code
    qr_code_png = QrCodeService.generate_qr_code(@unit)

    send_data qr_code_png,
      filename: "#{@unit.serial}_QR.png",
      type: "image/png",
      disposition: "inline"
  end

  def new_from_inspection
    @inspection = current_user.inspections.find_by(id: params[:id])

    unless @inspection
      flash[:alert] = I18n.t("units.errors.inspection_not_found")
      redirect_to root_path and return
    end

    if @inspection.unit.present?
      flash[:alert] = I18n.t("units.errors.inspection_has_unit")
      redirect_to inspection_path(@inspection) and return
    end

    @unit = Unit.new(user: current_user)
  end

  def create_from_inspection
    @inspection = current_user.inspections.find_by(id: params[:id])

    unless @inspection
      flash[:alert] = I18n.t("units.errors.inspection_not_found")
      redirect_to root_path and return
    end

    if @inspection.unit.present?
      flash[:alert] = I18n.t("units.errors.inspection_has_unit")
      redirect_to inspection_path(@inspection) and return
    end

    @unit = current_user.units.build(unit_params)
    @unit.copy_attributes_from(@inspection)

    if @unit.save
      @inspection.update!(unit: @unit)
      flash[:notice] = I18n.t("units.messages.created_from_inspection")
      redirect_to inspection_path(@inspection)
    else
      render :new_from_inspection, status: :unprocessable_entity
    end
  end

  private

  def unit_params
    unit_specific_params = %i[
      name serial manufacturer photo description
      owner model manufacture_date notes
    ]
    copyable_attributes = Unit.new.copyable_attributes_via_reflection
    params.require(:unit).permit(unit_specific_params + copyable_attributes)
  end

  def no_index
    response.set_header("X-Robots-Tag", "noindex,nofollow")
  end

  def set_unit
    @unit = Unit.find_by(id: params[:id].upcase)

    unless @unit
      if action_name.in?(["report", "qr_code"])
        # For public report access, return 404 instead of redirect
        error_file = "#{Rails.root}/public/404.html"
        render file: error_file, status: :not_found, layout: false
      else
        flash[:alert] = I18n.t("units.messages.not_found")
        redirect_to units_path and return
      end
    end
  end

  def check_unit_owner
    unless @unit.user_id == current_user.id
      flash[:alert] = I18n.t("units.messages.access_denied")
      redirect_to units_path and return
    end
  end

  def require_inspection_company
    unless current_user.is_active?
      flash[:alert] = current_user.inactive_user_message
      redirect_to units_path
    end
  end

  def unit_to_csv
    attributes = %w[id name manufacturer serial has_slide]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      current_user.units.order(created_at: :desc).each do |unit|
        row = attributes.map { |attr| unit.send(attr) }
        csv << row
      end
    end
  end
end
