class AddExitSignVisiblePassToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :exit_sign_visible_pass, :boolean
  end
end
