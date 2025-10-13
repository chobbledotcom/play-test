# typed: false
# frozen_string_literal: true

class BadgeBatchesController < ApplicationController
  before_action :require_admin
  before_action :set_badge_batch, only: %i[edit update]

  def index
    @badge_batches = BadgeBatch.includes(:badges).order(created_at: :desc)
  end

  def new
    @badge_batch = BadgeBatch.new
  end

  def create
    count = badge_batch_params[:count].to_i
    note = badge_batch_params[:note]

    badge_batch = BadgeBatch.create!(note: note, count: count)

    badge_ids = Badge.generate_random_ids(count)

    timestamp = Time.current
    badge_records = badge_ids.map do |id|
      { id: id, badge_batch_id: badge_batch.id, created_at: timestamp,
       updated_at: timestamp }
    end
    Badge.insert_all(badge_records)

    flash[:success] = t("badges.messages.batch_created", count: count)
    redirect_to edit_badge_batch_path(badge_batch)
  end

  def edit
    @badges = @badge_batch.badges.order(:id)
  end

  def update
    if @badge_batch.update(note_param)
      flash[:success] = t("badges.messages.batch_updated")
      redirect_to edit_badge_batch_path(@badge_batch)
    else
      render :edit
    end
  end

  def search
    query = params[:query]&.strip&.upcase

    if query.blank?
      redirect_to badge_batches_path
      return
    end

    badge = Badge.find_by(id: query)

    if badge
      flash[:success] = t("badges.messages.search_success")
      redirect_to edit_badge_path(badge)
    else
      flash[:alert] = t("badges.messages.search_not_found", query: query)
      redirect_to badge_batches_path
    end
  end

  private

  def set_badge_batch
    @badge_batch = BadgeBatch.find(params[:id])
  end

  def badge_batch_params
    params.require(:badge_batch).permit(:count, :note)
  end

  def note_param
    params.require(:badge_batch).permit(:note)
  end
end
