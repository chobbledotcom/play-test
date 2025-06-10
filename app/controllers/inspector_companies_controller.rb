class InspectorCompaniesController < ApplicationController
  before_action :set_inspector_company, only: %i[
    show edit update archive unarchive
  ]
  before_action :require_login
  before_action :require_admin, except: [:show]

  def index
    @inspector_companies = InspectorCompany
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
      flash[:notice] = t("inspector_companies.messages.created")
      redirect_to @inspector_company
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @inspector_company.update(inspector_company_params)
      flash[:notice] = t("inspector_companies.messages.updated")
      redirect_to @inspector_company
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def archive
    @inspector_company.update(active: false)
    flash[:notice] = t("inspector_companies.messages.archived")
    redirect_to inspector_companies_path
  end

  def unarchive
    @inspector_company.update(active: true)
    flash[:notice] = t("inspector_companies.messages.unarchived")
    redirect_to inspector_companies_path
  end

  private

  def set_inspector_company
    @inspector_company = InspectorCompany.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = t("inspector_companies.messages.not_found")
    redirect_to inspector_companies_path
  end

  def inspector_company_params
    params.require(:inspector_company).permit(
      :name, :email, :phone, :address,
      :city, :postal_code, :country,
      :active, :notes, :logo
    )
  end

  def require_admin
    unless current_user&.admin?
      flash[:alert] = t("inspector_companies.messages.unauthorized")
      redirect_to root_path
    end
  end
end
