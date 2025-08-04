class AddIsSnippetToPages < ActiveRecord::Migration[8.0]
  def up
    add_column :pages, :is_snippet, :boolean, default: false, null: false
  end

  def down
    remove_column :pages, :is_snippet
  end
end
