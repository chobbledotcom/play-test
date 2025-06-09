class AddEntrapmentPassToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :entrapment_pass, :boolean
  end
end
