# typed: false
# frozen_string_literal: true

class InspectionsController < ApplicationController
  rate_limit to: 30, within: 1.minute, only: :show,
    by: -> { request.remote_ip },
    store: RATE_LIMIT_STORE, name: "public-report"

  include ChangeTracking
  include EventLogging
  include InspectionTurboStreams
  include PublicViewable
  include UserActivityCheck

  skip_before_action :require_login, only: %i[show]
  before_action :check_assessments_enabled
  before_action :check_unit_badges_for_create, only: %i[create]
  before_action :set_inspection, except: %i[create index new_from_unit]
  before_action :check_inspection_owner, except: %i[create index show new_from_unit]
  before_action :validate_unit_ownership, only: %i[update]
  before_action :redirect_if_complete,
    except: %i[create index destroy mark_draft show log new_from_unit]
  before_action :require_user_active, only: %i[create edit update new_from_unit]
  before_action :validate_inspection_completability, only: %i[show edit]
  before_action :no_index, except: %i[new_from_unit]

  def index
    all_inspections = filtered_inspections_query_without_order.to_a
    partitioned = Inspection.partition_for_index(all_inspections)
    @draft_inspections = partitioned.fetch(:drafts)
    @complete_inspections = partitioned.fetch(:complete)

    @title = helpers.inspections_index_title(params[:result])
    @has_any_inspections = all_inspections.any?

    respond_to do |format|
      format.html
      format.csv do
        log_inspection_event("exported", nil, "Exported #{@complete_inspections.count} inspections to CSV")
        send_inspections_csv
      end
    end
  end

  def show
    # Handle federation HEAD requests
    return head :ok if request.head?

    respond_to do |format|
      format.html { render_show_html }
      format.pdf { send_inspection_pdf }
      format.png { send_inspection_qr_code }
      format.json do
        render json: InspectionBlueprint.render(@inspection)
      end
    end
  end

  def new_from_unit
    @title = t("inspections.titles.new_from_unit")
    @search_term = unit_search_param
    search_unit_or_badge if unit_search_param.present?

    respond_to do |format|
      format.html { render :new_from_unit }
      format.turbo_stream { render_unit_search_results }
    end
  end

  def create
    unit_id = params[:unit_id] || params.dig(:inspection, :unit_id)
    result = InspectionCreationService.new(
      current_user,
      unit_id: unit_id
    ).create

    if result[:success]
      log_inspection_event("created", result[:inspection])
      flash[:notice] = result[:message]
      redirect_to edit_inspection_path(result[:inspection])
    else
      flash[:alert] = result[:message]
      redirect_to result[:redirect_path]
    end
  end

  def edit
    validate_tab_parameter
    set_previous_inspection
  end

  def update
    previous_attributes = @inspection.attributes.dup
    params_to_update = inspection_params

    return render_image_processing_error if @image_processing_error

    if @inspection.update(params_to_update)
      log_update_changes(previous_attributes)
      handle_successful_update
    else
      handle_failed_update
    end
  end

  def destroy
    return redirect_complete_inspection_delete if @inspection.complete?

    inspection_details = capture_inspection_details
    @inspection.destroy
    log_deletion(inspection_details)
    redirect_to inspections_path, notice: I18n.t("inspections.messages.deleted")
  end

  def select_unit
    @units = current_user.units
      .includes(photo_attachment: :blob)
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

    @inspection.unit = unit

    if @inspection.save
      handle_successful_unit_update(unit)
    else
      handle_failed_unit_update
    end
  end

  def complete
    validation_errors = @inspection.validate_completeness

    if validation_errors.any?
      error_list = validation_errors.join(", ")
      flash[:alert] =
        t("inspections.messages.cannot_complete", errors: error_list)
      redirect_to edit_inspection_path(@inspection)
      return
    end

    @inspection.complete!(current_user)
    log_inspection_event("completed", @inspection)
    flash[:notice] = t("inspections.messages.marked_complete")
    redirect_to @inspection
  end

  def mark_draft
    if @inspection.update(complete_date: nil)
      log_inspection_event("marked_draft", @inspection)
      flash[:notice] = t("inspections.messages.marked_in_progress")
    else
      error_messages = @inspection.errors.full_messages.join(", ")
      flash[:alert] = t("inspections.messages.mark_in_progress_failed",
        errors: error_messages)
    end
    redirect_to edit_inspection_path(@inspection)
  end

  def log
    @events = Event.for_resource(@inspection).recent.includes(:user)
    @title = I18n.t("inspections.titles.log", inspection: @inspection.id)
  end

  private

  def inspection_params
    base_params = build_base_params
    add_assessment_params(base_params)

    process_image_params(base_params, :photo_1, :photo_2, :photo_3)
  end

  def handle_successful_unit_update(unit)
    log_inspection_event("unit_changed", @inspection, "Unit changed to #{unit.name}")
    flash[:notice] = t("inspections.messages.unit_changed", unit_name: unit.name)
    redirect_to edit_inspection_path(@inspection)
  end

  def handle_failed_unit_update
    error_messages = @inspection.errors.full_messages.join(", ")
    flash[:alert] = t("inspections.messages.unit_change_failed", errors: error_messages)
    redirect_to select_unit_inspection_path(@inspection)
  end

  def unit_search_param = params.dig(:search, :search)

  def search_unit_or_badge
    normalized_search = unit_search_param.gsub(/\s+/, "").upcase[0, CustomIdGenerator::ID_LENGTH]
    @unit = Unit.includes(photo_attachment: :blob).find_by(id: normalized_search)
    @badge = Badge.find_by(id: normalized_search) if @unit.nil?
  end

  def render_unit_search_results
    render turbo_stream: turbo_stream.replace("unit_search_results", partial: "inspections/unit_search_results")
  end

  def render_image_processing_error
    flash.now[:alert] = @image_processing_error.message
    render :edit, status: :unprocessable_content
  end

  def log_update_changes(previous_attributes)
    changed_data = calculate_changes(previous_attributes, @inspection.attributes, inspection_params.keys)
    log_inspection_event("updated", @inspection, nil, changed_data)
  end

  def redirect_complete_inspection_delete
    alert_message = I18n.t("inspections.messages.delete_complete_denied")
    redirect_to inspection_path(@inspection), alert: alert_message
  end

  def capture_inspection_details
    {
      inspection_date: @inspection.inspection_date,
      unit_serial: @inspection.unit&.serial,
      unit_name: @inspection.unit&.name,
      complete_date: @inspection.complete_date
    }
  end

  def log_deletion(inspection_details)
    Event.log(
      user: current_user,
      action: "deleted",
      resource: @inspection,
      details: nil,
      metadata: inspection_details
    )
  end

  def log_completion_error
    inspection_errors = @inspection.completion_errors
    Rails.logger.error "Inspection #{@inspection.id} is marked complete but has errors: #{inspection_errors}"
  end

  def raise_or_log_integrity_error
    error_message = I18n.t("inspections.errors.invalid_completion_state", errors: @inspection.completion_errors.join(", "))
    if Rails.env.local?
      test_message = "In tests, use create(:inspection, :completed) to avoid this."
      raise StandardError, "DATA INTEGRITY ERROR: #{error_message}. #{test_message}"
    else
      Rails.logger.error "DATA INTEGRITY ERROR: #{error_message}"
    end
  end

  def check_assessments_enabled
    head :not_found unless Rails.configuration.app.has_assessments
  end

  def check_unit_badges_for_create
    return unless Rails.configuration.units.badges_enabled
    return if params[:unit_id].present?

    flash[:alert] = t("inspections.errors.direct_creation_disabled")
    redirect_to new_inspection_from_unit_path
  end

  def send_inspections_csv
    csv_data = InspectionCsvExportService.new(@complete_inspections).generate
    filename = I18n.t("inspections.export.csv_filename", date: Time.zone.today)
    send_data csv_data, filename: filename
  end

  def validate_tab_parameter
    return if params[:tab].blank?

    valid_tabs = helpers.inspection_tabs(@inspection)
    return if valid_tabs.include?(params[:tab])

    redirect_to edit_inspection_path(@inspection),
      alert: I18n.t("inspections.messages.invalid_tab")
  end

  def validate_inspection_completability
    return unless @inspection.complete?
    return if @inspection.can_mark_complete?

    log_completion_error
    raise_or_log_integrity_error
  end

  ASSESSMENT_SYSTEM_ATTRIBUTES = %w[
    inspection_id
    created_at
    updated_at
  ].freeze

  def build_base_params
    params.require(:inspection).permit(*Inspection::USER_EDITABLE_PARAMS)
  end

  def add_assessment_params(base_params)
    Inspection::ALL_ASSESSMENT_TYPES.each_key do |ass_type|
      ass_key = "#{ass_type}_attributes"
      next if params[:inspection][ass_key].blank?

      ass_params = params[:inspection][ass_key]
      permitted_ass_params = assessment_permitted_attributes(ass_type)
      base_params[ass_key] = ass_params.permit(*permitted_ass_params)
    end
  end

  def assessment_permitted_attributes(assessment_type)
    model_class = "Assessments::#{assessment_type.to_s.camelize}".constantize
    model_class.column_name_syms - ASSESSMENT_SYSTEM_ATTRIBUTES
  end

  def filtered_inspections_query_without_order = current_user.inspections
    .includes(:inspector_company, unit: {photo_attachment: {blob: :attachments}})
    .search(params[:query])
    .filter_by_result(params[:result])
    .filter_by_unit(params[:unit_id])
    .filter_by_operator(params[:operator])

  def set_inspection
    inspection_query = Inspection
      .includes(
        :user, :inspector_company,
        *Inspection::ALL_ASSESSMENT_TYPES.keys,
        unit: {photo_attachment: :blob},
        photo_1_attachment: :blob,
        photo_2_attachment: :blob,
        photo_3_attachment: :blob
      )
    inspection_id = params[:id]&.upcase

    @inspection = find_by_id_with_pdf_measurement(
      :inspection, inspection_id, inspection_query
    )

    head :not_found unless @inspection
  end

  def check_inspection_owner
    head :not_found unless owns_resource?
  end

  def redirect_if_complete
    return unless @inspection.complete?

    flash[:notice] = I18n.t("inspections.messages.cannot_edit_complete")
    redirect_to @inspection
  end

  def validate_unit_ownership
    return unless inspection_params[:unit_id]

    unit = if Rails.configuration.units.badges_enabled
      Unit.find_by(id: inspection_params[:unit_id])
    else
      current_user.units.find_by(id: inspection_params[:unit_id])
    end

    return if unit

    # Unit ID not found or doesn't belong to user - security issue
    flash[:alert] = I18n.t("inspections.errors.invalid_unit")
    render :edit, status: :unprocessable_content
  end

  def handle_successful_update
    respond_to do |format|
      format.html do
        flash[:notice] = I18n.t("inspections.messages.updated")
        redirect_to @inspection
      end
      format.json do
        render json: {status: I18n.t("shared.api.success"),
                      inspection: @inspection}
      end
      format.turbo_stream { render turbo_stream: success_turbo_streams }
    end
  end

  def handle_failed_update
    respond_to do |format|
      format.html { render :edit, status: :unprocessable_content }
      format.json { render json: {status: I18n.t("shared.api.error"), errors: @inspection.errors.full_messages} }
      format.turbo_stream { render turbo_stream: error_turbo_streams }
    end
  end

  def send_inspection_pdf
    deliver_cached_pdf(:inspection, @inspection.id) do
      result = PdfCacheService.fetch_or_generate_inspection_pdf(
        @inspection,
        debug_enabled: admin_debug_enabled?,
        debug_queries: debug_sql_queries
      )
      track_pdf_access
      result
    end
  end

  def track_pdf_access
    PdfPerformance.measure(
      :access_tracking,
      pdf_type: :inspection,
      record_id: @inspection.id
    ) do
      @inspection.update(pdf_last_accessed_at: Time.current)
    end
  end

  def send_inspection_qr_code
    send_qr_code(@inspection, qr_code_filename)
  end

  # PublicViewable implementation
  def check_resource_owner
    check_inspection_owner
  end

  def viewable_resource = @inspection

  def qr_code_filename
    identifier = @inspection.unit&.serial || @inspection.id
    I18n.t("inspections.export.qr_filename", identifier: identifier)
  end

  def resource_pdf_url
    inspection_path(@inspection, format: :pdf)
  end

  def handle_inactive_user_redirect
    if action_name == "create"
      unit_id = params[:unit_id] || params.dig(:inspection, :unit_id)
      if unit_id.present?
        unit = current_user.units.find_by(id: unit_id)
        redirect_to unit ? unit_path(unit) : inspections_path
      else
        redirect_to inspections_path
      end
    elsif action_name.in?(%w[edit update]) && @inspection
      redirect_to inspection_path(@inspection)
    else
      redirect_to inspections_path
    end
  end

  def set_previous_inspection
    @previous_inspection = @inspection.unit&.last_inspection
    return if @previous_inspection.nil? || @previous_inspection.id == @inspection.id

    @prefilled_fields = InspectionPrefillService
      .new(@inspection, @previous_inspection, params[:tab])
      .field_labels
  end

  def log_inspection_event(action, inspection, details = nil, changed_data = nil)
    log_event(action, inspection, resource_type: "Inspection",
      details: details, changed_data: changed_data)
  end
end
