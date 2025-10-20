# typed: false
# frozen_string_literal: true

class AdminTextReplacementsController < ApplicationController
  include TurboStreamResponders

  before_action :require_admin
  before_action :set_text_replacement, only: %i[destroy]

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
      handle_create_success(
        @text_replacement,
        "admin_text_replacements.messages.created",
        admin_text_replacements_path
      )
    else
      @available_keys = TextReplacement.available_i18n_keys
      handle_create_failure(@text_replacement)
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
