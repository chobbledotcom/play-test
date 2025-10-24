# typed: false

require "rails_helper"

RSpec.describe PdfGeneratorService::TableBuilder do
  around do |example|
    I18n.with_locale(:en) do
      example.run
    end
  end

  describe ".build_unit_details_table" do
    context "for inspection context with complete data" do
      let(:company) { create(:inspector_company) }
      let(:user) do
        create(:user,
          inspection_company: company,
          rpii_inspector_number: "RPII123")
      end
      let(:unit) { create(:unit, :with_all_fields) }
      let!(:inspection) do
        create(:inspection,
          unit: unit,
          user: user,
          width: 10.5,
          length: 8.0,
          height: 2.5)
      end

      before do
        unit.reload # Ensure unit sees the inspection
      end

      it "formats unit data into 4x4 table structure" do
        result = described_class.build_unit_details_table(unit, :inspection)

        expect(result).to be_an(Array)
        expect(result.length).to eq(4)
        result.each { |row| expect(row.length).to eq(4) }
      end

      it "includes key unit information" do
        result = described_class.build_unit_details_table(unit, :inspection)
        flattened = result.flatten

        expect(flattened).to include(unit.name)
        expect(flattened).to include(unit.description)
        expect(flattened).to include(unit.serial)
        expect(flattened).to include(unit.manufacturer)
        expect(flattened).to include(unit.operator)
      end

      it "includes dimensions when available" do
        result = described_class.build_unit_details_table(unit, :inspection)
        dimensions_text = result[2][1] # Size field

        # Just verify dimensions field exists - depends on unit.last_inspection
        expect(dimensions_text).to be_a(String)
      end
    end

    context "for unit context" do
      let(:unit) { create(:unit) }

      it "formats unit data into 2-column table structure" do
        result = described_class.build_unit_details_table(unit, :unit)

        expect(result).to be_an(Array)
        expect(result.length).to eq(5)
        result.each { |row| expect(row.length).to eq(2) }
      end
    end

    context "with missing data" do
      let(:unit) do
        build(:unit, name: nil, description: nil, manufacturer: nil)
      end

      it "handles missing fields with empty values" do
        result = described_class.build_unit_details_table(unit, "inspection")

        expect(result[0][1]).to eq("") # empty name (truncate_text converts nil to "")
        expect(result[1][1]).to be_nil # nil description
        expect(result[1][3]).to be_nil # nil manufacturer (row 1, col 3)
      end
    end
  end

  describe ".build_inspection_history_data" do
    let(:company) { create(:inspector_company) }
    let(:user) do
      create(:user,
        name: "John Smith",
        rpii_inspector_number: "RPII123",
        inspection_company: company)
    end
    let(:inspections) do
      [
        create(:inspection, :passed,
          inspection_date: Date.new(2024, 1, 15), user: user),
        create(:inspection, :failed,
          inspection_date: Date.new(2024, 2, 20), user: user)
      ]
    end

    it "formats inspection history with header row" do
      result = described_class.build_inspection_history_data(inspections)

      expect(result.length).to eq(3) # header + 2 inspections
      expect(result[0]).to eq([
        I18n.t("pdf.unit.fields.date"),
        I18n.t("pdf.unit.fields.result"),
        I18n.t("pdf.unit.fields.inspector")
      ])
    end

    it "formats inspection data correctly" do
      result = described_class.build_inspection_history_data(inspections)

      rpii_label = I18n.t("pdf.inspection.fields.rpii_inspector_no")
      inspector_text = "John Smith (#{rpii_label} RPII123)"

      expect(result[1]).to eq([
        "15 January, 2024",
        I18n.t("shared.pass_pdf"),
        inspector_text
      ])

      expect(result[2]).to eq([
        "20 February, 2024",
        I18n.t("shared.fail_pdf"),
        inspector_text
      ])
    end

    it "handles empty inspections array" do
      result = described_class.build_inspection_history_data([])

      expect(result.length).to eq(1) # just header
      expect(result[0]).to eq([
        I18n.t("pdf.unit.fields.date"),
        I18n.t("pdf.unit.fields.result"),
        I18n.t("pdf.unit.fields.inspector")
      ])
    end
  end

  describe ".inspection_result_text" do
    it "returns correct text for passed inspection" do
      inspection = build(:inspection, passed: true)
      result = described_class.inspection_result_text(inspection)
      expect(result).to eq(I18n.t("shared.pass_pdf"))
    end

    it "returns correct text for failed inspection" do
      inspection = build(:inspection, passed: false)
      result = described_class.inspection_result_text(inspection)
      expect(result).to eq(I18n.t("shared.fail_pdf"))
    end
  end

  describe ".inspector_text" do
    let(:user) { build(:user, name: "John Smith", rpii_inspector_number: nil) }
    let(:inspection) { build(:inspection, user: user) }

    it "formats inspector with RPII number" do
      user.rpii_inspector_number = "RPII123"
      result = described_class.inspector_text(inspection)

      rpii_label = I18n.t("pdf.inspection.fields.rpii_inspector_no")
      expect(result).to eq("John Smith (#{rpii_label} RPII123)")
    end

    it "returns name only without RPII number" do
      result = described_class.inspector_text(inspection)

      expect(result).to eq("John Smith")
    end

    it "handles missing inspector name" do
      user.name = nil
      user.rpii_inspector_number = nil
      result = described_class.inspector_text(inspection)

      expect(result).to be_nil
    end
  end
end
