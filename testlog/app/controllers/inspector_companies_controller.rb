class InspectorCompaniesController < ApplicationController
  before_action :set_inspector_company, only: [:show, :edit, :update, :archive]
  before_action :require_login
  before_action :require_admin, except: [:show]

  def index
    @inspector_companies = InspectorCompany.active.order(:name)

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @inspector_companies = @inspector_companies.where(
        "name LIKE ? OR rpii_registration_number LIKE ?",
        search_term, search_term
      )
    end

    if params[:verified].present?
      @inspector_companies = @inspector_companies.verified if params[:verified] == "true"
    end
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
      flash[:success] = t("inspector_companies.messages.created")
      redirect_to @inspector_company
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @inspector_company.update(inspector_company_params)
      flash[:success] = t("inspector_companies.messages.updated")
      redirect_to @inspector_company
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def archive
    @inspector_company.update(active: false)
    flash[:success] = t("inspector_companies.messages.archived")
    redirect_to inspector_companies_path
  end

  private

  def set_inspector_company
    @inspector_company = InspectorCompany.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = t("inspector_companies.messages.not_found")
    redirect_to inspector_companies_path
  end

  def inspector_company_params
    params.require(:inspector_company).permit(
      :name, :rpii_registration_number, :email, :phone, :address,
      :city, :state, :postal_code, :country, :rpii_verified,
      :active, :notes, :logo
    )
  end

  def require_admin
    unless current_user&.admin?
      flash[:danger] = t("inspector_companies.messages.unauthorized")
      redirect_to root_path
    end
  end
end
