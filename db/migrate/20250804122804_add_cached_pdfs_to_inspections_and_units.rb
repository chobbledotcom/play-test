class AddCachedPdfsToInspectionsAndUnits < ActiveRecord::Migration[8.0]
  def change
    # Active Storage will handle the attachments, so no table changes needed
    # The associations will be added directly to the models
  end
end
