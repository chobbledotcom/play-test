class AddMissingFieldsToEnclosedAssessment < ActiveRecord::Migration[8.0]
  def change
    add_column :enclosed_assessments, :exit_sign_visible_comment, :text
  end
end
