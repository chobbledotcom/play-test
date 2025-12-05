# typed: false

require "rails_helper"

RSpec.describe "Inspections CSV Export Completeness", type: :request do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let!(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

  before do
    login_as(user)
  end

  describe "CSV export completeness" do
    it "includes all inspection database columns (except excluded ones)" do
      get inspections_path(format: :csv)

      expect(response).to have_http_status(:success)
      csv_content = response.body
      headers = CSV.parse(csv_content).first

      # Expected exclusions (foreign keys handled separately)
      excluded_columns = %w[user_id inspector_company_id unit_id]
      expected_inspection_columns = Inspection.column_names - excluded_columns

      # All inspection columns should be present
      expected_inspection_columns.each do |column|
        expect(headers).to include(column),
          "CSV missing inspection column: #{column}. All inspection columns should be included automatically."
      end
    end

    it "includes all expected related model fields" do
      get inspections_path(format: :csv)

      csv_content = response.body
      headers = CSV.parse(csv_content).first

      # Unit fields (operator is now on inspection, not unit)
      expect(headers).to include("unit_name", "unit_serial", "unit_manufacturer", "unit_description")

      # Inspector company field
      expect(headers).to include("inspector_company_name")

      # User (inspector) fields
      expect(headers).to include("inspector_user_email")
    end

    it "exports data for all header columns" do
      get inspections_path(format: :csv)

      csv_content = response.body
      csv_data = CSV.parse(csv_content, headers: true)

      # Should have one data row
      expect(csv_data.length).to eq(1)

      row = csv_data.first

      # Check some key fields have data
      expect(row["id"]).to eq(inspection.id)
      expect(row["complete"]).to eq("true")
      expect(row["unit_name"]).to eq(unit.name)
      expect(row["inspector_company_name"]).to eq(inspection.inspector_company.name)
      expect(row["inspector_user_email"]).to eq(user.email)
    end

    it "automatically includes new inspection columns if added" do
      # This test ensures the reflection-based approach will pick up new columns
      # without requiring manual updates to the CSV export code

      get inspections_path(format: :csv)
      csv_content = response.body
      headers = CSV.parse(csv_content).first

      # Count should match all inspection columns minus exclusions plus related fields
      excluded_columns = %w[user_id inspector_company_id unit_id]
      inspection_column_count = Inspection.column_names.length - excluded_columns.length
      # unit_name, unit_serial, unit_manufacturer, unit_description +
      # inspector_company_name + inspector_user_email + complete
      related_field_count = 7

      expect(headers.length).to eq(inspection_column_count + related_field_count)
    end

    it "handles inspections without units gracefully" do
      inspection_without_unit = create(:inspection, :completed, user: user, unit: nil)

      get inspections_path(format: :csv)

      csv_content = response.body
      csv_data = CSV.parse(csv_content, headers: true)

      # Should have two data rows now
      expect(csv_data.length).to eq(2)

      # Row without unit should have empty unit fields
      row_without_unit = csv_data.find { |row| row["id"] == inspection_without_unit.id }
      expect(row_without_unit["unit_name"]).to be_nil
      expect(row_without_unit["unit_serial"]).to be_nil
    end
  end
end
