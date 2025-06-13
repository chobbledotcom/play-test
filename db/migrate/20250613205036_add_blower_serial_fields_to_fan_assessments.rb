class AddBlowerSerialFieldsToFanAssessments < ActiveRecord::Migration[8.0]
  def change
    add_column :fan_assessments, :blower_serial_pass, :boolean
    add_column :fan_assessments, :blower_serial_comment, :text
  end
end
