# RPII Utility - Analytics and reporting controller
class ReportsController < ApplicationController
  before_action :authenticate_user!

  # GET /reports
  def index
    @inspection_stats = current_user.inspection_statistics
    @equipment_stats = current_user.equipment_statistics
    @compliance_trends = current_user.compliance_trends
  end

  # GET /reports/inspections
  # Detailed inspection reports with filtering
  def inspections
    @inspections = current_user.inspections
                              .includes(:unit, :inspector_company)
                              .filter_by_date_range(params[:start_date], params[:end_date])
                              .filter_by_status(params[:status])
                              .order(:inspection_date)

    respond_to do |format|
      format.html
      format.csv { send_data @inspections.to_csv }
      format.xlsx { send_data @inspections.to_xlsx }
    end
  end

  # GET /reports/compliance_summary
  # Compliance analytics dashboard
  def compliance_summary
    @pass_fail_stats = current_user.pass_fail_statistics
    @common_failures = current_user.common_failure_analysis
    @equipment_performance = current_user.equipment_performance_metrics
  end
end