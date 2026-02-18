# typed: true
# frozen_string_literal: true

class UnitsController < ApplicationController
  extend T::Sig

  include ChangeTracking
  include TurboStreamResponders
  include PublicViewable
  include UserActivityCheck

  skip_before_action :require_login, only: %i[show]
  before_action :check_assessments_enabled
  before_action :require_admin, only: %i[all]
  before_action :set_unit, only: %i[destroy edit log show update]
  before_action :check_unit_owner, only: %i[destroy edit update]
  before_action :check_log_access, only: %i[log]
  before_action :require_user_active, only: %i[create new edit update]
  before_action :validate_badge_id_param, only: %i[new create]
  before_action :no_index

  def index
    @units = apply_filters(current_user.units)
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

  def all
    @units = apply_filters(Unit.all)
    @title = I18n.t("units.titles.all_units")

    respond_to do |format|
      format.html { render :index }
      format.csv do
        log_unit_event("exported", nil, "Exported #{@units.count} units to CSV")
        csv_data = UnitCsvExportService.new(@units).generate
        send_data csv_data, filename: "all-units-#{Time.zone.today}.csv"
      end
    end
  end

  def show
    # Handle federation HEAD requests
    return head :ok if request.head?

    @inspections = @unit.inspections
      .includes(:user, inspector_company: {logo_attachment: :blob})
      .order(inspection_date: :desc)

    respond_to do |format|
      format.html { render_show_html }
      format.pdf { send_unit_pdf }
      format.png { send_unit_qr_code }
      format.json do
        render json: UnitBlueprint.render_with_inspections(@unit)
      end
    end
  end

  def new
    @unit = Unit.new

    if @validated_badge_id.present?
      @unit.id = @validated_badge_id
      @prefilled_badge = true
    end
  end

  def create
    @unit = current_user.units.build(unit_params)
    @prefilled_badge = @validated_badge_id.present?

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
    return handle_image_processing_error if @image_processing_error

    previous_attributes = @unit.attributes.dup
    if @unit.update(unit_params)
      log_unit_changes(previous_attributes)
      handle_update_success(@unit, nil, nil, additional_streams: photo_turbo_streams)
    else
      handle_update_failure(@unit)
    end
  end

  def destroy
    unit_details = capture_unit_details_for_deletion
    if @unit.destroy
      log_unit_deletion(unit_details)
      flash[:notice] = I18n.t("units.messages.deleted")
      redirect_to units_path
    else
      flash[:alert] = unit_deletion_error_message
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
    service = build_unit_creation_service
    if service.create
      handle_unit_creation_success(service)
    elsif service.error_message
      handle_unit_creation_error(service)
    else
      render_unit_creation_form(service)
    end
  end

  private

  def validate_badge_id_param
    return unless unit_badges_enabled?

    id_param = extract_badge_id_param
    return if id_param.blank?

    normalized_id = normalize_unit_id(id_param)
    return redirect_to_existing_unit(normalized_id) if unit_exists?(normalized_id)

    # Only set validated badge ID if it exists, otherwise let model validation handle it
    @validated_badge_id = normalized_id if badge_exists?(normalized_id)
  end

  def log_unit_event(action, unit, details = nil, changed_data = nil)
    return unless current_user

    if unit
      log_resource_event(action, unit, details, changed_data)
    else
      log_system_unit_event(action, details)
    end
  rescue => e
    log_event_error(e)
  end

  def unit_params
    permitted_fields = build_unit_permitted_fields
    permitted_params = params.require(:unit).permit(*permitted_fields)
    process_image_params(permitted_params, :photo)
  end

  sig { returns(T::Boolean) }
  def unit_badges_enabled?
    Rails.configuration.units.badges_enabled
  end

  sig { params(raw_id: String).returns(String) }
  def normalize_unit_id(raw_id)
    raw_id.gsub(/\s+/, "").upcase[0, 8]
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

  def check_assessments_enabled
    head :not_found unless Rails.configuration.app.has_assessments
  end

  def send_unit_pdf
    # Unit already has photo loaded from set_unit
    result = PdfCacheService.fetch_or_generate_unit_pdf(
      @unit,
      debug_enabled: admin_debug_enabled?,
      debug_queries: debug_sql_queries
    )

    handle_pdf_response(result, pdf_filename)
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
    prefix = Rails.configuration.units.pdf_filename_prefix
    type_name = I18n.t("units.export.pdf_type")
    "#{prefix}#{type_name}-#{@unit.id}.pdf"
  end

  def resource_pdf_url
    unit_path(@unit, format: :pdf)
  end

  def apply_filters(units)
    units = units.includes(photo_attachment: :blob)
    units = units.search(params[:query])
    units = units.overdue if params[:status] == "overdue"
    units = units.by_manufacturer(params[:manufacturer])
    units.order(created_at: :desc)
  end

  def require_admin
    head :not_found unless current_user&.admin?
  end

  def build_index_title
    title_parts = [I18n.t("units.titles.index")]
    if params[:status] == "overdue"
      title_parts << I18n.t("units.status.overdue")
    end
    title_parts << params[:manufacturer] if params[:manufacturer].present?
    title_parts.join(" - ")
  end

  def handle_inactive_user_redirect
    redirect_to units_path
  end

  def handle_image_processing_error
    flash.now[:alert] = @image_processing_error.message
    handle_update_failure(@unit)
  end

  def log_unit_changes(previous_attributes)
    changed_data = calculate_changes(
      previous_attributes,
      @unit.attributes,
      unit_params.keys
    )
    log_unit_event("updated", @unit, nil, changed_data)
  end

  def photo_turbo_streams
    return [] if params[:unit][:photo].blank?

    [turbo_stream.replace(
      "unit_photo_preview",
      partial: "chobble_forms/file_field_turbo_response",
      locals: {
        model: @unit,
        field: :photo,
        turbo_frame_id: "unit_photo_preview",
        i18n_base: "forms.units",
        accept: "image/*"
      }
    )]
  end

  def capture_unit_details_for_deletion
    {
      name: @unit.name,
      serial: @unit.serial,
      manufacturer: @unit.manufacturer
    }
  end

  def log_unit_deletion(unit_details)
    Event.log(
      user: current_user,
      action: "deleted",
      resource: @unit,
      details: nil,
      metadata: unit_details
    )
  end

  def unit_deletion_error_message
    @unit.errors.full_messages.first || I18n.t("units.messages.delete_failed")
  end

  def build_unit_creation_service
    UnitCreationFromInspectionService.new(
      user: current_user,
      inspection_id: params[:id],
      unit_params: unit_params
    )
  end

  def handle_unit_creation_success(service)
    log_unit_event("created", service.unit)
    flash[:notice] = I18n.t("units.messages.created_from_inspection")
    redirect_to edit_inspection_path(service.inspection)
  end

  def handle_unit_creation_error(service)
    flash[:alert] = service.error_message
    redirect_to unit_creation_error_path(service)
  end

  def unit_creation_error_path(service)
    service.inspection ? inspection_path(service.inspection) : root_path
  end

  def render_unit_creation_form(service)
    @unit = service.unit
    @inspection = service.inspection
    render :new_from_inspection, status: :unprocessable_content
  end

  def extract_badge_id_param
    (action_name == "new") ? params[:id] : params.dig(:unit, :id)
  end

  def unit_exists?(normalized_id)
    Unit.exists?(id: normalized_id)
  end

  def badge_exists?(normalized_id)
    Badge.exists?(id: normalized_id)
  end

  def redirect_to_existing_unit(normalized_id)
    flash[:notice] = I18n.t("units.messages.existing_unit_found")
    redirect_to Unit.find(normalized_id)
  end

  def log_resource_event(action, unit, details, changed_data)
    Event.log(
      user: current_user,
      action: action,
      resource: unit,
      details: details,
      changed_data: changed_data
    )
  end

  def log_system_unit_event(action, details)
    Event.log_system_event(
      user: current_user,
      action: action,
      details: details,
      metadata: {resource_type: "Unit"}
    )
  end

  def log_event_error(error)
    Rails.logger.error I18n.t("units.errors.log_failed", message: error.message)
  end

  def build_unit_permitted_fields
    fields = %i[
      description
      manufacture_date
      manufacturer
      name
      operator
      photo
      serial
      unit_type
    ]
    fields << :id if allow_badge_id_in_params?
    fields
  end

  def allow_badge_id_in_params?
    create_actions = %w[create create_from_inspection]
    unit_badges_enabled? && create_actions.include?(action_name)
  end

end
