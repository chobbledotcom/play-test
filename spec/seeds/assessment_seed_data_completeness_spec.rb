require "rails_helper"
require Rails.root.join("db/seeds/seed_data")

RSpec.describe "SeedData assessment field completeness" do
  # Assessment types that have corresponding seed data methods
  assessment_types = %w[
    structure
    anchorage
    materials
    user_height
    enclosed
    slide
    fan
  ]

  assessment_types.each do |assessment_type|
    describe ".#{assessment_type}_fields" do
      let(:model_class) do
        "Assessments::#{assessment_type.classify}Assessment".constantize
      end
      let(:table_name) { "#{assessment_type}_assessments" }
      let(:seed_method) { "#{assessment_type}_fields" }

      # Get all columns from the database schema
      let(:db_columns) do
        ActiveRecord::Base.connection.columns(table_name).map(&:name)
      end

      # Columns that are system-managed and don't need to be in seed data
      let(:system_columns) do
        %w[inspection_id created_at updated_at]
      end

      # Comment fields are optional
      let(:optional_columns) do
        db_columns.select { |col| col.end_with?("_comment") }
      end

      # Fields that must be provided by seed data
      let(:required_columns) do
        db_columns - system_columns - optional_columns
      end

      context "when passed: true" do
        let(:seed_fields) { SeedData.send(seed_method, passed: true) }

        it "provides values for all required fields" do
          missing_fields = required_columns - seed_fields.keys.map(&:to_s)

          message = "SeedData.#{seed_method} is missing required fields: " +
            missing_fields.join(", ")
          expect(missing_fields).to be_empty, message
        end

        it "includes non-nil values for all provided fields" do
          # Only check fields that are actually provided
          nil_fields = seed_fields.select { |_k, v| v.nil? }.keys

          message = "SeedData.#{seed_method} has nil values for: " +
            nil_fields.join(", ")
          expect(nil_fields).to be_empty, message
        end
      end

      context "when passed: false" do
        let(:seed_fields) { SeedData.send(seed_method, passed: false) }

        it "provides values for all required fields" do
          missing_fields = required_columns - seed_fields.keys.map(&:to_s)

          message = "SeedData.#{seed_method} is missing required fields: " +
            missing_fields.join(", ")
          expect(missing_fields).to be_empty, message
        end

        it "includes non-nil values for all provided fields" do
          # Only check fields that are actually provided
          nil_fields = seed_fields.select { |_k, v| v.nil? }.keys

          message = "SeedData.#{seed_method} has nil values for: " +
            nil_fields.join(", ")
          expect(nil_fields).to be_empty, message
        end
      end

      it "doesn't include extra fields not in the database" do
        seed_fields = SeedData.send(seed_method, passed: true)
        extra_fields = seed_fields.keys.map(&:to_s) - db_columns

        message = "SeedData.#{seed_method} has extra fields not in database: " +
          extra_fields.join(", ")
        expect(extra_fields).to be_empty, message
      end
    end
  end

  describe "inspection fields" do
    let(:seed_fields) { SeedData.inspection_fields(passed: true) }
    let(:db_columns) do
      ActiveRecord::Base.connection.columns("inspections").map(&:name)
    end

    # These are handled separately or auto-generated
    let(:excluded_columns) do
      %w[
        id unit_id created_at updated_at
        inspection_type completable cached_status
        passed user_id inspector_company_id
        pdf_last_accessed_at complete_date is_seed
      ]
    end

    let(:optional_columns) do
      %w[notes risk_assessment width_comment length_comment height_comment]
    end

    let(:required_columns) do
      db_columns - excluded_columns - optional_columns
    end

    it "provides values for all required inspection fields" do
      missing_fields = required_columns - seed_fields.keys.map(&:to_s)

      message = "SeedData.inspection_fields is missing required fields: " +
        missing_fields.join(", ")
      expect(missing_fields).to be_empty, message
    end
  end
end
