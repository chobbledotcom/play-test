class InspectorCompaniesController < ApplicationController
  before_action :set_inspector_company, only: %i[
    show edit update
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
      respond_to do |format|
        format.html do
          flash[:notice] = t("inspector_companies.messages.updated")
          redirect_to @inspector_company
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("inspector_company_save_message",
              partial: "shared/save_message",
              locals: {
                dom_id: "inspector_company_save_message",
                success: true,
                success_message: t("inspector_companies.messages.updated")
              })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("inspector_company_save_message",
              partial: "shared/save_message",
              locals: {
                dom_id: "inspector_company_save_message",
                errors: @inspector_company.errors.full_messages,
                error_message: t("shared.messages.save_failed")
              })
          ]
        end
      end
    end
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
