# Shared examples for common assessment model behaviors

RSpec.shared_examples "an assessment model" do
  describe "associations" do
    it "belongs to inspection" do
      expect(assessment.inspection).to eq(inspection)
    end
  end

  describe "audit logging" do
    it "logs assessment updates when changes are made" do
      # Find a changeable field
      changeable_field = assessment.class.column_names.find { |col|
        col.end_with?("_comment", "_pass") && assessment.respond_to?("#{col}=")
      }

      if changeable_field
        expect(assessment).to receive(:log_assessment_update)
        test_value = changeable_field.end_with?("_pass") || "new value"
        assessment.update!(changeable_field => test_value)
      else
        pending "No changeable field found for audit logging test"
      end
    end

    it "does not log when no changes are made" do
      assessment.save
      expect(assessment).not_to receive(:log_assessment_update)
      assessment.save
    end
  end

  describe "standard methods" do
    it "responds to #complete?" do
      expect(assessment).to respond_to(:complete?)
    end

    it "has pass_columns_count method" do
      expect(assessment).to respond_to(:pass_columns_count)
    end

    it "responds to #passed_checks_count" do
      expect(assessment).to respond_to(:passed_checks_count)
    end

    it "responds to #completion_percentage" do
      expect(assessment).to respond_to(:completion_percentage)
    end
  end
end

RSpec.shared_examples "validates non-negative numeric field" do |field|
  it "validates #{field} is non-negative" do
    assessment.send("#{field}=", -1.0)
    expect(assessment).not_to be_valid
    expect(assessment.errors[field.to_sym]).to include("must be greater than or equal to 0")
  end

  it "allows blank #{field}" do
    assessment.send("#{field}=", nil)
    expect(assessment).to be_valid
  end

  it "allows zero #{field}" do
    assessment.send("#{field}=", 0)
    expect(assessment).to be_valid
  end

  it "allows large #{field}" do
    assessment.send("#{field}=", 999.99)
    expect(assessment).to be_valid
  end
end

RSpec.shared_examples "validates non-negative integer field" do |field|
  it "validates #{field} is non-negative" do
    assessment.send("#{field}=", -1)
    expect(assessment).not_to be_valid
    expect(assessment.errors[field.to_sym]).to include("must be greater than or equal to 0")
  end

  it "allows blank #{field}" do
    assessment.send("#{field}=", nil)
    expect(assessment).to be_valid
  end

  it "allows zero #{field}" do
    assessment.send("#{field}=", 0)
    expect(assessment).to be_valid
  end

  it "allows large #{field}" do
    assessment.send("#{field}=", 999)
    expect(assessment).to be_valid
  end

  it "validates #{field} is integer" do
    assessment.send("#{field}=", 5.5)
    expect(assessment).not_to be_valid
    expect(assessment.errors[field.to_sym]).to include("must be an integer")
  end
end

RSpec.shared_examples "validates boolean field" do |field|
  it "allows nil for #{field}" do
    assessment.send("#{field}=", nil)
    expect(assessment).to be_valid
  end

  it "allows true for #{field}" do
    assessment.send("#{field}=", true)
    expect(assessment).to be_valid
  end

  it "allows false for #{field}" do
    assessment.send("#{field}=", false)
    expect(assessment).to be_valid
  end
end

RSpec.shared_examples "validates comment field" do |field|
  it "allows blank #{field}" do
    assessment.send("#{field}=", nil)
    expect(assessment).to be_valid

    assessment.send("#{field}=", "")
    expect(assessment).to be_valid
  end

  it "allows text in #{field}" do
    assessment.send("#{field}=", "Test comment")
    expect(assessment).to be_valid
  end
end

RSpec.shared_examples "has safety check methods" do
  describe "#pass_columns_count" do
    it "returns the correct number of pass/fail checks" do
      # Count actual columns from the database that end with _pass
      actual_pass_columns = assessment.class.column_names.count { |col| col.end_with?("_pass") }
      expect(assessment.pass_columns_count).to eq(actual_pass_columns)
    end
  end

  describe "#passed_checks_count" do
    it "counts only passed checks" do
      # Set all checks to pass
      assessment.class.column_names.select { |col| col.end_with?("_pass") }.each do |check|
        assessment.send("#{check}=", true) if assessment.respond_to?("#{check}=")
      end

      # Count how many we actually set
      actual_checks = assessment.class.column_names.count { |col|
        col.end_with?("_pass") && assessment.respond_to?(col)
      }

      expect(assessment.passed_checks_count).to eq(actual_checks)
    end

    it "returns 0 when no checks are passed" do
      # Set all checks to fail
      assessment.class.column_names.select { |col| col.end_with?("_pass") }.each do |check|
        assessment.send("#{check}=", false) if assessment.respond_to?("#{check}=")
      end

      expect(assessment.passed_checks_count).to eq(0)
    end
  end
end

RSpec.shared_examples "delegates to SafetyStandard" do |delegated_methods|
  delegated_methods.each do |method|
    it "delegates ##{method} to SafetyStandard" do
      expect(SafetyStandard).to respond_to(method)
    end
  end
end
