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
  end

  describe "validation patterns" do
    context "pass/fail fields" do
      described_class.column_names.select { |col| col.end_with?("_pass") }.each do |field|
        include_examples "validates boolean field", field
      end
    end

    context "comment fields" do
      described_class.column_names.select { |col| col.end_with?("_comment") }.each do |field|
        include_examples "validates comment field", field
      end
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

  describe "#failed_checks_count" do
    it "counts only failed checks" do
      # Set all checks to fail
      assessment.class.column_names.select { |col| col.end_with?("_pass") }.each do |check|
        assessment.send("#{check}=", false) if assessment.respond_to?("#{check}=")
      end

      actual_checks = assessment.class.column_names.count { |col|
        col.end_with?("_pass") && assessment.respond_to?(col)
      }

      expect(assessment.failed_checks_count).to eq(actual_checks)
    end
  end

  describe "#has_critical_failures?" do
    it "returns true when any check fails" do
      # Set first check to fail, rest to pass
      pass_fields = assessment.class.column_names.select { |col| col.end_with?("_pass") }
      if pass_fields.any?
        assessment.send("#{pass_fields.first}=", false)
        pass_fields[1..].each { |check| assessment.send("#{check}=", true) }
        expect(assessment.has_critical_failures?).to be true
      end
    end

    it "returns false when all checks pass" do
      # Set all checks to pass
      assessment.class.column_names.select { |col| col.end_with?("_pass") }.each do |check|
        assessment.send("#{check}=", true) if assessment.respond_to?("#{check}=")
      end

      expect(assessment.has_critical_failures?).to be false
    end

    it "returns false when all checks are nil" do
      # Set all checks to nil
      assessment.class.column_names.select { |col| col.end_with?("_pass") }.each do |check|
        assessment.send("#{check}=", nil) if assessment.respond_to?("#{check}=")
      end

      expect(assessment.has_critical_failures?).to be false
    end
  end

  describe "#safety_issues_summary" do
    it "returns no issues message when all checks pass" do
      # Set all checks to pass
      assessment.class.column_names.select { |col| col.end_with?("_pass") }.each do |check|
        assessment.send("#{check}=", true) if assessment.respond_to?("#{check}=")
      end

      expect(assessment.safety_issues_summary).to eq("No safety issues")
    end

    it "returns no issues message when all checks are nil" do
      # Set all checks to nil
      assessment.class.column_names.select { |col| col.end_with?("_pass") }.each do |check|
        assessment.send("#{check}=", nil) if assessment.respond_to?("#{check}=")
      end

      expect(assessment.safety_issues_summary).to eq("No safety issues")
    end

    it "lists failed checks when some checks fail" do
      pass_fields = assessment.class.column_names.select { |col| col.end_with?("_pass") }
      if pass_fields.any?
        # Set first check to fail
        assessment.send("#{pass_fields.first}=", false)

        expect(assessment.safety_issues_summary).to include("Safety issues:")
        expect(assessment.safety_issues_summary).to include(pass_fields.first.humanize)
      end
    end
  end

  describe "#critical_failure_summary" do
    it "aliases safety_issues_summary" do
      expect(assessment.critical_failure_summary).to eq(assessment.safety_issues_summary)
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

# Shared examples for assessment form feature tests
RSpec.shared_examples "an assessment form" do |assessment_type|
  describe "common assessment form behaviors" do
    it "displays the assessment tab in navigation" do
      visit edit_inspection_path(inspection)
      expect_assessment_tab(assessment_type)
    end

    it "navigates to the assessment form when clicking the tab" do
      visit edit_inspection_path(inspection)
      click_assessment_tab(assessment_type)

      expect(page).to have_current_path(edit_inspection_path(inspection, tab: assessment_type))
      expect(page).to have_content(I18n.t("forms.#{assessment_type}.header"))
    end

    it "displays the assessment form without errors" do
      visit edit_inspection_path(inspection, tab: assessment_type)

      # Should have the form header
      expect(page).to have_content(I18n.t("forms.#{assessment_type}.header"))

      # Should not have any translation missing errors
      expect(page).not_to have_content("translation missing")

      # Should have a save button
      expect(page).to have_button(I18n.t("inspections.buttons.save_assessment"))
    end

    it "displays assessment completion status section" do
      visit edit_inspection_path(inspection, tab: assessment_type)

      # Should have the assessment status section
      expect(page).to have_css(".assessment-status")
      expect(page).to have_content(I18n.t("shared.assessment_completion"))
    end

    it "saves the assessment when form is submitted" do
      visit edit_inspection_path(inspection, tab: assessment_type)

      # Submit the form
      click_button I18n.t("inspections.buttons.save_assessment")

      # Should show success message
      expect(page).to have_content(I18n.t("inspections.messages.updated"))
    end
  end
end
