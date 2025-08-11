class RemoveUniqueReportNumberFromInspections < ActiveRecord::Migration[8.0]
  def change
    # Remove the index first (specify column for reversibility)
    remove_index :inspections, column: [:user_id, :unique_report_number],
      name: "index_inspections_on_user_and_report_number"

    # Remove the column
    remove_column :inspections, :unique_report_number, :string
  end
end
