require "rails_helper"

RSpec.feature "Inspections CSV Export", type: :feature do
  let(:user) { create(:user) }
  let(:unit1) { create(:unit, user: user, name: "Test Unit 1", serial: "TU001", manufacturer: "Test Mfg") }
  let(:unit2) { create(:unit, user: user, name: "Test Unit 2", serial: "TU002", manufacturer: "Test Mfg") }

  let!(:inspection1) do
    create_completed_inspection(
      user: user,
      unit: unit1,
      passed: true,
      inspection_location: "Test Location 1",
      inspection_date: Date.current
    )
  end

  let!(:inspection2) do
    create(:inspection, :draft,
      user: user,
      unit: unit2,
      passed: nil,
      inspection_location: "Test Location 2",
      inspection_date: Date.current - 1.day)
  end

  before { sign_in(user) }

  describe "CSV export functionality" do
    it "allows downloading CSV export of inspections" do
      visit inspections_path

      # Verify we can see the export link
      expect(page).to have_link("Export CSV")

      # Click the export link and check the response
      click_link "Export CSV"

      # Check that we get a CSV response
      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.response_headers["Content-Disposition"]).to include("inspections-#{Date.today}.csv")

      # Parse the CSV content
      csv_content = page.body
      csv_lines = CSV.parse(csv_content, headers: true)

      # Verify CSV structure and content
      expect(csv_lines.length).to eq(1) # Should only have complete inspection

      # Check that key headers are present (CSV includes all inspection columns)
      key_headers = %w[id inspection_date inspection_location passed risk_assessment unit_name unit_serial unit_manufacturer inspector_company_name]
      key_headers.each do |header|
        expect(csv_lines.headers).to include(header)
      end

      # Check complete inspection data (only complete inspections are exported)
      row = csv_lines.find { |row| row["unit_serial"] == "TU001" }
      expect(row).to be_present
      expect(row["unit_name"]).to eq("Test Unit 1")
      expect(row["inspection_location"]).to eq("Test Location 1")
      expect(row["unit_manufacturer"]).to eq("Test Mfg")
      expect(row["passed"]).to eq("true")

      # Draft inspection should not be in CSV
      draft_row = csv_lines.find { |row| row["unit_serial"] == "TU002" }
      expect(draft_row).to be_nil
    end

    it "exports filtered inspections when result filter is applied" do
      visit inspections_path(result: "passed")

      click_link "Export CSV"

      # Should only export passed inspections (filtering by result works)
      csv_content = page.body
      csv_lines = CSV.parse(csv_content, headers: true)

      expect(csv_lines.length).to eq(1) # Only the passed inspection
      expect(csv_lines.first["unit_serial"]).to eq("TU001")
      expect(csv_lines.first["passed"]).to eq("true")
    end

    it "handles empty inspection list gracefully" do
      # Remove all inspections
      user.inspections.destroy_all

      visit inspections_path

      # When there are no complete inspections, CSV export link should not be shown
      expect(page).not_to have_link("Export CSV")
      expect(page).to have_content("No inspection records found")
    end
  end

  describe "CSV export error handling" do
    it "raises error if CSV generation fails" do
      # Mock the CSV generation service to raise an error
      allow_any_instance_of(InspectionCsvExportService).to receive(:generate).and_raise(StandardError.new("CSV generation failed"))

      visit inspections_path

      # Currently CSV errors are not handled gracefully and will raise
      expect {
        click_link "Export CSV"
      }.to raise_error(StandardError, "CSV generation failed")
    end
  end
end
