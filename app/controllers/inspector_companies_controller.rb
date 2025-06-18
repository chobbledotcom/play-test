class InspectorCompaniesController < ApplicationController
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
      handle_successful_update
    else
      handle_failed_update
    end
  end

  private

  def handle_successful_update
    respond_to do |format|
      format.html do
        flash[:notice] = t("inspector_companies.messages.updated")
        redirect_to @inspector_company
      end
      format.turbo_stream do
        render turbo_stream: save_message_turbo_stream(
          t("inspector_companies.messages.updated"),
          "success"
        )
      end
    end
  end

  def handle_failed_update
    respond_to do |format|
      format.html { render :edit, status: :unprocessable_entity }
      format.turbo_stream do
        render turbo_stream: save_message_turbo_stream(
          t("shared.messages.save_failed"),
          "error"
        )
      end
    end
  end

  def save_message_turbo_stream(message, type)
    [
      turbo_stream.replace("form_save_message",
        partial: "shared/save_message",
        locals: {
          element_id: "form_save_message",
          message: message,
          type: type
        })
    ]
  end

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

  def require_admin
    unless current_user&.admin?
      flash[:alert] = t("forms.session_new.status.admin_required")
      redirect_to root_path
    end
  end
end
