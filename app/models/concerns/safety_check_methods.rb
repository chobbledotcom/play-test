module SafetyCheckMethods
  extend ActiveSupport::Concern

  included do
    # Automatically validate all _pass fields across all assessment models
    column_names&.select { |name| name.end_with?("_pass") }.each do |pass_field|
      validates pass_field.to_sym, inclusion: {in: [true, false]}, allow_nil: true
    end
  end

  def pass_columns_count
    self.class.column_names.count { |col| col.end_with?("_pass") }
  end

  def passed_checks_count
    self.class.column_names.count { |col|
      col.end_with?("_pass") && send(col) == true
    }
  end

  def failed_checks_count
    self.class.column_names.count { |col|
      col.end_with?("_pass") && send(col) == false
    }
  end
end
