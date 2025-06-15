class ChangeBooleansToNullableWithNoDefault < ActiveRecord::Migration[7.2]
  def change
    # Remove default values and allow null for boolean fields that should be explicitly chosen
    change_column_default :inspections, :has_slide, from: false, to: nil
    change_column_default :inspections, :is_totally_enclosed, from: false, to: nil

    # Allow null values (remove the NOT NULL constraint)
    change_column_null :inspections, :has_slide, true
    change_column_null :inspections, :is_totally_enclosed, true
  end
end
