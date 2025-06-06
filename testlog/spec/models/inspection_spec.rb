require "rails_helper"

RSpec.describe Inspection, type: :model do
  let(:user) { User.create!(email: "test@example.com", password: "password", password_confirmation: "password") }

  describe "validations" do
    it "validates presence of required fields" do
      inspection = Inspection.new(user: user)
      expect(inspection).not_to be_valid
      expect(inspection.errors[:inspector]).to include("can't be blank")
      expect(inspection.errors[:serial]).to include("can't be blank")
      expect(inspection.errors[:location]).to include("can't be blank")
    end

    it "can be created with valid attributes" do
      inspection = Inspection.new(
        user: user,
        inspector: "Test Inspector",
        serial: "TEST123",
        location: "Test Location",
        manufacturer: "Test Manufacturer",
        passed: true,
        inspection_date: Date.today,
        reinspection_date: Date.today + 1.year,
        comments: "Test comments"
      )

      expect(inspection).to be_valid
    end

    it "requires a user" do
      inspection = Inspection.new(
        inspector: "Test Inspector",
        serial: "TEST123",
        location: "Test Location",
        manufacturer: "Test Manufacturer",
        passed: true
      )

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
      inspection = Inspection.new(
        user: user,
        inspector: "Jörgen Müller 👨‍🔧",
        serial: "ÜNICØDÉ-😎-123",
        location: "Meeting Room 🏢 3F",
        manufacturer: "Apple, Inc.",
        passed: true,
        comments: "❗️Tested with special 🔌 adapter. Result: ✅"
      )

      expect(inspection).to be_valid
      inspection.save!

      # Retrieve and verify data is intact
      retrieved = Inspection.find(inspection.id)
      expect(retrieved.inspector).to eq("Jörgen Müller 👨‍🔧")
      expect(retrieved.serial).to eq("ÜNICØDÉ-😎-123")
      expect(retrieved.comments).to eq("❗️Tested with special 🔌 adapter. Result: ✅")
    end

    # Test with maximum possible database field lengths
    it "handles maximum length strings in text fields" do
      extremely_long_text = "A" * 65535  # Text field typical max size

      inspection = Inspection.new(
        user: user,
        inspector: "Max Length Tester",
        serial: "MAX123",
        location: "Test lab",
        manufacturer: "Acme, Inc.",
        passed: true,
        comments: extremely_long_text
      )

      expect(inspection).to be_valid
      inspection.save!

      # Verify the extremely long comment was saved correctly
      retrieved = Inspection.find(inspection.id)
      expect(retrieved.comments).to eq(extremely_long_text)
    end

    # Test with SQL injection attempts in string fields
    it "safely handles strings that look like SQL injection attempts" do
      inspection = Inspection.new(
        user: user,
        inspector: "Robert'); DROP TABLE inspections; --",
        serial: "'; SELECT * FROM users; --",
        location: "Location'); UPDATE users SET admin=true; --",
        manufacturer: "Vendor'); DROP TABLE users; --",
        passed: true,
        comments: "Normal comment"
      )

      expect(inspection).to be_valid
      inspection.save!

      # Verify the data was saved correctly and didn't affect the database
      retrieved = Inspection.find(inspection.id)
      expect(retrieved.inspector).to eq("Robert'); DROP TABLE inspections; --")

      # Verify all inspections still exist
      expect(Inspection.count).to be >= 1
    end

    # Test search functionality with special characters
    it "performs search with special characters" do
      # Create inspection with special characters in serial
      Inspection.create!(
        user: user,
        inspector: "Search Tester",
        serial: "SPEC!@#$%^&*()_+",
        location: "Test Lab",
        manufacturer: "Test Manufacturer",
        passed: true
      )

      # Test searching for various patterns
      expect(Inspection.search("SPEC!@#").count).to eq(1)
      expect(Inspection.search("%^&*").count).to eq(1)
      expect(Inspection.search("()_+").count).to eq(1)
      expect(Inspection.search("NONEXISTENT").count).to eq(0)
    end

    # Test date validation and handling
    it "handles edge case dates" do
      # Far future dates
      future_inspection = Inspection.new(
        user: user,
        inspector: "Future Tester",
        serial: "FUTURE123",
        location: "Time Lab",
        manufacturer: "Future Corp",
        passed: true,
        inspection_date: Date.today + 50.years,         # Far future inspection date
        reinspection_date: Date.today + 100.years       # Far future reinspection date
      )

      expect(future_inspection).to be_valid
      future_inspection.save!

      retrieved = Inspection.find(future_inspection.id)
      expect(retrieved.inspection_date).to eq(Date.today + 50.years)
      expect(retrieved.reinspection_date).to eq(Date.today + 100.years)
    end
  end

  describe "search functionality" do
    before do
      # Create test records for search
      Inspection.create!(
        user: user,
        inspector: "Search Tester 1",
        serial: "SEARCH001",
        location: "Search Lab",
        manufacturer: "Vendor A",
        passed: true
      )

      Inspection.create!(
        user: user,
        inspector: "Search Tester 2",
        serial: "ANOTHER999",
        location: "Search Lab",
        manufacturer: "Vendor B",
        passed: false
      )
    end

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
      Inspection.create!(
        user: user,
        inspector: "Case Tester",
        serial: "lowercase123",
        location: "Case Lab",
        manufacturer: "Test Manufacturer",
        passed: true
      )

      expect(Inspection.search("LOWERCASE").count).to eq(1)
      expect(Inspection.search("lowercase").count).to eq(1)
    end
  end
end
