# RPII Utility - PDF generation controller
class InspectionReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inspection

  # GET /inspections/:id/report.pdf
  # Generate and serve PDF report
  def show
    respond_to do |format|
      format.pdf do
        pdf = InspectionReportPdf.new(@inspection)
        send_data pdf.render,
                  filename: "RPII_Report_#{@inspection.unique_report_number}_#{Date.current}.pdf",
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end

  # POST /inspections/:id/report/email
  # Email report to stakeholders
  def email
    InspectionReportMailer.send_report(@inspection, params[:recipients]).deliver_now
    redirect_to @inspection, notice: 'Report emailed successfully.'
  end

  private

  def set_inspection
    @inspection = current_user.inspections.find(params[:inspection_id])
  end
end
