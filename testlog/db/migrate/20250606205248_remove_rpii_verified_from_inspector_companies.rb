class RemoveRpiiVerifiedFromInspectorCompanies < ActiveRecord::Migration[8.0]
  def change
    remove_column :inspector_companies, :rpii_verified, :boolean
  end
end
