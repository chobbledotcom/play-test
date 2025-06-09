module NumberSanitizer
  extend ActiveSupport::Concern

  def sanitize_number_attributes
    sanitized_values = {}
    
    # Get all numeric attributes for this model
    numeric_attributes = self.class.columns.select { |col| col.type.in?([:decimal, :float, :integer]) }.map(&:name)
    
    numeric_attributes.each do |attr|
      original_value = read_attribute(attr)
      
      # Skip if value is nil
      next if original_value.nil?
      
      # Skip if value is already a clean numeric type and wasn't changed from a string
      next if original_value.is_a?(Numeric) && !attribute_changed?(attr)
      
      # Convert to string for processing
      str_value = original_value.to_s.strip
      
      # Sanitize the string value
      sanitized = sanitize_number_string(str_value)
      
      # Convert to appropriate numeric type
      column = self.class.columns.find { |col| col.name == attr }
      numeric_value = convert_to_numeric(sanitized, column.type)
      
      # Only update if the value actually changed
      if original_value != numeric_value
        # Set the sanitized value
        write_attribute(attr, numeric_value)
        sanitized_values[attr] = numeric_value
      end
    end
    
    sanitized_values
  end

  private

  def sanitize_number_string(value)
    return "0" if value.blank?
    
    # Strip all non-numeric characters except decimal points and minus signs
    sanitized = value.gsub(/[^0-9.-]/, '')
    
    # Handle case where we removed everything
    return "0" if sanitized.blank?
    
    # Handle multiple minus signs - keep only first one if at beginning
    negative = sanitized.start_with?('-')
    sanitized = sanitized.gsub('-', '')
    
    # Handle multiple decimal points - keep only the first one
    decimal_parts = sanitized.split('.')
    if decimal_parts.length > 1
      sanitized = "#{decimal_parts[0]}.#{decimal_parts[1..-1].join('')}"
    end
    
    # Add back the negative sign if it was at the beginning
    sanitized = "-#{sanitized}" if negative
    
    # Handle edge cases
    sanitized = "0" if sanitized.empty? || sanitized == "-" || sanitized == "."
    
    sanitized
  end

  def convert_to_numeric(value, column_type)
    return 0 if value.blank? || value == "0"
    
    case column_type
    when :integer
      value.to_i
    when :decimal, :float
      value.to_f
    else
      value.to_f  # Default to float for unknown numeric types
    end
  end
end