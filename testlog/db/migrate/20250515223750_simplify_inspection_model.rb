class SimplifyInspectionModel < ActiveRecord::Migration[8.0]
  def change
    # Remove columns we no longer need
    remove_column :inspections, :description
    remove_column :inspections, :equipment_class
    remove_column :inspections, :visual_pass
    remove_column :inspections, :fuse_rating
    remove_column :inspections, :earth_ohms
    remove_column :inspections, :insulation_mohms
    remove_column :inspections, :leakage
    remove_column :inspections, :image_path
    remove_column :inspections, :appliance_plug_check
    remove_column :inspections, :equipment_power
    remove_column :inspections, :load_test
    remove_column :inspections, :rcd_trip_time

    # Keep: serial, location, comments, inspection_date, reinspection_date, passed, pdf_last_accessed_at, inspector, manufacturer
  end
end
