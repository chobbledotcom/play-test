class UnitCsvExportService
  ATTRIBUTES = %w[id name manufacturer serial].freeze

  def initialize(units)
    @units = units
  end

  def generate
    CSV.generate(headers: true) do |csv|
      csv << ATTRIBUTES

      @units.order(created_at: :desc).each do |unit|
        csv << ATTRIBUTES.map { |attr| unit.send(attr) }
      end
    end
  end
end
