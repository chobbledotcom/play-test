# typed: true
# frozen_string_literal: true

module SymbolizedAttributes
  extend ActiveSupport::Concern

  def attributes
    super.symbolize_keys
  end

  def column_names
    super.map(&:to_sym)
  end
end
