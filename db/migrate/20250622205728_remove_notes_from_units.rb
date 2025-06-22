class RemoveNotesFromUnits < ActiveRecord::Migration[8.0]
  def change
    remove_column :units, :notes, :text
  end
end
