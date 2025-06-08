require "rails_helper"

RSpec.describe Inspection, type: :model do
  let(:user) { create(:user) }

  describe "validations" do
    it "validates presence of required fields" do
      inspection = build(:inspection, inspection_location: nil, inspection_date: nil, status: "completed")
      expect(inspection).not_to be_valid
      expect(inspection.errors[:inspection_location]).to include("can't be blank")
    end

    it "can be created with valid attributes" do
      inspection = build(:inspection)
      expect(inspection).to be_valid
    end

    it "requires a user" do
      inspector_company = create(:inspector_company)
      inspection = build(:inspection, user: nil, inspector_company: inspector_company)
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

  describe "inspector_company assignment" do
    let(:inspector_company) { create(:inspector_company) }
    let(:user_with_company) { create(:user, inspection_company: inspector_company) }
    let(:unit) { create(:unit, user: user_with_company) }

    it "copies inspector_company_id from user on creation" do
      inspection = user_with_company.inspections.create!(
        unit: unit,
        inspection_date: Date.current,
        status: "draft"
      )

      expect(inspection.inspector_company_id).to eq(inspector_company.id)
    end

    it "doesn't change inspector_company_id when user's company changes" do
      inspection = create(:inspection, user: user_with_company, unit: unit)
      original_company_id = inspection.inspector_company_id

      new_company = create(:inspector_company, name: "New Company")
      user_with_company.update!(inspection_company: new_company)

      inspection.reload
      expect(inspection.inspector_company_id).to eq(original_company_id)
      expect(inspection.inspector_company_id).not_to eq(new_company.id)
    end

    it "uses explicitly set inspector_company_id over user's company" do
      different_company = create(:inspector_company, name: "Different Company")

      inspection = user_with_company.inspections.create!(
        unit: unit,
        inspection_date: Date.current,
        status: "draft",
        inspector_company_id: different_company.id
      )

      expect(inspection.inspector_company_id).to eq(different_company.id)
      expect(inspection.inspector_company_id).not_to eq(inspector_company.id)
    end
  end

  describe "esoteric tests" do
    # Test with Unicode characters and emoji in text fields
    it "handles Unicode characters and emoji in text fields" do
      inspection = create(:inspection, :with_unicode_data)

      # Retrieve and verify data is intact
      retrieved = Inspection.find(inspection.id)
      expect(retrieved.inspector_company.name).to be_present
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
      expect(retrieved.inspector_company.name).to be_present

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
        inspection_date: Date.today + 50.years)

      retrieved = Inspection.find(future_inspection.id)
      expect(retrieved.inspection_date).to eq(Date.today + 50.years)
      # reinspection_date is calculated as inspection_date + 1 year
      expect(retrieved.reinspection_date).to eq(Date.today + 51.years)
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

  describe "HasDimensions concern" do
    let(:inspection) { create(:inspection) }

    it "includes HasDimensions module" do
      expect(Inspection.ancestors).to include(HasDimensions)
    end

    it "has all dimension fields available" do
      inspection.width = 10
      inspection.length = 8
      inspection.height = 3
      inspection.num_low_anchors = 4
      inspection.rope_size = 12.5

      expect(inspection.dimensions).to eq("10m × 8m × 3m")
      expect(inspection.area).to eq(80)
      expect(inspection.volume).to eq(240)
    end
  end

  describe "dimension copying from unit" do
    let(:unit) {
      create(:unit,
        width: 12.5,
        length: 10.0,
        height: 4.0,
        num_low_anchors: 6,
        num_high_anchors: 2,
        rope_size: 15.0,
        slide_platform_height: 2.5,
        containing_wall_height: 1.2,
        users_at_1000mm: 10)
    }

    it "copies all dimensions from unit on creation" do
      inspection = create(:inspection,
        user: user,
        unit: unit,
        inspection_date: Date.current,
        inspection_location: "Test Location",
        inspector_company: create(:inspector_company))

      # Basic dimensions
      expect(inspection.width).to eq(12.5)
      expect(inspection.length).to eq(10.0)
      expect(inspection.height).to eq(4.0)

      # Other dimensions
      expect(inspection.num_low_anchors).to eq(6)
      expect(inspection.num_high_anchors).to eq(2)
      expect(inspection.rope_size).to eq(15.0)
      expect(inspection.slide_platform_height).to eq(2.5)
      expect(inspection.containing_wall_height).to eq(1.2)
      expect(inspection.users_at_1000mm).to eq(10)
    end

    it "preserves inspection dimensions when unit is updated" do
      inspection = create(:inspection, unit: unit)

      # Original dimensions
      expect(inspection.width).to eq(12.5)

      # Update unit
      unit.update!(width: 15.0, length: 12.0)

      # Inspection dimensions remain unchanged
      inspection.reload
      expect(inspection.width).to eq(12.5)
      expect(inspection.length).to eq(10.0)
    end
  end
end
