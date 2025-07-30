class AddNumberOfBlowersToFanAssessments < ActiveRecord::Migration[8.0]
  def change
    add_column :fan_assessments, :number_of_blowers, :integer
  end
end
