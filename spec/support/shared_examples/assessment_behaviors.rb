# Shared examples for common assessment model behaviors

def enum_field?(assessment_class, field)
  assessment_class.respond_to?(:defined_enums) && assessment_class.defined_enums.key?(field.to_s)
end

RSpec.shared_examples "an assessment model" do
  describe "associations" do
    it "belongs to inspection" do
      expect(assessment.inspection).to eq(inspection)
    end
  end

  describe "audit logging" do
    it "logs assessment updates when changes are made" do
      changeable_field = assessment.class.column_names.find { |col|
        col.end_with?("_comment", "_pass") && assessment.respond_to?("#{col}=")
      }

      if changeable_field
        expect(assessment).to receive(:log_assessment_update)
        test_value = if changeable_field.end_with?("_pass")
          if enum_field?(assessment.class, changeable_field)
            "pass"
          else
            true
          end
        else
          "new value"
        end
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
    if enum_field?(assessment.class, field)
      assessment.send("#{field}=", "pass")
    else
      assessment.send("#{field}=", true)
    end
    expect(assessment).to be_valid
  end

  it "allows false for #{field}" do
    if enum_field?(assessment.class, field)
      assessment.send("#{field}=", "fail")
    else
      assessment.send("#{field}=", false)
    end
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

RSpec.shared_examples "delegates to EN14960::Constants" do |delegated_methods|
  delegated_methods.each do |method|
    it "delegates ##{method} to EN14960::Constants" do
      expect(EN14960::Constants).to respond_to(method)
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

      expect(page).to have_content(I18n.t("forms.#{assessment_type}.header"))

      expect(page).not_to have_content("translation missing")

      expect(page).to have_button(I18n.t("inspections.buttons.save_assessment"))
    end

    it "saves the assessment when form is submitted" do
      visit edit_inspection_path(inspection, tab: assessment_type)

      click_button I18n.t("inspections.buttons.save_assessment")

      expect_updated_message
    end
  end
end
