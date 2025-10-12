# typed: true
# frozen_string_literal: true

class BadgeBatch < ApplicationRecord
  extend T::Sig

  has_many :badges, dependent: :destroy

  sig { returns(Integer) }
  def badge_count = badges.count
end
