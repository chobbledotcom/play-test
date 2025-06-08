class RemoveWeatherFieldsFromInspections < ActiveRecord::Migration[8.0]
  def change
    remove_column :inspections, :weather_conditions, :string
    remove_column :inspections, :ambient_temperature, :decimal, precision: 5, scale: 2
  end
end
