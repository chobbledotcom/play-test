class RemoveModelFromUnits < ActiveRecord::Migration[8.0]
  def change
    remove_column :units, :model, :string
  end
end
