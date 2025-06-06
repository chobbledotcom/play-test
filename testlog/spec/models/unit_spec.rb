require "rails_helper"

RSpec.describe Unit, type: :model do
  let(:user) { create(:user) }

  describe "associations" do
    let(:unit) { create(:unit, user: user) }

    it "belongs to user" do
      expect(unit.user).to eq(user)
    end

    it "has many inspections" do
      expect(unit).to respond_to(:inspections)
    end

    it "has one attached photo" do
      expect(unit).to respond_to(:photo)
      expect(unit.photo).to be_an_instance_of(ActiveStorage::Attached::One)
    end
  end

  describe "validations" do
    it "validates presence of all required fields" do
      unit = build(:unit, user: user, name: nil, serial: nil,
        description: nil, manufacturer: nil, unit_type: nil, owner: nil,
        width: nil, length: nil, height: nil)
      expect(unit).not_to be_valid
      expect(unit.errors[:name]).to be_present
      expect(unit.errors[:serial]).to be_present
      expect(unit.errors[:description]).to be_present
      expect(unit.errors[:manufacturer]).to be_present
      expect(unit.errors[:unit_type]).to be_present
      expect(unit.errors[:owner]).to be_present
      expect(unit.errors[:width]).to be_present
      expect(unit.errors[:length]).to be_present
      expect(unit.errors[:height]).to be_present
    end

    it "validates dimension ranges" do
      unit = build(:unit, width: 250.0) # Too large
      expect(unit).not_to be_valid
      expect(unit.errors[:width]).to be_present
    end

    it "validates serial uniqueness within user" do
      existing_unit = create(:unit)
      # Same user, same serial should fail
      duplicate = build(:unit, user: existing_unit.user, serial: existing_unit.serial)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:serial]).to be_present
    end

    it "allows same serial for different users" do
      user1 = create(:user)
      user2 = create(:user)
      create(:unit, user: user1, manufacturer: "TestCorp", serial: "ABC123")
      unit2 = build(:unit, user: user2, manufacturer: "TestCorp", serial: "ABC123")
      expect(unit2).to be_valid
    end
  end

  describe "custom ID generation" do
    it "generates a custom ID before creation" do
      unit = build(:unit)
      expect(unit.id).to be_nil
      unit.save!
      expect(unit.id).to match(/\A[A-Z0-9]{12}\z/)
    end
  end

  describe "photo attachment" do
    let(:unit) { create(:unit) }

    it "can attach a photo" do
      file = fixture_file_upload("test_image.jpg", "image/jpeg")
      unit.photo.attach(file)

      expect(unit.photo).to be_attached
      expect(unit.photo.filename.to_s).to eq("test_image.jpg")
    end

    it "works without a photo" do
      expect(unit.photo).not_to be_attached
      expect(unit).to be_valid
    end
  end

  describe "search functionality" do
    let!(:unit1) { create(:unit, name: "Bounce House", serial: "BH001") }
    let!(:unit2) { create(:unit, :slide, name: "Slide Unit", serial: "SL002") }

    it "searches by serial" do
      results = Unit.search("BH001")
      expect(results).to include(unit1)
      expect(results).not_to include(unit2)
    end

    it "searches by name" do
      results = Unit.search("Bounce")
      expect(results).to include(unit1)
      expect(results).not_to include(unit2)
    end
  end

  describe "Unit functionality" do
    let(:test_unit) { create(:unit) }

    describe "validations in unit mode" do
      it "validates unit-specific fields when in unit mode" do
        unit = build(:unit, user: user, manufacturer: nil, unit_type: nil,
          owner: nil, width: nil, length: nil, height: nil, serial: nil)

        expect(unit).not_to be_valid
        expect(unit.errors[:manufacturer]).to be_present
        expect(unit.errors[:unit_type]).to be_present
        expect(unit.errors[:owner]).to be_present
        expect(unit.errors[:width]).to be_present
        expect(unit.errors[:length]).to be_present
        expect(unit.errors[:height]).to be_present
        expect(unit.errors[:serial]).to be_present
      end

      it "validates dimension ranges" do
        unit = build(:unit, width: 250.0) # Too large
        expect(unit).not_to be_valid
        expect(unit.errors[:width]).to be_present
      end

      it "validates serial uniqueness within user" do
        test_unit # Create first unit

        duplicate = build(:unit, user: test_unit.user, serial: test_unit.serial)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:serial]).to be_present
      end
    end

    describe "enums" do
      it "defines unit_type enum" do
        expect(Unit.unit_types).to include(
          "bounce_house" => "bounce_house",
          "slide" => "slide",
          "combo_unit" => "combo_unit",
          "obstacle_course" => "obstacle_course",
          "totally_enclosed" => "totally_enclosed"
        )
      end

      it "can set and query unit_type" do
        test_unit.unit_type = "slide"
        expect(test_unit.slide?).to be_truthy
        expect(test_unit.bounce_house?).to be_falsy
      end
    end

    describe "dimensions and calculations" do
      it "calculates dimensions string" do
        expect(test_unit.dimensions).to eq("10.0m × 10.0m × 3.0m")
      end

      it "calculates area" do
        expect(test_unit.area).to eq(100.0)
      end

      it "calculates volume" do
        expect(test_unit.volume).to eq(300.0)
      end
    end

    describe "scopes" do
      let!(:slide_unit) {
        create(:unit, :slide, user: user, name: "Slide Unit",
          serial: "SLIDE001", manufacturer: "Slide Co")
      }

      describe ".by_type" do
        it "filters by unit_type" do
          results = Unit.by_type("bounce_house")
          expect(results).to include(test_unit)
          expect(results).not_to include(slide_unit)
        end
      end

      describe "enhanced search" do
        it "searches across all relevant fields" do
          results = Unit.search("Bounce")
          expect(results).to include(test_unit)

          results = Unit.search("Test Manufacturer")
          expect(results).to include(test_unit)

          results = Unit.search("Test Owner")
          expect(results).to include(test_unit)
        end
      end
    end

    describe "inspection methods" do
      it "responds to inspection-related methods" do
        expect(test_unit).to respond_to(:last_inspection)
        expect(test_unit).to respond_to(:last_inspection_status)
        expect(test_unit).to respond_to(:inspection_history)
        expect(test_unit).to respond_to(:next_inspection_due)
        expect(test_unit).to respond_to(:inspection_overdue?)
        expect(test_unit).to respond_to(:compliance_status)
        expect(test_unit).to respond_to(:inspection_summary)
      end

      it "determines enclosed assessment requirement" do
        test_unit.unit_type = "totally_enclosed"
        expect(test_unit.requires_enclosed_assessment?).to be_truthy

        test_unit.unit_type = "bounce_house"
        expect(test_unit.requires_enclosed_assessment?).to be_falsy
      end

      it "provides inspection summary" do
        summary = test_unit.inspection_summary
        expect(summary[:total_inspections]).to eq(0)
        expect(summary[:passed_inspections]).to eq(0)
        expect(summary[:failed_inspections]).to eq(0)
        expect(summary[:compliance_status]).to eq("Never Inspected")
      end
    end
  end

  describe "CustomIdGenerator integration" do
    it "uses uppercase IDs for new unit" do
      unit = create(:unit, user: user)
      expect(unit.id).to match(/\A[A-Z0-9]{12}\z/)
    end
  end

  # TODO: Add tests for overdue functionality once inspection relationship is enhanced
  # TODO: Add tests for last_due_date once inspection dates are properly implemented
end
