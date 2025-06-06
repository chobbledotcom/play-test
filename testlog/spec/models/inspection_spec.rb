require "rails_helper"

RSpec.describe Inspection, type: :model do
  let(:user) { create(:user) }

  describe "validations" do
    it "validates presence of required fields" do
      inspection = build(:inspection, inspector: nil, location: nil, inspection_date: nil, place_inspected: nil)
      expect(inspection).not_to be_valid
      expect(inspection.errors[:inspector]).to include("can't be blank")
      expect(inspection.errors[:location]).to include("can't be blank")
    end

    it "can be created with valid attributes" do
      inspection = build(:inspection)
      expect(inspection).to be_valid
    end

    it "requires a user" do
      inspection = build(:inspection, user: nil)
      expect(inspection).not_to be_valid
      expect(inspection.errors[:user]).to include("must exist")
    end
  end

  describe "associations" do
    it "belongs to a user" do
      association = Inspection.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "esoteric tests" do
    # Test with Unicode characters and emoji in text fields
    it "handles Unicode characters and emoji in text fields" do
      inspection = create(:inspection, :with_unicode_data)

      # Retrieve and verify data is intact
      retrieved = Inspection.find(inspection.id)
      expect(retrieved.inspector).to eq("Jörgen Müller 👨‍🔧")
      expect(retrieved.unit.serial).to match(/ÜNICØDÉ-😎-\d+/)
      expect(retrieved.comments).to eq("❗️Tested with special 🔌 adapter. Result: ✅")
    end

    # Test with maximum possible database field lengths
    it "handles maximum length strings in text fields" do
      inspection = create(:inspection, :max_length_comments)
      extremely_long_text = "A" * 65535  # Text field typical max size

      # Verify the extremely long comment was saved correctly
      retrieved = Inspection.find(inspection.id)
      expect(retrieved.comments).to eq(extremely_long_text)
    end

    # Test with SQL injection attempts in string fields
    it "safely handles strings that look like SQL injection attempts" do
      inspection = create(:inspection, :sql_injection_test)

      # Verify the data was saved correctly and didn't affect the database
      retrieved = Inspection.find(inspection.id)
      expect(retrieved.inspector).to eq("Robert'); DROP TABLE inspections; --")

      # Verify all inspections still exist
      expect(Inspection.count).to be >= 1
    end

    # Test search functionality with special characters
    it "performs search with special characters" do
      # Create unit and inspection with special characters in serial
      special_unit = create(:unit, serial: "SPEC!@#$%^&*()_+")
      create(:inspection, unit: special_unit)

      # Test searching for various patterns
      expect(Inspection.search("SPEC!@#").count).to eq(1)
      expect(Inspection.search("%^&*").count).to eq(1)
      expect(Inspection.search("()_+").count).to eq(1)
      expect(Inspection.search("NONEXISTENT").count).to eq(0)
    end

    # Test date validation and handling
    it "handles edge case dates" do
      # Far future dates
      future_inspection = create(:inspection,
        inspection_date: Date.today + 50.years,
        reinspection_date: Date.today + 100.years)

      retrieved = Inspection.find(future_inspection.id)
      expect(retrieved.inspection_date).to eq(Date.today + 50.years)
      expect(retrieved.reinspection_date).to eq(Date.today + 100.years)
    end
  end

  describe "search functionality" do
    let!(:search_unit1) { create(:unit, serial: "SEARCH001") }
    let!(:search_unit2) { create(:unit, serial: "ANOTHER999") }
    let!(:search_inspection1) { create(:inspection, :passed, unit: search_unit1) }
    let!(:search_inspection2) { create(:inspection, :failed, unit: search_unit2) }

    it "finds records by partial serial match" do
      expect(Inspection.search("SEARCH").count).to eq(1)
      expect(Inspection.search("ANOTHER").count).to eq(1)
      expect(Inspection.search("999").count).to eq(1)
      expect(Inspection.search("001").count).to eq(1)
    end

    it "returns empty collection when no match found" do
      expect(Inspection.search("NONEXISTENT").count).to eq(0)
    end

    it "is case-insensitive when searching" do
      expect(Inspection.search("search").count).to eq(1)
      expect(Inspection.search("another").count).to eq(1)

      # Create a record with lowercase serial
      lowercase_unit = create(:unit, serial: "lowercase123")
      create(:inspection, unit: lowercase_unit)

      expect(Inspection.search("LOWERCASE").count).to eq(1)
      expect(Inspection.search("lowercase").count).to eq(1)
    end
  end
end
