class RemoveSlideFieldsFromInspections < ActiveRecord::Migration[8.0]
  def change
    # Remove slide-specific fields that belong in slide_assessments
    remove_column :inspections, :slide_platform_height, :decimal
    remove_column :inspections, :slide_wall_height, :decimal
    remove_column :inspections, :runout, :decimal
    remove_column :inspections, :slide_first_metre_height, :decimal
    remove_column :inspections, :slide_beyond_first_metre_height, :decimal
    remove_column :inspections, :slide_permanent_roof, :boolean

    # Remove slide comment fields
    remove_column :inspections, :slide_platform_height_comment, :string
    remove_column :inspections, :slide_wall_height_comment, :string
    remove_column :inspections, :runout_comment, :string
    remove_column :inspections, :slide_first_metre_height_comment, :string
    remove_column :inspections, :slide_beyond_first_metre_height_comment, :string
    remove_column :inspections, :slide_permanent_roof_comment, :string

    # Remove slide pass/fail fields
    remove_column :inspections, :clamber_netting_pass, :boolean
    remove_column :inspections, :runout_pass, :boolean
    remove_column :inspections, :slip_sheet_pass, :boolean
  end
end
