# typed: true
# frozen_string_literal: true

# == Schema Information
#
# Table name: badge_batches
#
#  id         :integer          not null, primary key
#  count      :integer
#  note       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class BadgeBatch < ApplicationRecord
  extend T::Sig

  has_many :badges, dependent: :destroy
end
