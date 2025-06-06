class RemoveUserFromInspectorCompanies < ActiveRecord::Migration[8.0]
  def change
    remove_reference :inspector_companies, :user, null: false, foreign_key: true
  end
end
