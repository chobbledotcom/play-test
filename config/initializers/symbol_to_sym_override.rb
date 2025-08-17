# frozen_string_literal: true

# Override Symbol#to_sym to raise an error when called on a Symbol
# This helps catch redundant to_sym calls in the codebase
class Symbol
  # Store the original to_sym method
  alias_method :original_to_sym, :to_sym

  # Override to_sym to raise an error since calling to_sym on a Symbol is redundant
  def to_sym
    raise ArgumentError, "Calling to_sym on a Symbol is redundant. The object is already a Symbol: :#{self}"
  end
end