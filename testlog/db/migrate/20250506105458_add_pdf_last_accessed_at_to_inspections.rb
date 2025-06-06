class AddPdfLastAccessedAtToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :pdf_last_accessed_at, :datetime
  end
end
