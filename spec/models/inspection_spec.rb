require "rails_helper"

RSpec.describe Inspection, type: :model do
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user: user) }
  
  # Helper methods to DRY up assessment mocking
  def mock_assessment(inspection, assessment_name, complete: true)
    allow(inspection).to receive_message_chain(assessment_name, :complete?).and_return(complete)
  end
  
  def mock_all_core_assessments(inspection, complete: true)
    %i[user_height_assessment structure_assessment anchorage_assessment 
       materials_assessment fan_assessment].each do |assessment|
      mock_assessment(inspection, assessment, complete: complete)
    end
  end

  # Shared examples for common patterns
  shared_examples "a filtering scope" do |scope_name, included_record, excluded_record|
    it "includes #{included_record} and excludes #{excluded_record}" do
      expect(Inspection.public_send(scope_name)).to include(send(included_record))
      expect(Inspection.public_send(scope_name)).not_to include(send(excluded_record))
    end
  end
  
  shared_examples "a boolean method" do |method_name, attribute, truthy_value, falsy_value|
    context "when #{attribute} is #{truthy_value.class}" do
      before { inspection.send("#{attribute}=", truthy_value) }
      it "returns true" do
        expect(inspection.send(method_name)).to be_truthy
      end
    end
    
    context "when #{attribute} is #{falsy_value.inspect}" do
      before { inspection.send("#{attribute}=", falsy_value) }
      it "returns false" do
        expect(inspection.send(method_name)).to be_falsey
      end
    end
  end
  
  shared_examples "a filter scope" do |filter_method, setup_matching, setup_non_matching, test_value|
    let!(:matching) { create(:inspection).tap(&setup_matching) }
    let!(:non_matching) { create(:inspection).tap(&setup_non_matching) }
    
    it "filters when value present" do
      result = Inspection.send(filter_method, test_value)
      expect(result).to include(matching)
      expect(result).not_to include(non_matching)
    end
    
    it "returns all when value blank" do
      expect(Inspection.send(filter_method, nil)).to eq(Inspection.all)
      expect(Inspection.send(filter_method, "")).to eq(Inspection.all)
    end
  end

  describe "validations" do
    it "validates presence of required fields" do
      inspection = build(:inspection, inspection_location: nil, inspection_date: nil, complete_date: Time.current)
      expect(inspection).not_to be_valid
      expect(inspection.errors[:inspection_location]).to include("can't be blank")
    end

    it "can be created with valid attributes" do
      inspection = build(:inspection)
      expect(inspection).to be_valid
    end

    it "requires a user" do
      inspector_company = create(:inspector_company)
      inspection = build(:inspection, user: nil, inspector_company: inspector_company)
      expect(inspection).not_to be_valid
      expect(inspection.errors[:user]).to include("must exist")
    end
  end

  describe "associations" do
    it "belongs to a user" do
      association = Inspection.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "status and completion" do
    describe "#complete?" do
      it_behaves_like "a boolean method", :complete?, :complete_date, Time.current, nil
    end

    describe "#reinspection_date" do
      it "returns nil when inspection_date is nil" do
        inspection.inspection_date = nil
        expect(inspection.reinspection_date).to be_nil
      end

      it "returns inspection_date + 1 year when inspection_date is present" do
        inspection.inspection_date = Date.new(2025, 1, 1)
        expect(inspection.reinspection_date).to eq(Date.new(2026, 1, 1))
      end
    end
  end

  describe "URL routing methods" do
    %w[primary_url_path preferred_path].each do |method|
      describe "##{method}" do
        context "when complete" do
          before { inspection.complete_date = Time.current }
          
          it "returns inspection path" do
            result = inspection.send(method)
            if method == "primary_url_path"
              expect(result).to eq("inspection_path(self)")
            else
              expect(result).to include("/inspections/#{inspection.id}")
              expect(result).not_to include("/edit")
            end
          end
        end
        
        context "when draft" do
          before { inspection.complete_date = nil }
          
          it "returns edit inspection path" do
            result = inspection.send(method)
            if method == "primary_url_path"
              expect(result).to eq("edit_inspection_path(self)")
            else
              expect(result).to include("/inspections/#{inspection.id}/edit")
            end
          end
        end
      end
    end
  end

  describe "validation scopes and filters" do
    let!(:passed_inspection) { create(:inspection, :passed) }
    let!(:failed_inspection) { create(:inspection, :failed) }
    let!(:complete_inspection) { create(:inspection, :completed) }
    let!(:draft_inspection) { create(:inspection) }

    describe "scopes" do
      it_behaves_like "a filtering scope", :passed, :passed_inspection, :failed_inspection
      it_behaves_like "a filtering scope", :failed, :failed_inspection, :passed_inspection
      it_behaves_like "a filtering scope", :complete, :complete_inspection, :draft_inspection
      it_behaves_like "a filtering scope", :draft, :draft_inspection, :complete_inspection
    end

    describe "filter_by_result" do
      it "filters by passed result" do
        expect(Inspection.filter_by_result("passed")).to include(passed_inspection)
        expect(Inspection.filter_by_result("passed")).not_to include(failed_inspection)
      end

      it "filters by failed result" do
        expect(Inspection.filter_by_result("failed")).to include(failed_inspection)
        expect(Inspection.filter_by_result("failed")).not_to include(passed_inspection)
      end

      it "returns all when result is neither passed nor failed" do
        expect(Inspection.filter_by_result("other")).to eq(Inspection.all)
        expect(Inspection.filter_by_result(nil)).to eq(Inspection.all)
      end
    end

    describe "filter_by_unit" do
      let(:unit1) { create(:unit) }
      let(:unit2) { create(:unit) }
      
      it "filters by unit_id when present" do
        matching = create(:inspection, unit: unit1)
        non_matching = create(:inspection, unit: unit2)
        
        result = Inspection.filter_by_unit(unit1.id)
        expect(result).to include(matching)
        expect(result).not_to include(non_matching)
      end
      
      it "returns all when unit_id is blank" do
        expect(Inspection.filter_by_unit(nil)).to eq(Inspection.all)
        expect(Inspection.filter_by_unit("")).to eq(Inspection.all)
      end
    end
  end

  describe "advanced methods" do
    describe "#get_missing_assessments" do
      # Test core assessments
      %w[user_height structure anchorage materials fan].each do |assessment|
        it "identifies missing #{assessment} assessment" do
          mock_assessment(inspection, "#{assessment}_assessment", complete: false)
          missing = inspection.get_missing_assessments
          expect(missing).to include(I18n.t("forms.#{assessment}.header"))
        end
      end
      
      # Test conditional assessments
      {slide: :has_slide, enclosed: :is_totally_enclosed}.each do |assessment, condition|
        context "when #{condition} is true" do
          before { inspection.send("#{condition}=", true) }
          
          it "includes #{assessment} assessment when incomplete" do
            mock_assessment(inspection, "#{assessment}_assessment", complete: false)
            missing = inspection.get_missing_assessments
            expect(missing).to include(I18n.t("forms.#{assessment}.header"))
          end
        end
      end
      
      it "identifies missing unit" do
        inspection.unit = nil
        missing = inspection.get_missing_assessments
        expect(missing).to include("Unit")
      end
    end

    describe "#can_be_completed?" do
      it "returns false when unit is nil" do
        inspection.unit = nil
        expect(inspection.can_be_completed?).to be_falsey
      end

      it "returns false when not all assessments are complete" do
        mock_assessment(inspection, :user_height_assessment, complete: false)
        expect(inspection.can_be_completed?).to be_falsey
      end

      it "returns true when unit present and all assessments complete" do
        inspection.unit = create(:unit)
        mock_all_core_assessments(inspection, complete: true)
        expect(inspection.can_be_completed?).to be_truthy
      end
    end

    describe "#complete!" do
      it "sets complete_date and logs audit action" do
        inspection.complete_date = nil
        expect(inspection).to receive(:log_audit_action).with("completed", user, "Inspection completed")

        inspection.complete!(user)
        expect(inspection.complete_date).not_to be_nil
      end
    end
  end

  describe "private methods" do
    describe "#all_assessments_complete?" do
      it "returns false when core assessments incomplete" do
        mock_assessment(inspection, :user_height_assessment, complete: false)
        expect(inspection.send(:all_assessments_complete?)).to be_falsey
      end

      it "returns true when all core assessments complete" do
        mock_all_core_assessments(inspection, complete: true)
        expect(inspection.send(:all_assessments_complete?)).to be_truthy
      end

      context "conditional assessments" do
        before { mock_all_core_assessments(inspection, complete: true) }
        
        it "includes slide assessment when has_slide" do
          inspection.has_slide = true
          mock_assessment(inspection, :slide_assessment, complete: false)
          expect(inspection.send(:all_assessments_complete?)).to be_falsey
        end

        it "includes enclosed assessment when is_totally_enclosed" do
          inspection.is_totally_enclosed = true
          mock_assessment(inspection, :enclosed_assessment, complete: false)
          expect(inspection.send(:all_assessments_complete?)).to be_falsey
        end
      end
    end
  end
end