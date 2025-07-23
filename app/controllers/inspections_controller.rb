class InspectionsController < ApplicationController
  include InspectionTurboStreams
  include PublicViewable
  include UserActivityCheck

  skip_before_action :require_login, only: %i[show]
  before_action :set_inspection, except: %i[create index]
  before_action :check_inspection_owner, except: %i[create index show]
  before_action :validate_unit_ownership, only: %i[update]
  before_action :redirect_if_complete,
    except: %i[create index destroy mark_draft show log]
  before_action :require_user_active, only: %i[create edit update]
  before_action :validate_inspection_completability, only: %i[show edit]
  before_action :no_index

  def index
    all_inspections = filtered_inspections_query_without_order.to_a
    partition_inspections(all_inspections)

    @title = build_index_title
    @has_any_inspections = all_inspections.any?
    load_inspection_locations

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
        render json: JsonSerializerService.serialize_inspection(@inspection)
      end
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
    load_inspection_locations
    set_previous_inspection
  end

  def update
    previous_attributes = @inspection.attributes.dup
    if @inspection.update(inspection_params)
      changed_data = calculate_changes(
        previous_attributes,
        @inspection.attributes,
        inspection_params.keys
      )
      log_inspection_event("updated", @inspection, nil, changed_data)
      handle_successful_update
    else
      handle_failed_update
    end
  end

  def destroy
    if @inspection.complete?
      alert_message = I18n.t("inspections.messages.delete_complete_denied")
      redirect_to inspection_path(@inspection), alert: alert_message
      return
    end

    # Capture inspection details before deletion for the audit log
    inspection_details = {
      unique_report_number: @inspection.unique_report_number,
      inspection_date: @inspection.inspection_date,
      unit_serial: @inspection.unit&.serial,
      unit_name: @inspection.unit&.name,
      complete_date: @inspection.complete_date
    }

    @inspection.destroy
    # Log the deletion with the inspection details in metadata
    Event.log(
      user: current_user,
      action: "deleted",
      resource: @inspection,
      details: nil,
      metadata: inspection_details
    )
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

  def inspection_params
    base_params = build_base_params
    add_assessment_params(base_params)
    base_params
  end

  private

  def partition_inspections(all_inspections)
    @draft_inspections = all_inspections
      .select { it.complete_date.nil? }
      .sort_by(&:created_at)

    @complete_inspections = all_inspections
      .select { it.complete_date.present? }
      .sort_by { -it.created_at.to_i }
  end

  def send_inspections_csv
    csv_data = InspectionCsvExportService.new(@complete_inspections).generate
    filename = I18n.t("inspections.export.csv_filename", date: Time.zone.today)
    send_data csv_data, filename: filename
  end

  def validate_tab_parameter
    return if params[:tab].blank?

    valid_tabs = helpers.inspection_tabs(@inspection)
    unless valid_tabs.include?(params[:tab])
      redirect_to edit_inspection_path(@inspection),
        alert: I18n.t("inspections.messages.invalid_tab")
    end
  end

  def validate_inspection_completability
    return unless @inspection.complete?
    return if @inspection.can_mark_complete?

    error_message = I18n.t(
      "inspections.errors.invalid_completion_state",
      errors: @inspection.completion_errors.join(", ")
    )

    inspection_errors = @inspection.completion_errors
    Rails.logger.error "Inspection #{@inspection.id} is marked complete " \
                      "but has errors: #{inspection_errors}"

    # Only raise error in development/test environments
    if Rails.env.local?
      test_message = "In tests, use create(:inspection, :completed) to avoid this."
      raise StandardError, "DATA INTEGRITY ERROR: #{error_message}. #{test_message}"
    else
      # In production, log the error but continue
      Rails.logger.error "DATA INTEGRITY ERROR: #{error_message}"
    end
  end

  ASSESSMENT_SYSTEM_ATTRIBUTES = %w[
    inspection_id
    created_at
    updated_at
  ].freeze

  # Build safe mappings from Inspection::ALL_ASSESSMENT_TYPES
  # This ensures mappings stay in sync with the model definition
  ASSESSMENT_TAB_MAPPING = Inspection::ALL_ASSESSMENT_TYPES
    .each_with_object({}) do |(method_name, _), hash|
      # Convert :user_height_assessment to "user_height"
      tab_name = method_name.to_s.gsub(/_assessment$/, "")
      hash[tab_name] = method_name
    end.freeze

  ASSESSMENT_CLASS_MAPPING = Inspection::ALL_ASSESSMENT_TYPES
    .each_with_object({}) do |(method_name, klass), hash|
      # Convert :user_height_assessment to "user_height"
      tab_name = method_name.to_s.gsub(/_assessment$/, "")
      hash[tab_name] = klass
    end.freeze

  def build_base_params
    params.require(:inspection).permit(*Inspection::USER_EDITABLE_PARAMS)
  end

  def add_assessment_params(base_params)
    Inspection::ALL_ASSESSMENT_TYPES.each do |ass_type, _ass_class|
      ass_key = "#{ass_type}_attributes"
      next if params[:inspection][ass_key].blank?

      ass_params = params[:inspection][ass_key]
      permitted_ass_params = assessment_permitted_attributes(ass_type)
      base_params[ass_key] = ass_params.permit(*permitted_ass_params)
    end
  end

  def assessment_permitted_attributes(assessment_type)
    model_class = "Assessments::#{assessment_type.to_s.camelize}".constantize
    all_attributes = model_class.column_names
    (all_attributes - ASSESSMENT_SYSTEM_ATTRIBUTES).map { it.to_sym }
  end

  def filtered_inspections_query_without_order = current_user.inspections
    .includes(:inspector_company, unit: {photo_attachment: :blob})
    .search(params[:query])
    .filter_by_result(params[:result])
    .filter_by_unit(params[:unit_id])
    .filter_by_owner(params[:owner])
    .filter_by_inspection_location(params[:inspection_location])

  def no_index = response.set_header("X-Robots-Tag", "noindex,nofollow")

  def set_inspection
    @inspection = Inspection
      .includes(
        :user, :inspector_company,
        *Inspection::ALL_ASSESSMENT_TYPES.keys,
        unit: {photo_attachment: :blob},
        photo_1_attachment: :blob,
        photo_2_attachment: :blob,
        photo_3_attachment: :blob
      )
      .find_by(id: params[:id]&.upcase)

    head :not_found unless @inspection
  end

  def check_inspection_owner
    return if current_user && @inspection.user_id == current_user.id

    head :not_found
  end

  def redirect_if_complete
    return unless @inspection.complete?

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
      format.json do
        render json: {status: I18n.t("shared.api.success"),
                      inspection: @inspection}
      end
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
    pdf_data = PdfGeneratorService.generate_inspection_report(
      @inspection,
      debug_enabled: admin_debug_enabled?,
      debug_queries: debug_sql_queries
    )
    @inspection.update(pdf_last_accessed_at: Time.current)

    send_data pdf_data.render,
      filename: pdf_filename,
      type: "application/pdf",
      disposition: "inline"
  end

  def send_inspection_qr_code
    qr_code_png = QrCodeService.generate_qr_code(@inspection)

    send_data qr_code_png,
      filename: qr_code_filename,
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
    identifier = @inspection.unit&.serial || @inspection.id
    I18n.t("inspections.export.pdf_filename", identifier: identifier)
  end

  def qr_code_filename
    identifier = @inspection.unit&.serial || @inspection.id
    I18n.t("inspections.export.qr_filename", identifier: identifier)
  end

  def resource_pdf_url
    inspection_path(@inspection, format: :pdf)
  end

  def load_inspection_locations
    @inspection_locations = current_user
      .inspections
      .pluck(:inspection_location)
      .uniq
      .compact
      .sort
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

  NOT_COPIED_FIELDS = %w[
    complete_date
    created_at
    id
    inspection_date
    inspection_id
    inspector_company_id
    is_seed
    passed
    pdf_last_accessed_at
    unique_report_number
    unit_id
    updated_at
    user_id
  ]

  def set_previous_inspection
    @previous_inspection = @inspection.unit&.last_inspection
    return if !@previous_inspection || @previous_inspection.id == @inspection.id

    @prefilled_fields = []
    current_object, previous_object, column_names = get_prefill_objects

    column_names.each do |field|
      next if NOT_COPIED_FIELDS.include?(field)
      next if previous_object&.send(field).nil?
      next unless current_object.send(field).nil?

      @prefilled_fields << translate_field_name(field)
    end
  end

  def get_prefill_objects
    case params[:tab]
    when "inspection", "", nil
      [@inspection, @previous_inspection, Inspection.column_names]
    when "results"
      # Results tab uses inspection fields directly, not an assessment
      # Only risk_assessment should be prefilled, not passed
      [@inspection, @previous_inspection, ["risk_assessment"]]
    else
      assessment_method = ASSESSMENT_TAB_MAPPING[params[:tab]]
      assessment_class = ASSESSMENT_CLASS_MAPPING[params[:tab]]
      [
        @inspection.public_send(assessment_method),
        @previous_inspection.public_send(assessment_method),
        assessment_class.column_names
      ]
    end
  end

  def translate_field_name(field)
    is_comment = field.end_with?("_comment")
    is_pass = field.end_with?("_pass")
    field_base = field.gsub(/_(comment|pass)$/, "")
    i18n_base = "forms.#{params[:tab]}.fields"

    translated = I18n.t("#{i18n_base}.#{field_base}", default: nil)
    translated ||= I18n.t("#{i18n_base}.#{field}", default: field.humanize)

    if is_comment
      translated += " (#{I18n.t("shared.comment")})"
    elsif is_pass
      translated += " (#{I18n.t("shared.pass")}/#{I18n.t("shared.fail")})"
    end

    translated
  end

  def log_inspection_event(action, inspection, details = nil, changed_data = nil)
    return unless current_user

    if inspection
      Event.log(
        user: current_user,
        action: action,
        resource: inspection,
        details: details,
        changed_data: changed_data
      )
    else
      # For events without a specific inspection (like CSV export)
      Event.log_system_event(
        user: current_user,
        action: action,
        details: details,
        metadata: {resource_type: "Inspection"}
      )
    end
  rescue => e
    Rails.logger.error "Failed to log inspection event: #{e.message}"
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
end
