# typed: true
# frozen_string_literal: true

class Badge < ApplicationRecord
  extend T::Sig

  include CustomIdGenerator

  belongs_to :badge_batch
end
