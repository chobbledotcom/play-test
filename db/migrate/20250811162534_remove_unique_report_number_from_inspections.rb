class RemoveUniqueReportNumberFromInspections < ActiveRecord::Migration[8.0]
  def change
    # Remove the index first
    remove_index :inspections,
      name: "index_inspections_on_user_and_report_number"

    # Remove the column
    remove_column :inspections, :unique_report_number, :string
  end
end
