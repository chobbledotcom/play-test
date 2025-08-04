# typed: true
# frozen_string_literal: true

class UnitsController < ApplicationController
  extend T::Sig

  include TurboStreamResponders
  include PublicViewable
  include UserActivityCheck

  skip_before_action :require_login, only: %i[show]
  before_action :set_unit, only: %i[destroy edit log show update]
  before_action :check_unit_owner, only: %i[destroy edit update]
  before_action :check_log_access, only: %i[log]
  before_action :require_user_active, only: %i[create new edit update]
  before_action :no_index

  def index
    @units = filtered_units_query
    @title = build_index_title

    respond_to do |format|
      format.html
      format.csv do
        log_unit_event("exported", nil, "Exported #{@units.count} units to CSV")
        csv_data = UnitCsvExportService.new(@units).generate
        send_data csv_data, filename: "units-#{Time.zone.today}.csv"
      end
    end
  end

  def show
    # Handle federation HEAD requests
    return head :ok if request.head?

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

    if @image_processing_error
      flash.now[:alert] = @image_processing_error.message
      handle_create_failure(@unit)
      return
    end

    if @unit.save
      log_unit_event("created", @unit)
      handle_create_success(@unit)
    else
      handle_create_failure(@unit)
    end
  end

  def edit = nil

  def update
    previous_attributes = @unit.attributes.dup

    params_to_update = unit_params

    if @image_processing_error
      flash.now[:alert] = @image_processing_error.message
      handle_update_failure(@unit)
      return
    end

    if @unit.update(params_to_update)
      # Calculate what changed
      changed_data = calculate_changes(
        previous_attributes,
        @unit.attributes,
        unit_params.keys
      )

      log_unit_event("updated", @unit, nil, changed_data)

      additional_streams = []
      if params[:unit][:photo].present?
        # Render just the file field without a new form wrapper
        additional_streams << turbo_stream.replace(
          "unit_photo_preview",
          partial: "chobble_forms/file_field_turbo_response",
          locals: {
            model: @unit,
            field: :photo,
            turbo_frame_id: "unit_photo_preview",
            i18n_base: "forms.units",
            accept: "image/*"
          }
        )
      end

      handle_update_success(@unit, nil, nil, additional_streams: additional_streams)
    else
      handle_update_failure(@unit)
    end
  end

  def destroy
    # Capture unit details before deletion for the audit log
    unit_details = {
      name: @unit.name,
      serial: @unit.serial,
      operator: @unit.operator,
      manufacturer: @unit.manufacturer
    }

    if @unit.destroy
      # Log the deletion with the unit details in metadata
      Event.log(
        user: current_user,
        action: "deleted",
        resource: @unit,
        details: nil,
        metadata: unit_details
      )
      flash[:notice] = I18n.t("units.messages.deleted")
      redirect_to units_path
    else
      error_message =
        @unit.errors.full_messages.first ||
        I18n.t("units.messages.delete_failed")
      flash[:alert] = error_message
      redirect_to @unit
    end
  end

  def log
    @events = Event.for_resource(@unit).recent.includes(:user)
    @title = I18n.t("units.titles.log", unit: @unit.name)
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
      log_unit_event("created", service.unit)
      flash[:notice] = I18n.t("units.messages.created_from_inspection")
      redirect_to inspection_path(service.inspection)
    elsif service.error_message
      flash[:alert] = service.error_message
      redirect_path = service.inspection ?
        inspection_path(service.inspection) :
        root_path
      redirect_to redirect_path
    else
      @unit = service.unit
      @inspection = service.inspection
      render :new_from_inspection, status: :unprocessable_entity
    end
  end

  private

  def log_unit_event(action, unit, details = nil, changed_data = nil)
    return unless current_user

    if unit
      Event.log(
        user: current_user,
        action: action,
        resource: unit,
        details: details,
        changed_data: changed_data
      )
    else
      # For events without a specific unit (like CSV export)
      Event.log_system_event(
        user: current_user,
        action: action,
        details: details,
        metadata: {resource_type: "Unit"}
      )
    end
  rescue => e
    Rails.logger.error I18n.t("units.errors.log_failed", message: e.message)
  end

  def calculate_changes(previous_attributes, current_attributes, changed_keys)
    changes = {}

    changed_keys.map(&:to_s).each do |key|
      previous_value = previous_attributes[key]
      current_value = current_attributes[key]

      if previous_value != current_value
        changes[key] = {
          "from" => previous_value,
          "to" => current_value
        }
      end
    end

    changes.presence
  end

  def unit_params
    permitted_params = params.require(:unit).permit(*%i[
      description
      manufacture_date
      manufacturer
      name
      operator
      photo
      serial
      unit_type
    ])

    process_image_params(permitted_params, :photo)
  end

  def no_index = response.set_header("X-Robots-Tag", "noindex,nofollow")

  def set_unit
    @unit = Unit.includes(photo_attachment: :blob)
      .find_by(id: params[:id].upcase)

    unless @unit
      # Always return 404 for non-existent resources regardless of login status
      head :not_found
    end
  end

  def check_unit_owner
    head :not_found unless owns_resource?
  end

  def check_log_access
    # Only unit owners can view logs
    head :not_found unless owns_resource?
  end

  def send_unit_pdf
    # Unit already has photo loaded from set_unit
    result = PdfCacheService.fetch_or_generate_unit_pdf(
      @unit,
      debug_enabled: admin_debug_enabled?,
      debug_queries: debug_sql_queries
    )

    case result.type
    when :redirect
      redirect_to result.data, allow_other_host: true
    when :pdf_data
      send_data result.data,
        filename: "#{@unit.serial}.pdf",
        type: "application/pdf",
        disposition: "inline"
    end
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
    units = current_user.units.includes(photo_attachment: :blob)
    units = units.search(params[:query])
    units = units.overdue if params[:status] == "overdue"
    units = units.by_manufacturer(params[:manufacturer])
    units = units.by_operator(params[:operator])
    units.order(created_at: :desc)
  end

  def build_index_title
    title_parts = [I18n.t("units.titles.index")]
    if params[:status] == "overdue"
      title_parts << I18n.t("units.status.overdue")
    end
    title_parts << params[:manufacturer] if params[:manufacturer].present?
    title_parts << params[:operator] if params[:operator].present?
    title_parts.join(" - ")
  end

  def handle_inactive_user_redirect
    redirect_to units_path
  end
end
