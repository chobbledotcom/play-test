# typed: false
# frozen_string_literal: true

class AdminTextReplacementsController < ApplicationController
  include TurboStreamResponders

  before_action :require_admin
  before_action :set_text_replacement, only: %i[edit update destroy]

  def index
    @text_replacements = TextReplacement.order(:i18n_key)
    @tree = TextReplacement.tree_structure
  end

  def new
    @text_replacement = TextReplacement.new
    @available_keys = TextReplacement.available_i18n_keys
  end

  def create
    @text_replacement = TextReplacement.new(text_replacement_params)
    if @text_replacement.save
      respond_to do |format|
        format.html do
          msg = I18n.t("admin_text_replacements.messages.created")
          redirect_to admin_text_replacements_path, notice: msg
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "form_save_message",
            partial: "shared/save_message",
            locals: {
              message: I18n.t("admin_text_replacements.messages.created"),
              type: "success"
            }
          )
        end
      end
    else
      @available_keys = TextReplacement.available_i18n_keys
      handle_create_failure(@text_replacement)
    end
  end

  def edit
    @available_keys = TextReplacement.available_i18n_keys
  end

  def update
    if @text_replacement.update(text_replacement_params)
      respond_to do |format|
        format.html do
          msg = I18n.t("admin_text_replacements.messages.updated")
          redirect_to admin_text_replacements_path, notice: msg
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "form_save_message",
            partial: "shared/save_message",
            locals: {
              message: I18n.t("admin_text_replacements.messages.updated"),
              type: "success"
            }
          )
        end
      end
    else
      @available_keys = TextReplacement.available_i18n_keys
      handle_update_failure(@text_replacement)
    end
  end

  def destroy
    @text_replacement.destroy
    msg = I18n.t("admin_text_replacements.messages.destroyed")
    redirect_to admin_text_replacements_path, notice: msg
  end

  private

  def set_text_replacement
    @text_replacement = TextReplacement.find(params[:id])
  end

  def text_replacement_params
    params.require(:text_replacement).permit(:i18n_key, :value)
  end
end
