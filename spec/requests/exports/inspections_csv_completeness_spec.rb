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
    it "preserves the fixed inspection summary columns" do
      get inspections_path(format: :csv)

      expect(response).to have_http_status(:success)
      csv_content = response.body
      headers = CSV.parse(csv_content).first

      expect(headers).to eq(%w[
        id complete_date created_at has_slide height height_comment
        indoor_only inspection_date inspection_type is_seed is_totally_enclosed
        length length_comment operator passed pdf_last_accessed_at
        risk_assessment updated_at width width_comment
        unit_name unit_serial unit_manufacturer unit_description
        inspector_company_name inspector_user_email complete
      ])
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

    it "does not expose configuration revisions or detailed assessment answers" do
      get inspections_path(format: :csv)
      headers = CSV.parse(response.body).first

      expect(headers).not_to include(
        "checklist_revision", "has_fencing", "has_ball_pool",
        "inspection_location", "number_of_users", "fabric_strength_pass"
      )
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
