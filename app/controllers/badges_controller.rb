# typed: strict
# frozen_string_literal: true

class BadgesController < ApplicationController
  extend T::Sig

  before_action :require_admin
  before_action :set_badge, only: %i[edit update]

  sig { void }
  def edit
    @badge_batch = @badge.badge_batch
    @units = Unit.where(id: @badge.id)
  end

  sig { void }
  def update
    if @badge.update(note_params)
      flash[:success] = t("badges.messages.badge_updated")
      redirect_to edit_badge_batch_path(@badge.badge_batch)
    else
      render :edit
    end
  end

  private

  sig { void }
  def set_badge
    @badge = Badge.find(params[:id])
  end

  sig { returns(ActionController::Parameters) }
  def note_params
    params.require(:badge).permit(:note)
  end
end
