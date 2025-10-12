# typed: false
# frozen_string_literal: true

class BadgesController < ApplicationController
  before_action :require_admin
  before_action :set_badge, only: %i[show edit update]

  def show
    @badge_batch = @badge.badge_batch
    @units = Unit.where(id: @badge.id)
  end

  def edit
  end

  def update
    if @badge.update(note_params)
      flash[:success] = t("badges.messages.badge_updated")
      redirect_to badge_batch_path(@badge.badge_batch)
    else
      render :edit
    end
  end

  private

  def set_badge
    @badge = Badge.find(params[:id])
  end

  def note_params
    params.require(:badge).permit(:note)
  end
end
