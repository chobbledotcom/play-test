class RemoveBlowerSerialPassFailFromFanAssessments <
  ActiveRecord::Migration[8.0]
  def change
    remove_column :fan_assessments, :blower_serial_pass, :boolean
    remove_column :fan_assessments, :blower_serial_comment, :text
  end
end
