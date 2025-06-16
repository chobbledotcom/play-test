require "rails_helper"

RSpec.describe PublicFieldFiltering do
  # Create test classes to test the concern
  let(:test_class) do
    Class.new do
      include PublicFieldFiltering

      def self.name
        "TestClass"
      end

      def self.column_names
        %w[
          id
          name
          email
          created_at
          updated_at
          user_id
          active
          description
        ]
      end
    end
  end

  let(:unit_class) do
    Class.new do
      include PublicFieldFiltering

      def self.name
        "Unit"
      end

      def self.column_names
        %w[
          id
          name
          serial
          manufacturer
          created_at
          updated_at
          user_id
          notes
          description
        ]
      end
    end
  end

  describe "constants" do
    describe "EXCLUDED_FIELDS" do
      it "contains system and metadata fields" do
        expected_fields = %w[
          id
          created_at
          updated_at
          pdf_last_accessed_at
          user_id
          unit_id
          inspector_company_id
          inspection_id
          is_seed
          unique_report_number
        ]

        expect(described_class::EXCLUDED_FIELDS).to eq(expected_fields)
      end

      it "is frozen to prevent modification" do
        expect(described_class::EXCLUDED_FIELDS).to be_frozen
      end
    end

    describe "PDF_EXCLUDED_FIELDS" do
      it "contains PDF-specific excluded fields" do
        expected_fields = %w[
          complete_date
          inspection_date
          inspection_location
        ]

        expect(described_class::PDF_EXCLUDED_FIELDS).to eq(expected_fields)
      end

      it "is frozen to prevent modification" do
        expect(described_class::PDF_EXCLUDED_FIELDS).to be_frozen
      end
    end

    describe "PDF_TOTAL_EXCLUDED_FIELDS" do
      it "combines EXCLUDED_FIELDS and PDF_EXCLUDED_FIELDS" do
        expected_combined = described_class::EXCLUDED_FIELDS +
          described_class::PDF_EXCLUDED_FIELDS

        expect(described_class::PDF_TOTAL_EXCLUDED_FIELDS).to eq(expected_combined)
      end

      it "is frozen to prevent modification" do
        expect(described_class::PDF_TOTAL_EXCLUDED_FIELDS).to be_frozen
      end
    end

    describe "EXCLUDED_COMPUTED_FIELDS" do
      it "contains computed field exclusions" do
        expect(described_class::EXCLUDED_COMPUTED_FIELDS).to eq(%w[reinspection_date])
      end

      it "is frozen to prevent modification" do
        expect(described_class::EXCLUDED_COMPUTED_FIELDS).to be_frozen
      end
    end

    describe "UNIT_EXCLUDED_FIELDS" do
      it "contains unit-specific excluded fields" do
        expect(described_class::UNIT_EXCLUDED_FIELDS).to eq(%w[notes])
      end

      it "is frozen to prevent modification" do
        expect(described_class::UNIT_EXCLUDED_FIELDS).to be_frozen
      end
    end
  end

  describe "class methods" do
    describe ".public_fields" do
      context "for non-Unit classes" do
        it "excludes only EXCLUDED_FIELDS" do
          expected_fields = %w[name email active description]

          expect(test_class.public_fields).to eq(expected_fields)
        end

        it "filters out system fields from column names" do
          public_fields = test_class.public_fields

          described_class::EXCLUDED_FIELDS.each do |excluded_field|
            expect(public_fields).not_to include(excluded_field)
          end
        end
      end

      context "for Unit class" do
        before do
          # Stub the class comparison to return true for Unit
          allow(unit_class).to receive(:==).with(Unit).and_return(true)
        end

        it "excludes both EXCLUDED_FIELDS and UNIT_EXCLUDED_FIELDS" do
          expected_fields = %w[name serial manufacturer description]

          expect(unit_class.public_fields).to eq(expected_fields)
        end

        it "filters out unit-specific fields" do
          public_fields = unit_class.public_fields

          described_class::UNIT_EXCLUDED_FIELDS.each do |excluded_field|
            expect(public_fields).not_to include(excluded_field)
          end
        end
      end
    end

    describe ".excluded_fields_for_assessment" do
      it "returns EXCLUDED_FIELDS regardless of class name" do
        expect(test_class.excluded_fields_for_assessment("SomeClass"))
          .to eq(described_class::EXCLUDED_FIELDS)
      end

      it "ignores the class name parameter" do
        result1 = test_class.excluded_fields_for_assessment("ClassA")
        result2 = test_class.excluded_fields_for_assessment("ClassB")

        expect(result1).to eq(result2)
        expect(result1).to eq(described_class::EXCLUDED_FIELDS)
      end

      it "returns the same exclusions for different assessment types" do
        %w[UserHeightAssessment SlideAssessment StructureAssessment].each do |assessment_type|
          expect(test_class.excluded_fields_for_assessment(assessment_type))
            .to eq(described_class::EXCLUDED_FIELDS)
        end
      end
    end
  end

  describe "integration with existing models" do
    it "is correctly included in models that use it" do
      # Test that the concern can be included without errors
      expect { test_class.new }.not_to raise_error
    end

    it "provides class methods when included" do
      expect(test_class).to respond_to(:public_fields)
      expect(test_class).to respond_to(:excluded_fields_for_assessment)
    end
  end

  describe "field filtering consistency" do
    it "maintains consistent exclusions across different contexts" do
      # Verify that constants don't accidentally overlap inappropriately
      general_exclusions = described_class::EXCLUDED_FIELDS
      pdf_exclusions = described_class::PDF_EXCLUDED_FIELDS
      unit_exclusions = described_class::UNIT_EXCLUDED_FIELDS

      # These should be distinct sets (no unintended overlap)
      expect(pdf_exclusions & general_exclusions).to be_empty
      expect(unit_exclusions & general_exclusions).to be_empty
    end

    it "ensures all constant arrays contain strings" do
      [
        described_class::EXCLUDED_FIELDS,
        described_class::PDF_EXCLUDED_FIELDS,
        described_class::UNIT_EXCLUDED_FIELDS,
        described_class::EXCLUDED_COMPUTED_FIELDS
      ].each do |field_array|
        expect(field_array).to all(be_a(String))
        expect(field_array).to all(be_present)
      end
    end
  end
end
