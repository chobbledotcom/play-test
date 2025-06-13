class RemoveSignatureAndNotesFromInspections < ActiveRecord::Migration[8.0]
  def change
    remove_column :inspections, :inspector_signature, :string
    remove_column :inspections, :signature_timestamp, :datetime
    remove_column :inspections, :general_notes, :text
    remove_column :inspections, :recommendations, :text
    remove_column :inspections, :comments, :text
  end
end