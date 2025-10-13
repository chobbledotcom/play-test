# typed: true
# frozen_string_literal: true

class Badge < ApplicationRecord
  extend T::Sig

  include CustomIdGenerator

  belongs_to :badge_batch
  has_one :unit, foreign_key: :id, primary_key: :id

  def badge_id = id

  def batch_note = badge_batch.note
end
