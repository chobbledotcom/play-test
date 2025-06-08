class UnitsController < ApplicationController
  before_action :set_unit, only: [:show, :edit, :update, :destroy, :report, :qr_code]
  before_action :check_unit_owner, only: [:show, :edit, :update, :destroy]
  before_action :no_index
  skip_before_action :require_login, only: [:report, :qr_code]

  def index
    @units = current_user.units.order(created_at: :desc)

    # Apply filters
    @units = @units.overdue if params[:status] == "overdue"
    @units = @units.where(manufacturer: params[:manufacturer]) if params[:manufacturer].present?
    @units = @units.where(owner: params[:owner]) if params[:owner].present?

    @title = "Equipment"
    @title += " - Overdue" if params[:status] == "overdue"
    @title += " - #{params[:manufacturer]}" if params[:manufacturer].present?
    @title += " - #{params[:owner]}" if params[:owner].present?

    respond_to do |format|
      format.html
      format.csv { send_data unit_to_csv, filename: "unit-#{Date.today}.csv" }
    end
  end

  def show
    @inspections = @unit.inspections.order(inspection_date: :desc)

    respond_to do |format|
      format.html
      format.json { render json: {id: @unit.id, name: @unit.name, serial: @unit.serial, manufacturer: @unit.manufacturer, has_slide: @unit.has_slide} }
    end
  end

  def new
    @unit = Unit.new
  end

  def create
    @unit = current_user.units.build(unit_params)

    if @unit.save
      process_photo_if_present
      flash[:success] = "Equipment record created"
      redirect_to @unit
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @unit.update(unit_params)
      process_photo_if_present

      respond_to do |format|
        format.html do
          flash[:success] = "Equipment record updated"
          redirect_to @unit
        end
        format.json { render json: {status: "success", message: t("autosave.saved")} }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("autosave_status",
              html: "<div class='saved' style='display: inline;'>#{t("autosave.saved")}</div>")
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: {status: "error", errors: @unit.errors.full_messages} }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("autosave_status",
              html: "<div class='error' style='display: inline;'>#{t("autosave.error")}</div>")
          ]
        end
      end
    end
  end

  def destroy
    @unit.destroy
    flash[:success] = "Equipment record deleted"
    redirect_to units_path
  end

  def search
    @units = params[:query].present? ?
      current_user.units.search(params[:query]) :
      current_user.units
  end

  def report
    pdf_data = PdfGeneratorService.generate_unit_report(@unit)

    send_data pdf_data.render,
      filename: "Equipment_History_#{@unit.serial}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def qr_code
    qr_code_png = QrCodeService.generate_qr_code(@unit)

    send_data qr_code_png,
      filename: "Equipment_History_QR_#{@unit.serial}.png",
      type: "image/png",
      disposition: "inline"
  end

  def new_from_inspection
    @inspection = current_user.inspections.find_by(id: params[:id])

    unless @inspection
      flash[:danger] = I18n.t("units.errors.inspection_not_found")
      redirect_to root_path and return
    end

    if @inspection.unit.present?
      flash[:danger] = I18n.t("units.errors.inspection_has_unit")
      redirect_to inspection_path(@inspection) and return
    end

    @unit = Unit.new(user: current_user)
  end

  def create_from_inspection
    @inspection = current_user.inspections.find_by(id: params[:id])

    unless @inspection
      flash[:danger] = I18n.t("units.errors.inspection_not_found")
      redirect_to root_path and return
    end

    if @inspection.unit.present?
      flash[:danger] = I18n.t("units.errors.inspection_has_unit")
      redirect_to inspection_path(@inspection) and return
    end

    @unit = current_user.units.build(unit_params)
    @unit.copy_dimensions_from(@inspection)

    if @unit.save
      @inspection.update!(unit: @unit)
      flash[:success] = I18n.t("units.messages.created_from_inspection")
      redirect_to inspection_path(@inspection)
    else
      render :new_from_inspection, status: :unprocessable_entity
    end
  end

  private

  def unit_params
    params.require(:unit).permit(:name, :serial, :manufacturer, :photo,
      :description, :has_slide, :owner,
      :width, :length, :height, :model, :manufacture_date, :notes,
      # Basic dimension comments
      :width_comment, :length_comment, :height_comment,
      # Totally enclosed flag
      :is_totally_enclosed,
      # Anchorage dimensions
      :num_low_anchors, :num_high_anchors,
      :num_low_anchors_comment, :num_high_anchors_comment,
      # Enclosed dimensions
      :exit_number, :exit_number_comment,
      # Materials dimensions
      :rope_size, :rope_size_comment,
      # Slide dimensions
      :slide_platform_height, :slide_wall_height, :runout_value,
      :slide_first_metre_height, :slide_beyond_first_metre_height, :slide_permanent_roof,
      :slide_platform_height_comment, :slide_wall_height_comment, :runout_value_comment,
      :slide_first_metre_height_comment, :slide_beyond_first_metre_height_comment,
      :slide_permanent_roof_comment,
      # Structure dimensions
      :stitch_length, :unit_pressure_value,
      :blower_tube_length, :step_size_value, :fall_off_height_value,
      :trough_depth_value, :trough_width_value,
      # User height dimensions
      :containing_wall_height, :platform_height, :user_height,
      :users_at_1000mm, :users_at_1200mm, :users_at_1500mm, :users_at_1800mm,
      :play_area_length, :play_area_width, :negative_adjustment, :permanent_roof,
      :containing_wall_height_comment, :platform_height_comment,
      :permanent_roof_comment, :play_area_length_comment, :play_area_width_comment,
      :negative_adjustment_comment)
  end

  def no_index
    response.set_header("X-Robots-Tag", "noindex,nofollow")
  end

  def set_unit
    @unit = Unit.find_by(id: params[:id].upcase)

    unless @unit
      if action_name.in?(["report", "qr_code"])
        # For public report access, return 404 instead of redirect
        render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
      else
        flash[:danger] = "Equipment record not found"
        redirect_to units_path and return
      end
    end
  end

  def check_unit_owner
    unless @unit.user_id == current_user.id
      flash[:danger] = "Access denied"
      redirect_to units_path and return
    end
  end

  def process_photo_if_present
    nil unless @unit.photo.attached?

    # The ImageProcessorService will handle resizing when the image is displayed
    # No need to process here as Rails Active Storage handles variants on demand
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
