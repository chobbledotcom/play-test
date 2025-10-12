# typed: true
# frozen_string_literal: true

class BadgeBatch < ApplicationRecord
  extend T::Sig

  has_many :badges, dependent: :destroy
end
