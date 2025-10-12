# typed: false
# frozen_string_literal: true

class BadgesController < ApplicationController
  before_action :require_admin
  before_action :set_badge_batch, only: %i[show]
  before_action :set_badge, only: %i[edit update]

  def index
    @badge_batches = BadgeBatch.includes(:badges).order(created_at: :desc)
  end

  def show
    @badges = @badge_batch.badges.order(:id)
  end

  def new
    @badge_batch = BadgeBatch.new
  end

  def create
    count = badge_batch_params[:count].to_i
    note = badge_batch_params[:note]

    badge_batch = BadgeBatch.create!(note: note)

    badge_ids = count.times.map { Badge.generate_random_id }

    Badge.insert_all(
      badge_ids.map { |id| {id: id, badge_batch_id: badge_batch.id, created_at: Time.current, updated_at: Time.current} }
    )

    flash[:success] = t("badges.messages.batch_created", count: count)
    redirect_to badge_batch_path(badge_batch)
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

  def set_badge_batch
    @badge_batch = BadgeBatch.find(params[:id])
  end

  def set_badge
    @badge = Badge.find(params[:id])
  end

  def badge_batch_params
    params.require(:badge_batch).permit(:count, :note)
  end

  def note_params
    params.require(:badge).permit(:note)
  end
end
