class UnitsController < ApplicationController
  include UnitTurboStreams
  include PublicViewable
  include UserActivityCheck

  skip_before_action :require_login, only: %i[show]
  before_action :set_unit, only: %i[destroy edit show update]
  before_action :check_unit_owner, only: %i[destroy edit update]
  before_action :require_user_active, only: %i[create new edit update]
  before_action :no_index

  def index
    @units = filtered_units_query
    @title = build_index_title

    respond_to do |format|
      format.html
      format.csv do
        csv_data = UnitCsvExportService.new(@units).generate
        send_data csv_data, filename: "units-#{Date.today}.csv"
      end
    end
  end

  def show
    @inspections = @unit.inspections
      .includes(inspector_company: {logo_attachment: :blob})
      .order(inspection_date: :desc)

    respond_to do |format|
      format.html { render_show_html }
      format.pdf { send_unit_pdf }
      format.png { send_unit_qr_code }
      format.json do
        render json: JsonSerializerService.serialize_unit(@unit)
      end
    end
  end

  def new = @unit = Unit.new

  def create
    @unit = current_user.units.build(unit_params)

    if @unit.save
      flash[:notice] = I18n.t("units.messages.created")
      redirect_to @unit
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit = nil

  def update
    if @unit.update(unit_params)
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t("units.messages.updated")
          redirect_to @unit
        end
        format.turbo_stream { render_unit_update_success_stream }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json do
          render json: {status: I18n.t("shared.api.error"), errors: @unit.errors.full_messages}
        end
        format.turbo_stream { render_unit_update_error_stream }
      end
    end
  end

  def destroy
    if @unit.destroy
      flash[:notice] = I18n.t("units.messages.deleted")
      redirect_to units_path
    else
      @unit.errors.full_messages.first || I18n.t("units.messages.delete_failed") => error_message
      flash[:alert] = error_message
      redirect_to @unit
    end
  end

  def new_from_inspection
    @inspection = current_user.inspections.find_by(id: params[:id])

    unless @inspection
      flash[:alert] = I18n.t("units.errors.inspection_not_found")
      redirect_to root_path and return
    end

    if @inspection.unit
      flash[:alert] = I18n.t("units.errors.inspection_has_unit")
      redirect_to inspection_path(@inspection) and return
    end

    @unit = Unit.new(user: current_user)
  end

  def create_from_inspection
    service = UnitCreationFromInspectionService.new(
      user: current_user,
      inspection_id: params[:id],
      unit_params: unit_params
    )

    if service.create
      flash[:notice] = I18n.t("units.messages.created_from_inspection")
      redirect_to inspection_path(service.inspection)
    elsif service.error_message
      flash[:alert] = service.error_message
      redirect_to service.inspection ? inspection_path(service.inspection) : root_path
    else
      @unit = service.unit
      @inspection = service.inspection
      render :new_from_inspection, status: :unprocessable_entity
    end
  end

  private

  def unit_params
    params.require(:unit).permit(*%i[
      description
      manufacture_date
      manufacturer
      model
      name
      notes
      owner
      photo
      serial
    ])
  end

  def no_index = response.set_header("X-Robots-Tag", "noindex,nofollow")

  def set_unit
    @unit = Unit.with_attached_photo.find_by(id: params[:id].upcase)

    unless @unit
      # Always return 404 for non-existent resources regardless of login status
      head :not_found
    end
  end

  def check_unit_owner
    unless current_user && @unit.user_id == current_user.id
      flash[:alert] = I18n.t("units.messages.access_denied")
      redirect_to units_path and return
    end
  end

  def send_unit_pdf
    # Unit already has photo loaded from set_unit
    pdf_data = PdfGeneratorService.generate_unit_report(@unit)

    send_data pdf_data.render,
      filename: "#{@unit.serial}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def send_unit_qr_code
    qr_code_png = QrCodeService.generate_qr_code(@unit)

    send_data qr_code_png,
      filename: "#{@unit.serial}_QR.png",
      type: "image/png",
      disposition: "inline"
  end

  # PublicViewable implementation
  def check_resource_owner
    check_unit_owner
  end

  def owns_resource?
    @unit && current_user && @unit.user_id == current_user.id
  end

  def pdf_filename
    "#{@unit.serial}.pdf"
  end

  def resource_pdf_url
    unit_path(@unit, format: :pdf)
  end

  def filtered_units_query
    units = current_user.units.with_attached_photo
    units = units.search(params[:query])
    units = units.overdue if params[:status] == "overdue"
    units = units.by_manufacturer(params[:manufacturer])
    units = units.by_owner(params[:owner])
    units.order(created_at: :desc)
  end

  def build_index_title
    title_parts = [I18n.t("units.titles.index")]
    title_parts << I18n.t("units.status.overdue") if params[:status] == "overdue"
    title_parts << params[:manufacturer] if params[:manufacturer].present?
    title_parts << params[:owner] if params[:owner].present?
    title_parts.join(" - ")
  end

  def handle_inactive_user_redirect
    redirect_to units_path
  end
end
