# typed: true
# frozen_string_literal: true

class Badge < ApplicationRecord
  extend T::Sig

  include CustomIdGenerator

  belongs_to :badge_batch

  def badge_id = id

  def batch_note = badge_batch.note
end
