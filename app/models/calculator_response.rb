CalculatorResponse = Data.define(:value, :value_suffix, :breakdown) do
  def initialize(value:, value_suffix: "", breakdown: [])
    super
  end

  def to_h
    {
      value: value,
      value_suffix: value_suffix,
      breakdown: breakdown
    }
  end

  alias_method :as_json, :to_h
end
