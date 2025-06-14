# Key DRY improvements for inspection_spec.rb:

# 1. Extract repeated assessment mocking into helper methods
def mock_assessment_complete(inspection, assessment_name, complete = true)
  allow(inspection).to receive_message_chain(assessment_name, :complete?).and_return(complete)
end

def mock_all_core_assessments_complete(inspection)
  %i[user_height_assessment structure_assessment anchorage_assessment 
     materials_assessment fan_assessment].each do |assessment|
    mock_assessment_complete(inspection, assessment)
  end
end

# 2. Use shared examples for repetitive scope tests
shared_examples "a filtering scope" do |scope_name, included_record, excluded_record|
  it "includes #{included_record} and excludes #{excluded_record}" do
    expect(Inspection.public_send(scope_name)).to include(send(included_record))
    expect(Inspection.public_send(scope_name)).not_to include(send(excluded_record))
  end
end

# Usage:
describe "scopes" do
  it_behaves_like "a filtering scope", :passed, :passed_inspection, :failed_inspection
  it_behaves_like "a filtering scope", :failed, :failed_inspection, :passed_inspection
  it_behaves_like "a filtering scope", :complete, :complete_inspection, :draft_inspection
  it_behaves_like "a filtering scope", :draft, :draft_inspection, :complete_inspection
end

# 3. DRY up the URL routing tests
describe "URL routing methods" do
  shared_examples "returns appropriate path" do |method_name, complete_path, draft_path|
    context "when complete" do
      before { inspection.complete_date = Time.current }
      it { expect(inspection.public_send(method_name)).to include(complete_path) }
    end
    
    context "when draft" do
      before { inspection.complete_date = nil }
      it { expect(inspection.public_send(method_name)).to include(draft_path) }
    end
  end
  
  it_behaves_like "returns appropriate path", :primary_url_path, "inspection_path", "edit_inspection_path"
  it_behaves_like "returns appropriate path", :preferred_path, "/inspections/", "/edit"
end

# 4. Extract filter_by_* test patterns
describe "filter scopes" do
  # Pattern for testing filter methods
  def test_filter_scope(method, param, setup_included, setup_excluded = nil)
    describe ".#{method}" do
      let!(:included) { create(:inspection).tap(&setup_included) }
      let!(:excluded) { create(:inspection).tap(&(setup_excluded || ->(_) {})) }
      
      it "filters correctly" do
        result = Inspection.public_send(method, param)
        expect(result).to include(included)
        expect(result).not_to include(excluded) if setup_excluded
      end
      
      it "returns all when param is nil" do
        expect(Inspection.public_send(method, nil)).to eq(Inspection.all)
      end
    end
  end
  
  test_filter_scope(:filter_by_unit, 123, 
    ->(i) { i.update(unit_id: 123) },
    ->(i) { i.update(unit_id: 456) })
end

# 5. DRY up the missing assessments tests
describe "#get_missing_assessments" do
  # Test each assessment type dynamically
  %w[user_height structure anchorage materials fan].each do |assessment_type|
    it "identifies missing #{assessment_type} assessment" do
      mock_assessment_complete(inspection, "#{assessment_type}_assessment", false)
      expect(inspection.get_missing_assessments).to include(
        I18n.t("forms.#{assessment_type}.header")
      )
    end
  end
  
  # Conditional assessments
  {slide: :has_slide, enclosed: :is_totally_enclosed}.each do |assessment, condition|
    context "when #{condition} is true" do
      before { inspection.public_send("#{condition}=", true) }
      
      it "includes #{assessment} when incomplete" do
        mock_assessment_complete(inspection, "#{assessment}_assessment", false)
        expect(inspection.get_missing_assessments).to include(
          I18n.t("forms.#{assessment}.header")
        )
      end
    end
  end
end

# 6. Extract validation test patterns
describe "validations" do
  # Pattern for testing presence validations
  def test_presence_validation(attribute, error_message = "can't be blank")
    it "requires #{attribute}" do
      subject = build(:inspection, attribute => nil)
      expect(subject).not_to be_valid
      expect(subject.errors[attribute]).to include(error_message)
    end
  end
  
  test_presence_validation(:inspection_date)
  
  context "when complete" do
    before { subject.complete_date = Time.current }
    test_presence_validation(:inspection_location)
  end
end

# 7. Use let! with descriptive names once
describe "comprehensive test setup" do
  # Define all test data at the top
  let!(:test_data) do
    {
      passed: create(:inspection, :passed),
      failed: create(:inspection, :failed),
      complete: create(:inspection, :completed),
      draft: create(:inspection),
      with_unit: create(:inspection, unit: create(:unit, serial: "TEST123")),
      overdue: create(:inspection, inspection_date: 2.years.ago),
      recent: create(:inspection, inspection_date: 1.month.ago)
    }
  end
  
  # Now use test_data[:key] throughout tests
  it "filters passed inspections" do
    expect(Inspection.passed).to include(test_data[:passed])
    expect(Inspection.passed).not_to include(test_data[:failed])
  end
end