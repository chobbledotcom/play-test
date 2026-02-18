# typed: true
# frozen_string_literal: true

# == Schema Information
#
# Table name: badges
#
#  id             :string(8)        not null, primary key
#  note           :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  badge_batch_id :integer          not null
#
# Indexes
#
#  index_badges_on_badge_batch_id  (badge_batch_id)
#  index_badges_on_id              (id) UNIQUE
#
# Foreign Keys
#
#  badge_batch_id  (badge_batch_id => badge_batches.id)
#
class Badge < ApplicationRecord
  extend T::Sig

  include CustomIdGenerator

  belongs_to :badge_batch
  has_one :unit, foreign_key: :id, primary_key: :id

  def badge_id = id

  def batch_note = badge_batch.note
end
