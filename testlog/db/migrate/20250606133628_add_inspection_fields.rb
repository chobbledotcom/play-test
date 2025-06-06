class AddInspectionFields < ActiveRecord::Migration[8.0]
  def change
    # Add comprehensive inspection fields to support advanced workflow
    add_column :inspections, :place_inspected, :string
    add_column :inspections, :rpii_registration_number, :string
    add_column :inspections, :unique_report_number, :string
    add_column :inspections, :inspection_company_name, :string
    add_column :inspections, :status, :string, default: "draft"
    add_column :inspections, :finalized_at, :datetime
    add_column :inspections, :finalized_by_id, :string, limit: 12
    add_column :inspections, :general_notes, :text
    add_column :inspections, :recommendations, :text
    add_column :inspections, :weather_conditions, :string
    add_column :inspections, :ambient_temperature, :decimal, precision: 5, scale: 2
    add_column :inspections, :inspector_signature, :string
    add_column :inspections, :signature_timestamp, :datetime
    add_column :inspections, :inspector_company_id, :string, limit: 12

    # Add indexes for new fields
    add_index :inspections, [:user_id, :unique_report_number], unique: true, name: "index_inspections_on_user_and_report_number"
    add_index :inspections, :status

    # Add foreign key constraints
    add_foreign_key :inspections, :users, column: :finalized_by_id
    add_foreign_key :inspections, :inspector_companies
  end
end
