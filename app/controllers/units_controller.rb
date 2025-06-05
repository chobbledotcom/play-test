# RPII Utility - Equipment management controller
class UnitsController < ApplicationController
  before_action :authenticate_user!

  # GET /units
  # Manage equipment library with search
  def index
    @units = current_user.units
                        .includes(:inspections)
                        .search(params[:search])
                        .order(:manufacturer, :description)
                        .page(params[:page])
  end

  # GET /units/:id
  # View unit history and inspection records
  def show
    @unit = current_user.units.find(params[:id])
    @inspections = @unit.inspections.order(inspection_date: :desc)
  end

  # GET /units/new
  def new
    @unit = current_user.units.build
  end

  # POST /units
  def create
    @unit = current_user.units.build(unit_params)
    
    if @unit.save
      redirect_to @unit, notice: 'Equipment added to library.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /units/:id/edit
  def edit
    @unit = current_user.units.find(params[:id])
  end

  # PATCH /units/:id
  def update
    @unit = current_user.units.find(params[:id])
    
    if @unit.update(unit_params)
      redirect_to @unit, notice: 'Equipment updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def unit_params
    params.require(:unit).permit(:description, :manufacturer, :width, :length, 
                                 :height, :serial_number, :unit_type, :owner, :photo)
  end
end