class MakeInspectorCompanyOptionalInInspections < ActiveRecord::Migration[8.0]
  def change
    change_column_null :inspections, :inspector_company_id, true
  end
end
