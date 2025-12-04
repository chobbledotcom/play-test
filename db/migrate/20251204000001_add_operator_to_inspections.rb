# typed: false
# frozen_string_literal: true

class AddOperatorToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :operator, :string
  end
end
