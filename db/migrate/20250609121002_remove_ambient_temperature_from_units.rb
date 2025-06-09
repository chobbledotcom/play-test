class RemoveAmbientTemperatureFromUnits < ActiveRecord::Migration[8.0]
  def change
    remove_column :units, :ambient_temperature, :decimal
  end
end
