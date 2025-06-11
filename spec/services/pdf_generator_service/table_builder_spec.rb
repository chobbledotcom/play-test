require "rails_helper"

RSpec.describe PdfGeneratorService::TableBuilder do
  around do |example|
    I18n.with_locale(:en) do
      example.run
    end
  end

  let(:pdf_double) { double("pdf") }
  let(:bounds_double) { double("bounds", width: 500) }
  let(:table_double) { double("table") }
  let(:cells_double) { double("cells") }
  let(:columns_double) { double("columns") }
  let(:row_double) { double("row") }

  before do
    allow(pdf_double).to receive(:bounds).and_return(bounds_double)
    allow(pdf_double).to receive(:table).and_return(table_double)
    allow(pdf_double).to receive(:text)
    allow(pdf_double).to receive(:stroke_horizontal_rule)
    allow(pdf_double).to receive(:move_down)

    allow(table_double).to receive(:cells).and_return(cells_double)
    allow(table_double).to receive(:columns).and_return(columns_double)
    allow(table_double).to receive(:row).and_return(row_double)
    allow(table_double).to receive(:column_widths=)

    allow(cells_double).to receive(:borders=)
    allow(cells_double).to receive(:padding=)
    allow(cells_double).to receive(:size=)
    allow(cells_double).to receive(:border_width=)
    allow(cells_double).to receive(:border_color=)

    allow(columns_double).to receive(:font_style=)
    allow(columns_double).to receive(:width=)

    allow(row_double).to receive(:background_color=)
    allow(row_double).to receive(:borders=)
    allow(row_double).to receive(:border_color=)
    allow(row_double).to receive(:font_style=)
    allow(row_double).to receive(:column).and_return(double("cell", text_color: "000000", font_style: :normal))
  end

  describe ".create_pdf_table" do
    let(:data) { [["Label 1", "Value 1"], ["Label 2", "Value 2"]] }

    it "creates a table with correct data and width" do
      described_class.create_pdf_table(pdf_double, data)

      expect(pdf_double).to have_received(:table).with(data, width: 500)
    end

    it "configures table styling correctly" do
      allow(pdf_double).to receive(:table).and_yield(table_double).and_return(table_double)

      described_class.create_pdf_table(pdf_double, data)

      expect(cells_double).to have_received(:borders=).with([])
      expect(cells_double).to have_received(:padding=).with(PdfGeneratorService::Configuration::TABLE_CELL_PADDING)
      expect(columns_double).to have_received(:font_style=).with(:bold)
      expect(columns_double).to have_received(:width=).with(PdfGeneratorService::Configuration::TABLE_FIRST_COLUMN_WIDTH)
    end

    it "applies row styling for all data rows" do
      allow(pdf_double).to receive(:table).and_yield(table_double).and_return(table_double)
      allow(table_double).to receive(:row).with(0..1).and_return(row_double)

      described_class.create_pdf_table(pdf_double, data)

      expect(row_double).to have_received(:background_color=).with("EEEEEE")
      expect(row_double).to have_received(:borders=).with([:bottom])
      expect(row_double).to have_received(:border_color=).with("DDDDDD")
    end

    it "yields table to block when given" do
      block_called = false
      allow(pdf_double).to receive(:table).and_yield(table_double).and_return(table_double)

      result = described_class.create_pdf_table(pdf_double, data) do |table|
        block_called = true
        expect(table).to eq(table_double)
      end

      expect(block_called).to be(true)
      expect(result).to eq(table_double)
    end

    it "returns table without yielding when no block given" do
      result = described_class.create_pdf_table(pdf_double, data)
      expect(result).to eq(table_double)
    end
  end

  describe ".create_nice_box_table" do
    let(:title) { "Test Title" }
    let(:data) { [["Label", "Value"]] }

    it "adds title with correct styling" do
      described_class.create_nice_box_table(pdf_double, title, data)

      expect(pdf_double).to have_received(:text).with(title, size: PdfGeneratorService::Configuration::HEADER_TEXT_SIZE, style: :bold)
    end

    it "adds horizontal rule and spacing" do
      described_class.create_nice_box_table(pdf_double, title, data)

      expect(pdf_double).to have_received(:stroke_horizontal_rule)
      expect(pdf_double).to have_received(:move_down).with(10)
      expect(pdf_double).to have_received(:move_down).with(15)
    end

    it "creates table with nice styling" do
      allow(pdf_double).to receive(:table).and_yield(table_double).and_return(table_double)

      described_class.create_nice_box_table(pdf_double, title, data)

      expect(cells_double).to have_received(:padding=).with(PdfGeneratorService::Configuration::NICE_TABLE_CELL_PADDING)
      expect(cells_double).to have_received(:size=).with(PdfGeneratorService::Configuration::NICE_TABLE_TEXT_SIZE)
    end

    it "yields table to block when given" do
      block_called = false
      allow(pdf_double).to receive(:table).and_yield(table_double).and_return(table_double)

      described_class.create_nice_box_table(pdf_double, title, data) do |table|
        block_called = true
        expect(table).to eq(table_double)
      end

      expect(block_called).to be(true)
    end
  end

  describe ".create_unit_details_table" do
    let(:title) { "Unit Details" }
    let(:data) { [["Description", "Test Unit", "Serial", "ABC123"]] }

    it "adds title and formatting" do
      described_class.create_unit_details_table(pdf_double, title, data)

      expect(pdf_double).to have_received(:text).with(title, size: PdfGeneratorService::Configuration::HEADER_TEXT_SIZE, style: :bold)
      expect(pdf_double).to have_received(:stroke_horizontal_rule)
      expect(pdf_double).to have_received(:move_down).with(10)
      expect(pdf_double).to have_received(:move_down).with(15)
    end

    it "configures unit-specific table styling" do
      allow(pdf_double).to receive(:table).and_yield(table_double).and_return(table_double)

      described_class.create_unit_details_table(pdf_double, title, data)

      expect(cells_double).to have_received(:padding=).with(PdfGeneratorService::Configuration::UNIT_TABLE_CELL_PADDING)
      expect(cells_double).to have_received(:size=).with(PdfGeneratorService::Configuration::UNIT_TABLE_TEXT_SIZE)
    end

    it "sets bold styling for label columns" do
      allow(pdf_double).to receive(:table).and_yield(table_double).and_return(table_double)
      allow(table_double).to receive(:columns).with(0).and_return(columns_double)
      allow(table_double).to receive(:columns).with(2).and_return(columns_double)

      described_class.create_unit_details_table(pdf_double, title, data)

      expect(columns_double).to have_received(:font_style=).with(:bold).twice
    end

    it "calculates column widths correctly" do
      allow(pdf_double).to receive(:table).and_yield(table_double).and_return(table_double)
      allow(table_double).to receive(:columns).with(0).and_return(columns_double)
      allow(table_double).to receive(:columns).with(1).and_return(columns_double)
      allow(table_double).to receive(:columns).with(2).and_return(columns_double)
      allow(table_double).to receive(:columns).with(3).and_return(columns_double)

      described_class.create_unit_details_table(pdf_double, title, data)

      label_width = PdfGeneratorService::Configuration::UNIT_LABEL_COLUMN_WIDTH
      remaining_width = 500 - (label_width * 2)
      value_width = remaining_width / 2

      expect(columns_double).to have_received(:width=).with(label_width).twice
      expect(columns_double).to have_received(:width=).with(value_width).twice
    end
  end

  describe ".create_inspection_history_table" do
    let(:title) { "Inspection History" }
    let(:company1) { create(:inspector_company, name: "Smith Inspections") }
    let(:company2) { create(:inspector_company, name: "Doe Inspections") }
    let(:user1) { create(:user, name: "John Smith", rpii_inspector_number: "RPII123", inspection_company: company1) }
    let(:user2) { create(:user, name: "Jane Doe", rpii_inspector_number: nil, inspection_company: company2) }
    let(:inspections) do
      [
        create(:inspection, :passed, inspection_date: Date.new(2024, 1, 15), user: user1, inspection_location: "Site A"),
        create(:inspection, :failed, inspection_date: Date.new(2024, 2, 20), user: user2, inspection_location: "Site B"),
        create(:inspection, inspection_date: Date.new(2024, 3, 1), user: user1, inspection_location: nil, passed: nil)
      ]
    end

    before do
      allow(pdf_double).to receive(:table).and_yield(table_double).and_return(table_double)

      # Create separate row doubles for each row to track calls properly
      @row0_double = double("row0")
      @row1_double = double("row1")
      @row2_double = double("row2")
      @row3_double = double("row3")

      allow(table_double).to receive(:row).with(0).and_return(@row0_double)
      allow(table_double).to receive(:row).with(1).and_return(@row1_double)
      allow(table_double).to receive(:row).with(2).and_return(@row2_double)
      allow(table_double).to receive(:row).with(3).and_return(@row3_double)

      [@row0_double, @row1_double, @row2_double, @row3_double].each do |row|
        allow(row).to receive(:background_color=)
        allow(row).to receive(:font_style=)
        allow(row).to receive(:column).with(1).and_return(double("cell", text_color: nil, font_style: nil))
      end

      # Mock cell styling for result column
      [@row1_double, @row2_double, @row3_double].each do |row|
        cell_double = double("cell")
        allow(cell_double).to receive(:text_color=)
        allow(cell_double).to receive(:font_style=)
        allow(row).to receive(:column).with(1).and_return(cell_double)
      end
    end

    it "adds title and formatting" do
      described_class.create_inspection_history_table(pdf_double, title, inspections)

      expect(pdf_double).to have_received(:text).with(title, size: PdfGeneratorService::Configuration::HEADER_TEXT_SIZE, style: :bold)
      expect(pdf_double).to have_received(:stroke_horizontal_rule)
      expect(pdf_double).to have_received(:move_down).with(10)
      expect(pdf_double).to have_received(:move_down).with(15)
    end

    it "creates header row with correct labels" do
      expected_header = [
        I18n.t("pdf.unit.fields.date"),
        I18n.t("pdf.unit.fields.result"),
        I18n.t("pdf.unit.fields.inspector"),
        I18n.t("pdf.inspection.fields.rpii_inspector_no"),
        I18n.t("pdf.inspection.fields.inspection_location")
      ]

      expected_data = [expected_header] + inspections.map { |i|
        [
          i.inspection_date&.strftime("%d/%m/%Y") || I18n.t("pdf.unit.fields.na"),
          i.passed ? I18n.t("pdf.unit.fields.pass") : I18n.t("pdf.unit.fields.fail"),
          i.user.name || I18n.t("pdf.unit.fields.na"),
          i.user.rpii_inspector_number || I18n.t("pdf.unit.fields.na"),
          i.inspection_location || I18n.t("pdf.unit.fields.na")
        ]
      }

      described_class.create_inspection_history_table(pdf_double, title, inspections)

      expect(pdf_double).to have_received(:table).with(expected_data, width: 500)
    end

    it "formats inspection data correctly" do
      expected_data = [
        [
          I18n.t("pdf.unit.fields.date"),
          I18n.t("pdf.unit.fields.result"),
          I18n.t("pdf.unit.fields.inspector"),
          I18n.t("pdf.inspection.fields.rpii_inspector_no"),
          I18n.t("pdf.inspection.fields.inspection_location")
        ],
        ["15/01/2024", I18n.t("pdf.unit.fields.pass"), "John Smith", "RPII123", "Site A"],
        ["20/02/2024", I18n.t("pdf.unit.fields.fail"), "Jane Doe", I18n.t("pdf.unit.fields.na"), "Site B"],
        ["01/03/2024", I18n.t("pdf.unit.fields.fail"), "John Smith", "RPII123", I18n.t("pdf.unit.fields.na")]
      ]

      described_class.create_inspection_history_table(pdf_double, title, inspections)

      expect(pdf_double).to have_received(:table).with(expected_data, width: 500)
    end

    it "configures table styling correctly" do
      described_class.create_inspection_history_table(pdf_double, title, inspections)

      expect(cells_double).to have_received(:padding=).with(PdfGeneratorService::Configuration::NICE_TABLE_CELL_PADDING)
      expect(cells_double).to have_received(:size=).with(PdfGeneratorService::Configuration::NICE_TABLE_TEXT_SIZE)
      expect(cells_double).to have_received(:border_width=).with(0.5)
      expect(cells_double).to have_received(:border_color=).with("CCCCCC")
    end

    it "applies header styling" do
      described_class.create_inspection_history_table(pdf_double, title, inspections)

      expect(@row0_double).to have_received(:background_color=).with(PdfGeneratorService::Configuration::HISTORY_TABLE_HEADER_COLOR)
      expect(@row0_double).to have_received(:font_style=).with(:bold)
    end

    it "applies alternating row colors" do
      described_class.create_inspection_history_table(pdf_double, title, inspections)

      # Rows 1, 3 (odd) get one color, row 2 (even) gets another
      expect(@row1_double).to have_received(:background_color=).with(PdfGeneratorService::Configuration::HISTORY_TABLE_ROW_COLOR)
      expect(@row2_double).to have_received(:background_color=).with(PdfGeneratorService::Configuration::HISTORY_TABLE_ALT_ROW_COLOR)
      expect(@row3_double).to have_received(:background_color=).with(PdfGeneratorService::Configuration::HISTORY_TABLE_ROW_COLOR)
    end

    it "sets column widths correctly" do
      remaining_width = 500 - PdfGeneratorService::Configuration::HISTORY_DATE_COLUMN_WIDTH -
        PdfGeneratorService::Configuration::HISTORY_RESULT_COLUMN_WIDTH -
        PdfGeneratorService::Configuration::HISTORY_RPII_COLUMN_WIDTH
      inspector_width = remaining_width * PdfGeneratorService::Configuration::HISTORY_INSPECTOR_WIDTH_PERCENT
      location_width = remaining_width * PdfGeneratorService::Configuration::HISTORY_LOCATION_WIDTH_PERCENT

      expected_widths = [
        PdfGeneratorService::Configuration::HISTORY_DATE_COLUMN_WIDTH,
        PdfGeneratorService::Configuration::HISTORY_RESULT_COLUMN_WIDTH,
        inspector_width,
        PdfGeneratorService::Configuration::HISTORY_RPII_COLUMN_WIDTH,
        location_width
      ]

      described_class.create_inspection_history_table(pdf_double, title, inspections)

      expect(table_double).to have_received(:column_widths=).with(expected_widths)
    end

    context "with empty inspections" do
      let(:empty_inspections) { [] }

      it "handles empty inspections array" do
        expected_data = [[
          I18n.t("pdf.unit.fields.date"),
          I18n.t("pdf.unit.fields.result"),
          I18n.t("pdf.unit.fields.inspector"),
          I18n.t("pdf.inspection.fields.rpii_inspector_no"),
          I18n.t("pdf.inspection.fields.inspection_location")
        ]]

        described_class.create_inspection_history_table(pdf_double, title, empty_inspections)

        expect(pdf_double).to have_received(:table).with(expected_data, width: 500)
      end
    end
  end

  describe ".build_unit_details_table" do
    context "with complete unit data" do
      let(:unit) do
        create(:unit,
          name: "Test Playground Unit",
          description: "Large playground structure",
          serial: "ABC123XYZ",
          manufacturer: "PlayCorp Ltd",
          owner: "City Council",
          width: 12.5,
          length: 8.0,
          height: 3.5,
          has_slide: true)
      end

      it "formats complete unit data correctly" do
        result = described_class.build_unit_details_table(unit, "inspection")

        expected = [
          [
            I18n.t("pdf.inspection.fields.description"),
            "Test Playground Unit",
            I18n.t("pdf.inspection.fields.serial_number_asset_id"),
            "ABC123XYZ"
          ],
          [
            I18n.t("pdf.inspection.fields.manufacturer"),
            "PlayCorp Ltd",
            I18n.t("pdf.inspection.fields.type"),
            I18n.t("pdf.inspection.fields.unit_with_slide")
          ],
          [
            I18n.t("pdf.inspection.fields.size_m"),
            "#{I18n.t("pdf.dimensions.width")}: 12.5 #{I18n.t("pdf.dimensions.length")}: 8 #{I18n.t("pdf.dimensions.height")}: 3.5",
            I18n.t("pdf.inspection.fields.owner"),
            "City Council"
          ]
        ]

        expect(result).to eq(expected)
      end

      it "shows unit with slide type when has_slide is true" do
        unit.has_slide = true
        result = described_class.build_unit_details_table(unit, "inspection")

        expect(result[1][3]).to eq(I18n.t("pdf.inspection.fields.unit_with_slide"))
      end

      it "shows standard unit type when has_slide is false" do
        unit.has_slide = false
        result = described_class.build_unit_details_table(unit, "inspection")

        expect(result[1][3]).to eq(I18n.t("pdf.inspection.fields.standard_unit"))
      end
    end

    context "with minimal unit data" do
      let(:unit) do
        build(:unit,
          name: nil,
          description: nil,
          serial: "TEST123",
          manufacturer: "Test Manufacturer",
          owner: "Test Owner",
          width: nil,
          length: nil,
          height: nil,
          has_slide: false)
      end

      it "handles missing data with appropriate fallbacks" do
        result = described_class.build_unit_details_table(unit, "unit")

        expected = [
          [
            I18n.t("pdf.inspection.fields.description"),
            "",
            I18n.t("pdf.inspection.fields.serial_number_asset_id"),
            "TEST123"
          ],
          [
            I18n.t("pdf.inspection.fields.manufacturer"),
            "Test Manufacturer",
            I18n.t("pdf.inspection.fields.type"),
            I18n.t("pdf.inspection.fields.standard_unit")
          ],
          [
            I18n.t("pdf.inspection.fields.size_m"),
            "",
            I18n.t("pdf.inspection.fields.owner"),
            "Test Owner"
          ]
        ]

        expect(result).to eq(expected)
      end
    end

    context "with partial dimension data" do
      let(:unit) do
        build(:unit,
          name: "Partial Unit",
          width: 10.0,
          length: nil,
          height: 4.0,
          has_slide: false)
      end

      it "includes only present dimensions" do
        result = described_class.build_unit_details_table(unit, "inspection")

        expected_dimensions = "#{I18n.t("pdf.dimensions.width")}: 10 #{I18n.t("pdf.dimensions.height")}: 4"
        expect(result[2][1]).to eq(expected_dimensions)
      end
    end

    context "with empty manufacturer" do
      let(:unit) do
        build(:unit,
          manufacturer: "",
          name: "Test Unit")
      end

      it "shows empty string for empty manufacturer" do
        result = described_class.build_unit_details_table(unit, "inspection")

        expect(result[1][1]).to eq("")
      end
    end

    context "with long unit name" do
      let(:unit) do
        create(:unit,
          name: "This is a very long unit name that exceeds the maximum allowed length and should be truncated properly",
          description: "Also a very long description that should be considered when name is nil")
      end

      it "truncates long unit name" do
        allow(PdfGeneratorService::Utilities).to receive(:truncate_text).and_call_original

        described_class.build_unit_details_table(unit, "inspection")

        expect(PdfGeneratorService::Utilities).to have_received(:truncate_text).with(
          unit.name,
          PdfGeneratorService::Configuration::UNIT_NAME_MAX_LENGTH
        )
      end

      it "falls back to description when name is nil" do
        unit.name = nil
        allow(PdfGeneratorService::Utilities).to receive(:truncate_text).and_call_original

        described_class.build_unit_details_table(unit, "inspection")

        expect(PdfGeneratorService::Utilities).to have_received(:truncate_text).with(
          unit.description,
          PdfGeneratorService::Configuration::UNIT_NAME_MAX_LENGTH
        )
      end
    end

    context "with different contexts" do
      let(:unit) { create(:unit, name: "Test Unit") }

      it "uses correct I18n keys for inspection context" do
        result = described_class.build_unit_details_table(unit, "inspection")

        # Should contain inspection-specific I18n keys
        expect(result.flatten).to include(I18n.t("pdf.inspection.fields.description"))
        expect(result.flatten).to include(I18n.t("pdf.inspection.fields.serial_number_asset_id"))
      end

      it "shows empty string when name and description are nil" do
        unit.name = nil
        unit.description = nil
        result = described_class.build_unit_details_table(unit, "unit")

        # Should show empty string instead of N/A
        expect(result[0][1]).to eq("")
      end
    end
  end
end
