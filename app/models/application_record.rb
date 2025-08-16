# typed: false

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  include ColumnNameSyms
end
