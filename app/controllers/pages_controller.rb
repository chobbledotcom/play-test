class PagesController < ApplicationController
  skip_before_action :require_login, only: :show
  before_action :require_admin, except: :show
  before_action :set_page, only: %i[edit update destroy]

  def index
    @pages = Page.order(:slug)
  end

  def show
    slug = params[:slug] || "/"
    @page = Page.pages.find_by(slug: slug)

    # If homepage doesn't exist, create a temporary empty page object
    if @page.nil? && slug == "/"
      @page = Page.new(
        slug: "/",
        content: "",
        meta_title: "play-test",
        meta_description: ""
      )
    elsif @page.nil?
      # For other missing pages, still raise not found
      raise ActiveRecord::RecordNotFound
    end
  end

  def new
    @page = Page.new
  end

  def create
    @page = Page.new(page_params)
    if @page.save
      redirect_to pages_path, notice: I18n.t("pages.messages.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @page.update(page_params)
      redirect_to pages_path, notice: I18n.t("pages.messages.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @page.destroy
    redirect_to pages_path, notice: I18n.t("pages.messages.destroyed")
  end

  private

  def set_page
    @page = Page.find_by!(slug: params[:id])
  end

  def page_params
    params.require(:page).permit(
      :slug,
      :meta_title,
      :meta_description,
      :link_title,
      :content,
      :is_snippet
    )
  end
end
