class RenameRunoutValueToRunout < ActiveRecord::Migration[8.0]
  def change
    rename_column :inspections, :runout_value, :runout
    rename_column :inspections, :runout_value_comment, :runout_comment

    rename_column :slide_assessments, :runout_value, :runout

    rename_column :units, :runout_value, :runout
    rename_column :units, :runout_value_comment, :runout_comment
  end
end
