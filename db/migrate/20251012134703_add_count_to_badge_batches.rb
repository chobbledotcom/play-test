class AddCountToBadgeBatches < ActiveRecord::Migration[8.0]
  def change
    add_column :badge_batches, :count, :integer
  end
end
