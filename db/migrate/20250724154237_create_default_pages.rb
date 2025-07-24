class CreateDefaultPages < ActiveRecord::Migration[8.0]
  def change
    create_table :default_pages do |t|
      t.timestamps
    end
  end
end
