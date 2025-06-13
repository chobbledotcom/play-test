module SafetyCheckMethods
  extend ActiveSupport::Concern

  def pass_columns_count
    self.class.column_names.count { |col| col.end_with?("_pass") }
  end

  def passed_checks_count
    self.class.column_names.count { |col|
      col.end_with?("_pass") && send(col) == true
    }
  end
end
