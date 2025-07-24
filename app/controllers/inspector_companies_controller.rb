class InspectorCompaniesController < ApplicationController
  include TurboStreamResponders

  before_action :set_inspector_company, only: %i[
    show edit update
  ]
  before_action :require_login
  before_action :require_admin, except: [:show]

  def index
    @inspector_companies = InspectorCompany
      .with_attached_logo
      .by_status(params[:active])
      .search_by_term(params[:search])
      .order(:name)
  end

  def show
    @company_stats = @inspector_company.company_statistics
    @recent_inspections = @inspector_company.recent_inspections(5)
  end

  def new
    @inspector_company = InspectorCompany.new
    @inspector_company.country = "UK"
  end

  def create
    @inspector_company = InspectorCompany.new(inspector_company_params)

    if @inspector_company.save
      handle_create_success(@inspector_company)
    else
      handle_create_failure(@inspector_company)
    end
  end

  def edit
  end

  def update
    if @inspector_company.update(inspector_company_params)
      handle_update_success(@inspector_company)
    else
      handle_update_failure(@inspector_company)
    end
  end

  private

  def set_inspector_company
    @inspector_company = InspectorCompany.find(params[:id])
  end

  def inspector_company_params
    params.require(:inspector_company).permit(
      :name, :email, :phone, :address,
      :city, :postal_code, :country,
      :active, :notes, :logo
    )
  end
end
