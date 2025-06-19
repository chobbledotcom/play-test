class InspectionsController < ApplicationController
  include InspectionTurboStreams
  include PublicViewable
  include UserActivityCheck

  skip_before_action :require_login, only: %i[show]
  before_action :set_inspection, except: %i[create index]
  before_action :check_inspection_owner, except: %i[create index show]
  before_action :validate_unit_ownership, only: %i[update]
  before_action :redirect_if_complete,
    except: %i[create index destroy mark_draft show]
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
      format.csv { send_inspections_csv }
    end
  end

  def show
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
      flash[:notice] = t("inspections.messages.unit_changed",
        unit_name: unit.name)
      redirect_to edit_inspection_path(@inspection)
    else
      error_messages = @inspection.errors.full_messages.join(", ")
      flash[:alert] = t("inspections.messages.unit_change_failed",
        errors: error_messages)
      redirect_to select_unit_inspection_path(@inspection)
    end
  end

  def complete
    validation_errors = @inspection.validate_completeness

    if validation_errors.any?
      error_list = validation_errors.join(", ")
      flash[:alert] = t("inspections.messages.cannot_complete",
        errors: error_list)
      redirect_to edit_inspection_path(@inspection)
      return
    end

    @inspection.complete!(current_user)
    flash[:notice] = t("inspections.messages.marked_complete")
    redirect_to @inspection
  end

  def mark_draft
    if @inspection.update(complete_date: nil)
      flash[:notice] = t("inspections.messages.marked_in_progress")
    else
      error_messages = @inspection.errors.full_messages.join(", ")
      flash[:alert] = t("inspections.messages.mark_in_progress_failed",
        errors: error_messages)
    end
    redirect_to edit_inspection_path(@inspection)
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
    send_data csv_data, filename: "inspections-#{Date.today}.csv"
  end

  def validate_tab_parameter
    return unless params[:tab].present?

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
    if Rails.env.development? || Rails.env.test?
      test_message = "In tests, use create(:inspection, :completed) to avoid this."
      raise "DATA INTEGRITY ERROR: #{error_message}. #{test_message}"
    else
      # In production, log the error but continue
      Rails.logger.error "DATA INTEGRITY ERROR: #{error_message}"
    end
  end

  SYSTEM_ATTRIBUTES = %w[inspection_id created_at updated_at].freeze

  # Build safe mappings from Inspection::ASSESSMENT_TYPES
  # This ensures mappings stay in sync with the model definition
  ASSESSMENT_TAB_MAPPING = Inspection::ASSESSMENT_TYPES.each_with_object({}) do |(method_name, _), hash|
    # Convert :user_height_assessment to "user_height"
    tab_name = method_name.to_s.gsub(/_assessment$/, "")
    hash[tab_name] = method_name
  end.freeze

  ASSESSMENT_CLASS_MAPPING = Inspection::ASSESSMENT_TYPES.each_with_object({}) do |(method_name, klass), hash|
    # Convert :user_height_assessment to "user_height"
    tab_name = method_name.to_s.gsub(/_assessment$/, "")
    hash[tab_name] = klass
  end.freeze

  def build_base_params
    params.require(:inspection).permit(*Inspection::USER_EDITABLE_PARAMS)
  end

  def add_assessment_params(base_params)
    Inspection::ASSESSMENT_TYPES.each do |ass_type, _ass_class|
      ass_key = "#{ass_type}_attributes"
      next unless params[:inspection][ass_key].present?

      ass_params = params[:inspection][ass_key]
      permitted_ass_params = assessment_permitted_attributes(ass_type)
      base_params[ass_key] = ass_params.permit(*permitted_ass_params)
    end
  end

  def assessment_permitted_attributes(assessment_type)
    model_class = "Assessments::#{assessment_type.to_s.camelize}".constantize
    all_attributes = model_class.column_names
    (all_attributes - SYSTEM_ATTRIBUTES).map { it.to_sym }
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
        *Inspection::ASSESSMENT_TYPES.keys,
        unit: {photo_attachment: :blob}
      )
      .find_by(id: params[:id]&.upcase)

    head :not_found unless @inspection
  end

  def check_inspection_owner
    return if current_user && @inspection.user_id == current_user.id

    flash[:alert] = I18n.t("inspections.errors.access_denied")
    redirect_to inspections_path
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
    unique_report_number
    unit
    updated_at
    user_id
  ]

  def set_previous_inspection
    @previous_inspection = @inspection.unit&.last_inspection
    return unless @previous_inspection

    @prefilled_fields = []

    case params[:tab]
    when "inspection", "", nil
      current_object = @inspection
      previous_object = @previous_inspection
      column_names = Inspection.column_names
    else
      # Use safe mapping instead of dynamic send
      assessment_method = ASSESSMENT_TAB_MAPPING[params[:tab]]
      return unless assessment_method

      current_object = @inspection.public_send(assessment_method)
      previous_object = @previous_inspection.public_send(assessment_method)

      # Use safe class lookup instead of constantize
      assessment_class = ASSESSMENT_CLASS_MAPPING[params[:tab]]
      return unless assessment_class

      column_names = assessment_class.column_names
    end

    column_names.each do |field|
      next if NOT_COPIED_FIELDS.include? field

      next if previous_object&.send(field).nil?
      next if current_object.send(field).nil?

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

      @prefilled_fields << translated
    end
  end
end
