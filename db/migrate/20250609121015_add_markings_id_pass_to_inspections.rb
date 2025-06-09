class AddMarkingsIdPassToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :markings_id_pass, :boolean
  end
end
