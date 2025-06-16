require "rails_helper"

RSpec.feature "Inspections CSV Export", type: :feature do
  let(:user) { create(:user) }
  let(:unit1) { create(:unit, user: user, name: "Test Unit 1", serial: "TU001", manufacturer: "Test Mfg") }
  let(:unit2) { create(:unit, user: user, name: "Test Unit 2", serial: "TU002", manufacturer: "Test Mfg") }

  let!(:inspection1) do
    create(:inspection, :completed,
      user: user,
      unit: unit1,
      passed: true,
      inspection_location: "Test Location 1",
      inspection_date: Date.current)
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

      expect(page).to have_link("Export CSV")

      click_link "Export CSV"

      expect(page.response_headers["Content-Type"]).to include("text/csv")
      expect(page.response_headers["Content-Disposition"]).to include("inspections-#{Date.today}.csv")

      csv_content = page.body
      csv_lines = CSV.parse(csv_content, headers: true)

      expect(csv_lines.length).to eq(1) # Should only have complete inspection

      key_headers = %w[id inspection_date inspection_location passed risk_assessment unit_name unit_serial unit_manufacturer inspector_company_name]
      key_headers.each do |header|
        expect(csv_lines.headers).to include(header)
      end

      row = csv_lines.find { |row| row["unit_serial"] == "TU001" }
      expect(row).to be_present
      expect(row["unit_name"]).to eq("Test Unit 1")
      expect(row["inspection_location"]).to eq("Test Location 1")
      expect(row["unit_manufacturer"]).to eq("Test Mfg")
      expect(row["passed"]).to eq("true")

      draft_row = csv_lines.find { |row| row["unit_serial"] == "TU002" }
      expect(draft_row).to be_nil
    end

    it "exports filtered inspections when result filter is applied" do
      visit inspections_path(result: "passed")

      click_link "Export CSV"

      csv_content = page.body
      csv_lines = CSV.parse(csv_content, headers: true)

      expect(csv_lines.length).to eq(1) # Only the passed inspection
      expect(csv_lines.first["unit_serial"]).to eq("TU001")
      expect(csv_lines.first["passed"]).to eq("true")
    end

    it "handles empty inspection list gracefully" do
      user.inspections.destroy_all

      visit inspections_path

      expect(page).not_to have_link("Export CSV")
      expect(page).to have_content("No inspection records found")
    end
  end

  describe "CSV export error handling" do
    it "raises error if CSV generation fails" do
      allow_any_instance_of(InspectionCsvExportService).to receive(:generate).and_raise(StandardError.new("CSV generation failed"))

      visit inspections_path

      expect {
        click_link "Export CSV"
      }.to raise_error(StandardError, "CSV generation failed")
    end
  end
end
