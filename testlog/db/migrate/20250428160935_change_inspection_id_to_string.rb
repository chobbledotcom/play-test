class ChangeInspectionIdToString < ActiveRecord::Migration[7.2]
  def up
    # For SQLite, we need a different approach
    # Create a new table with the structure we want
    create_table :new_inspections, id: false do |t|
      t.string :id, limit: 12, primary_key: true
      t.datetime :inspection_date
      t.datetime :reinspection_date
      t.string :inspector
      t.string :serial
      t.string :description
      t.string :location
      t.integer :equipment_class
      t.boolean :visual_pass
      t.integer :fuse_rating
      t.decimal :earth_ohms
      t.integer :insulation_mohms
      t.decimal :leakage
      t.boolean :passed
      t.text :comments
      t.string :image_path
      t.integer :user_id, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.boolean :appliance_plug_check, default: false
      t.integer :equipment_power
      t.boolean :load_test, default: false
      t.decimal :rcd_trip_time, precision: 5, scale: 2
      t.string :manufacturer
    end

    # Copy indexes
    add_index :new_inspections, :serial
    add_index :new_inspections, :user_id

    # Generate random IDs and copy data
    execute <<-SQL
      INSERT INTO new_inspections 
      SELECT 
        lower(hex(randomblob(6))), 
        inspection_date, 
        reinspection_date,
        inspector,
        serial,
        description,
        location,
        equipment_class,
        visual_pass,
        fuse_rating,
        earth_ohms,
        insulation_mohms,
        leakage,
        passed,
        comments,
        image_path,
        user_id,
        created_at,
        updated_at,
        appliance_plug_check,
        equipment_power,
        load_test,
        rcd_trip_time,
        manufacturer
      FROM inspections
    SQL

    # Update active storage attachments
    add_column :active_storage_attachments, :new_record_id, :string

    # Create a mapping table to match old IDs to new IDs
    create_table :id_mapping, id: false do |t|
      t.integer :old_id
      t.string :new_id
    end

    execute <<-SQL
      INSERT INTO id_mapping
      SELECT i.id, ni.id
      FROM inspections i
      JOIN new_inspections ni ON 
        i.inspection_date = ni.inspection_date AND
        i.serial = ni.serial AND
        i.description = ni.description
    SQL

    execute <<-SQL
      UPDATE active_storage_attachments
      SET new_record_id = (
        SELECT new_id FROM id_mapping 
        WHERE old_id = record_id
      )
      WHERE record_type = 'Inspection'
    SQL

    # Replace the tables
    rename_table :inspections, :old_inspections
    rename_table :new_inspections, :inspections

    # Update the foreign keys
    rename_column :active_storage_attachments, :record_id, :old_record_id
    rename_column :active_storage_attachments, :new_record_id, :record_id

    # Add foreign key
    add_foreign_key :inspections, :users

    # Clean up
    drop_table :old_inspections
    drop_table :id_mapping
    remove_column :active_storage_attachments, :old_record_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
