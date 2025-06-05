# RPII Utility - PDF generation controller
class InspectionCertificatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inspection

  # GET /inspections/:id/certificate.pdf
  # Generate and serve PDF certificate
  def show
    respond_to do |format|
      format.pdf do
        pdf = InspectionCertificatePdf.new(@inspection)
        send_data pdf.render,
                  filename: "RPII_Report_#{@inspection.unique_report_number}_#{Date.current}.pdf",
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end

  # POST /inspections/:id/certificate/email
  # Email certificate to stakeholders
  def email
    InspectionCertificateMailer.send_certificate(@inspection, params[:recipients]).deliver_now
    redirect_to @inspection, notice: 'Certificate emailed successfully.'
  end

  private

  def set_inspection
    @inspection = current_user.inspections.find(params[:inspection_id])
  end
end