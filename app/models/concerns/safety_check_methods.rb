module SafetyCheckMethods
  extend ActiveSupport::Concern

  included do
    # Automatically validate all _pass fields across all assessment models
    column_names.select { |name| name.end_with?("_pass") }.each do |pass_field|
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

  def has_critical_failures?
    self.class.column_names.any? { |col| col.end_with?("_pass") && send(col) == false }
  end

  def safety_issues_summary
    failures = self.class.column_names.select { |col| col.end_with?("_pass") && send(col) == false }
    return "No safety issues" if failures.empty?

    "Safety issues: #{failures.map(&:humanize).join(", ")}"
  end

  def critical_failure_summary
    safety_issues_summary
  end
end
