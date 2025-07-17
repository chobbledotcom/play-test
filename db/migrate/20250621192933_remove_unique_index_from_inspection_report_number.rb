class RemoveUniqueIndexFromInspectionReportNumber < ActiveRecord::Migration[8.0]
  def change
    remove_index :inspections, [ :user_id, :unique_report_number ],
      name: "index_inspections_on_user_and_report_number"

    # Add a regular non-unique index for performance
    add_index :inspections, [ :user_id, :unique_report_number ],
      name: "index_inspections_on_user_and_report_number"
  end
end
