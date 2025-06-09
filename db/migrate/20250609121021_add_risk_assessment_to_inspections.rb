class AddRiskAssessmentToInspections < ActiveRecord::Migration[8.0]
  def change
    add_column :inspections, :risk_assessment, :text
  end
end
