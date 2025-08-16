# typed: strict
# frozen_string_literal: true

module ColumnNameSyms
  extend T::Sig
  extend ActiveSupport::Concern

  class_methods do
    extend T::Sig

    sig { returns(T::Array[Symbol]) }
    def column_name_syms
      column_names.map(&:to_sym).sort
    end
  end
end
