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

    it "handles classes with only excluded fields" do
      excluded_only_class = Class.new do
        def self.column_name_syms
          %i[id created_at updated_at user_id]
        end
      end

      result = described_class.public_fields_for(excluded_only_class)

      expect(result).to eq([])
    end

    it "uses PublicFieldFiltering::EXCLUDED_FIELDS constant" do
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
end