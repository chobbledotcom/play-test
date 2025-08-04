class CreatePages < ActiveRecord::Migration[8.0]
  def change
    create_table :pages, id: false do |t|
      t.string :slug, null: false, primary_key: true
      t.string :meta_title
      t.text :meta_description
      t.string :link_title
      t.text :content

      t.timestamps
    end
  end
end
