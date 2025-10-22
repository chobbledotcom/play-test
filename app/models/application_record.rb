# typed: strict

class ApplicationRecord < ActiveRecord::Base
  extend T::Sig
  extend T::Helpers

  primary_abstract_class

  include ColumnNameSyms
end
