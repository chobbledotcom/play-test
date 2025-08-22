# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe BaseAssessmentBlueprint, type: :serializer do
  describe ".public_fields_for" do
    # Create a test class with known column names
    let(:test_class) do
      Class.new do
        def self.column_name_syms
          %i[
            id
            name
            description
            created_at
            updated_at
            user_id
            unit_id
            inspection_id
            inspector_company_id
            is_seed
            pdf_last_accessed_at
            custom_field_1
            custom_field_2
            status
            notes
          ]
        end
      end
    end

    context "when filtering public fields" do
      it "returns column names excluding system fields" do
        result = described_class.public_fields_for(test_class)

        # Should include these fields
        expect(result).to include(:name)
        expect(result).to include(:description)
        expect(result).to include(:custom_field_1)
        expect(result).to include(:custom_field_2)
        expect(result).to include(:status)
        expect(result).to include(:notes)
      end

      it "excludes all fields defined in PublicFieldFiltering::EXCLUDED_FIELDS" do
        result = described_class.public_fields_for(test_class)

        # Should exclude these system fields
        expect(result).not_to include(:id)
        expect(result).not_to include(:created_at)
        expect(result).not_to include(:updated_at)
        expect(result).not_to include(:user_id)
        expect(result).not_to include(:unit_id)
        expect(result).not_to include(:inspection_id)
        expect(result).not_to include(:inspector_company_id)
        expect(result).not_to include(:is_seed)
        expect(result).not_to include(:pdf_last_accessed_at)
      end

      it "returns an array of symbols" do
        result = described_class.public_fields_for(test_class)

        expect(result).to be_an(Array)
        expect(result).to all(be_a(Symbol))
      end

      it "handles classes with no columns gracefully" do
        empty_class = Class.new do
          def self.column_name_syms
            []
          end
        end

        result = described_class.public_fields_for(empty_class)

        expect(result).to eq([])
      end

      it "handles classes with only excluded fields" do
        excluded_only_class = Class.new do
          def self.column_name_syms
            %i[id created_at updated_at user_id]
          end
        end

        result = described_class.public_fields_for(excluded_only_class)

        expect(result).to eq([])
      end

      it "preserves field order from original column list" do
        ordered_class = Class.new do
          def self.column_name_syms
            %i[alpha beta gamma id delta epsilon created_at]
          end
        end

        result = described_class.public_fields_for(ordered_class)

        expect(result).to eq(%i[alpha beta gamma delta epsilon])
      end
    end

    context "with ActiveRecord models" do
      # Test with actual ActiveRecord models if available
      if defined?(MaterialsAssessment)
        it "works with MaterialsAssessment model" do
          result = described_class.public_fields_for(MaterialsAssessment)

          # Should include assessment-specific fields
          expect(result).to be_an(Array)
          expect(result).not_to include(:id)
          expect(result).not_to include(:inspection_id)
          expect(result).not_to include(:created_at)
          expect(result).not_to include(:updated_at)

          # Should include public fields (if model has any known fields)
          if MaterialsAssessment.column_names.include?("fabric_type")
            expect(result).to include(:fabric_type)
          end
        end
      end

      if defined?(AnchorsAssessment)
        it "works with AnchorsAssessment model" do
          result = described_class.public_fields_for(AnchorsAssessment)

          expect(result).to be_an(Array)
          expect(result).not_to include(:id)
          expect(result).not_to include(:inspection_id)

          # Should include anchor-specific fields (if model has any known fields)
          if AnchorsAssessment.column_names.include?("num_low_anchors")
            expect(result).to include(:num_low_anchors)
          end
        end
      end

      if defined?(GeneralAssessment)
        it "works with GeneralAssessment model" do
          result = described_class.public_fields_for(GeneralAssessment)

          expect(result).to be_an(Array)
          expect(result).not_to include(:id)
          expect(result).not_to include(:inspection_id)
        end
      end
    end

    context "edge cases" do
      it "handles duplicate fields in column list" do
        duplicate_class = Class.new do
          def self.column_name_syms
            %i[id name name description id created_at]
          end
        end

        result = described_class.public_fields_for(duplicate_class)

        # The subtraction operation keeps duplicates from the first array
        expect(result.count(:name)).to eq(2)
        expect(result.count(:description)).to eq(1)
        expect(result).not_to include(:id)
        expect(result).not_to include(:created_at)
      end

      it "returns a new array instance each time" do
        result1 = described_class.public_fields_for(test_class)
        result2 = described_class.public_fields_for(test_class)

        expect(result1).to eq(result2)
        expect(result1.object_id).not_to eq(result2.object_id)
      end

      it "does not modify the original column_name_syms array" do
        original_columns = test_class.column_name_syms.dup

        described_class.public_fields_for(test_class)

        expect(test_class.column_name_syms).to eq(original_columns)
      end
    end

    context "integration with PublicFieldFiltering" do
      it "uses the same excluded fields as PublicFieldFiltering module" do
        # Verify that the constant is accessible
        expect(PublicFieldFiltering::EXCLUDED_FIELDS).to be_an(Array)
        expect(PublicFieldFiltering::EXCLUDED_FIELDS).to include(:id, :created_at, :updated_at)
      end

      it "excludes exactly the fields defined in PublicFieldFiltering::EXCLUDED_FIELDS" do
        all_excluded_fields = PublicFieldFiltering::EXCLUDED_FIELDS

        # Create a class with all excluded fields plus some public ones
        comprehensive_class = Class.new do
          define_singleton_method(:column_name_syms) do
            all_excluded_fields + %i[public_field_1 public_field_2]
          end
        end

        result = described_class.public_fields_for(comprehensive_class)

        expect(result).to eq(%i[public_field_1 public_field_2])
      end
    end

    context "with large datasets" do
      it "handles large column lists" do
        large_class = Class.new do
          def self.column_name_syms
            # Generate a large list of columns
            fields = (1..1000).map { |i| :"field_#{i}" }
            fields + PublicFieldFiltering::EXCLUDED_FIELDS
          end
        end

        result = described_class.public_fields_for(large_class)
        
        expect(result.size).to eq(1000)
        expect(result).to all(match(/^field_\d+$/))
      end
    end
  end

  describe "inheritance and usage" do
    it "inherits from Blueprinter::Base" do
      expect(described_class.superclass).to eq(Blueprinter::Base)
    end

    it "is configured with JsonDateTransformer" do
      # Verify the transformer is defined in the class
      # Note: Blueprinter doesn't expose transformers list directly,
      # but we can verify it's set up in the class definition
      source_file = File.read(Rails.root.join("app/serializers/base_assessment_blueprint.rb"))
      expect(source_file).to include("transform JsonDateTransformer")
    end
  end
end
