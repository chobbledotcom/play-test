# RPII Utility - API controller for equipment library
module Api
  module V1
    class UnitsController < Api::BaseController
      # Equipment library API for mobile app
      def index
        @units = current_user.units.includes(:inspections)
        render json: @units, include: [:inspections]
      end

      def show
        @unit = current_user.units.find(params[:id])
        render json: @unit, include: [:inspections]
      end

      def create
        @unit = current_user.units.build(unit_params)
        
        if @unit.save
          render json: @unit, status: :created
        else
          render json: { errors: @unit.errors }, status: :unprocessable_entity
        end
      end

      private

      def unit_params
        params.require(:unit).permit(:description, :manufacturer, :width, :length, 
                                     :height, :serial_number, :unit_type, :owner)
      end
    end
  end
end