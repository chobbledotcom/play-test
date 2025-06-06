class UnitsController < ApplicationController
  before_action :set_unit, only: [:show, :edit, :update, :destroy, :certificate, :qr_code]
  before_action :check_unit_owner, only: [:show, :edit, :update, :destroy]
  before_action :no_index
  skip_before_action :require_login, only: [:certificate, :qr_code]

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
      format.json { render json: {id: @unit.id, name: @unit.name, serial: @unit.serial, manufacturer: @unit.manufacturer, unit_type: @unit.unit_type} }
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
      flash[:success] = "Equipment record updated"
      redirect_to @unit
    else
      render :edit, status: :unprocessable_entity
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

  def certificate
    pdf_data = PdfGeneratorService.generate_unit_certificate(@unit)

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

  private

  def unit_params
    params.require(:unit).permit(:name, :serial, :manufacturer, :photo,
      :description, :unit_type, :owner,
      :width, :length, :height, :model, :manufacture_date, :notes)
  end

  def no_index
    response.set_header("X-Robots-Tag", "noindex,nofollow")
  end

  def set_unit
    @unit = Unit.find_by(id: params[:id].upcase)

    unless @unit
      if action_name.in?(["certificate", "qr_code"])
        # For public certificate access, return 404 instead of redirect
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
    attributes = %w[id name manufacturer serial unit_type]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      current_user.units.order(created_at: :desc).each do |unit|
        row = attributes.map { |attr| unit.send(attr) }
        csv << row
      end
    end
  end
end
