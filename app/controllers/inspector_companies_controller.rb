# RPII Utility - Company/credential management controller
class InspectorCompaniesController < ApplicationController
  before_action :authenticate_user!

  # GET /inspector_companies
  def index
    @companies = current_user.inspector_companies.order(:name)
  end

  # GET /inspector_companies/new
  def new
    @company = current_user.inspector_companies.build
  end

  # POST /inspector_companies
  def create
    @company = current_user.inspector_companies.build(company_params)
    
    if @company.save
      redirect_to inspector_companies_path, notice: 'Company profile created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /inspector_companies/:id/edit
  def edit
    @company = current_user.inspector_companies.find(params[:id])
  end

  # PATCH /inspector_companies/:id
  def update
    @company = current_user.inspector_companies.find(params[:id])
    
    if @company.update(company_params)
      redirect_to inspector_companies_path, notice: 'Company profile updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def company_params
    params.require(:inspector_company).permit(:name, :rpii_registration_number, 
                                             :logo, :address, :phone, :email)
  end
end