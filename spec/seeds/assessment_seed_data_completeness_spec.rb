# typed: false

require "rails_helper"
require Rails.root.join("db/seeds/seed_data")

RSpec.describe "SeedData field completeness" do
  # NOTE: Assessment seed data tests have been moved to the en14960-assessments gem

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
