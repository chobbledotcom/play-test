module SafetyCheckMethods
  extend ActiveSupport::Concern

  included do
    # Automatically validate all _pass fields across all assessment models
    # Skip if running in a context without database (e.g., asset precompilation)
    if respond_to?(:connected?) && connected? && table_exists?
      column_names.select { |name| name.end_with?("_pass") }.each do |pass_field|
        validates pass_field.to_sym, inclusion: {in: [true, false]}, allow_nil: true
      end
    end
  end

  def pass_columns_count
    return 0 unless self.class.connected? && self.class.table_exists?
    self.class.column_names.count { |col| col.end_with?("_pass") }
  end

  def passed_checks_count
    return 0 unless self.class.connected? && self.class.table_exists?
    self.class.column_names.count { |col|
      col.end_with?("_pass") && send(col) == true
    }
  end

  def failed_checks_count
    return 0 unless self.class.connected? && self.class.table_exists?
    self.class.column_names.count { |col|
      col.end_with?("_pass") && send(col) == false
    }
  end
end
