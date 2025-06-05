# RPII Utility - API controller for mobile app and integrations
module Api
  module V1
    class InspectionsController < Api::BaseController
      # GET /api/v1/inspections
      def index
        @inspections = current_user.inspections.includes(:unit)
        render json: @inspections, include: [:unit]
      end

      # POST /api/v1/inspections
      def create
        @inspection = current_user.inspections.build(inspection_params)
        
        if @inspection.save
          render json: @inspection, status: :created
        else
          render json: { errors: @inspection.errors }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/inspections/:id
      def update
        @inspection = current_user.inspections.find(params[:id])
        
        if @inspection.update(inspection_params)
          render json: @inspection
        else
          render json: { errors: @inspection.errors }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/inspections/:id/sync
      # Sync offline mobile data
      def sync
        @inspection = current_user.inspections.find(params[:id])
        
        if @inspection.sync_mobile_data(params[:mobile_data])
          render json: { status: 'synced' }
        else
          render json: { errors: @inspection.errors }, status: :unprocessable_entity
        end
      end

      private

      def inspection_params
        params.require(:inspection).permit(
          :inspection_company_name, :rpii_registration_number, :place_inspected,
          :inspection_date, :testimony, :passed, :risk_assessment,
          unit_attributes: [:description, :manufacturer, :width, :length, :height, :serial_number, :unit_type, :owner]
        )
      end
    end
  end
end