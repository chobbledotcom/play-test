# typed: false
# frozen_string_literal: true

class RemoveOperatorFromUnits < ActiveRecord::Migration[8.0]
  def change
    remove_column :units, :operator, :string
  end
end
