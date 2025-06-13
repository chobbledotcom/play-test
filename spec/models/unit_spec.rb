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
        description: nil, manufacturer: nil, owner: nil)
      expect(unit).not_to be_valid
      expect(unit.errors[:name]).to be_present
      expect(unit.errors[:serial]).to be_present
      expect(unit.errors[:description]).to be_present
      expect(unit.errors[:manufacturer]).to be_present
      expect(unit.errors[:owner]).to be_present
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
      expect(unit.id).to match(/\A[A-Z0-9]{8}\z/)
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
    let!(:unit1) { create(:unit, name: "Bouncy Castle", serial: "BC001", description: "Inflatable bouncy castle") }
    let!(:unit2) { create(:unit, name: "Slide Unit", serial: "SL002", description: "Giant inflatable slide") }

    it "searches by serial" do
      results = Unit.search("BC001")
      expect(results).to include(unit1)
      expect(results).not_to include(unit2)
    end

    it "searches by name" do
      results = Unit.search("Bouncy")
      expect(results).to include(unit1)
      expect(results).not_to include(unit2)
    end
  end

  describe "Unit functionality" do
    let(:test_unit) { create(:unit) }

    describe "validations in unit mode" do
      it "validates unit-specific fields when in unit mode" do
        unit = build(:unit, user: user, manufacturer: nil,
          owner: nil, serial: nil)

        expect(unit).not_to be_valid
        expect(unit.errors[:manufacturer]).to be_present
        expect(unit.errors[:owner]).to be_present
        expect(unit.errors[:serial]).to be_present
      end

      it "validates serial uniqueness within user" do
        test_unit # Create first unit

        duplicate = build(:unit, user: test_unit.user, serial: test_unit.serial)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:serial]).to be_present
      end
    end

    describe "scopes" do
      describe "enhanced search" do
        it "searches across all relevant fields" do
          results = Unit.search("Bouncy")
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
      expect(unit.id).to match(/\A[A-Z0-9]{8}\z/)
    end
  end

  describe "#inspection_overdue?" do
    let(:unit) { create(:unit) }

    context "when unit has never been inspected" do
      it "returns false" do
        expect(unit.inspection_overdue?).to be false
      end
    end

    context "when last inspection was within the reinspection interval" do
      it "returns false" do
        create(:inspection, :complete, unit: unit, inspection_date: (SafetyStandard::REINSPECTION_INTERVAL_DAYS / 2).days.ago)
        expect(unit.inspection_overdue?).to be false
      end
    end

    context "when last inspection was beyond the reinspection interval" do
      it "returns true" do
        create(:inspection, :complete, unit: unit, inspection_date: (SafetyStandard::REINSPECTION_INTERVAL_DAYS + 30).days.ago)
        expect(unit.inspection_overdue?).to be true
      end
    end

    context "when last inspection was exactly at the reinspection interval" do
      it "returns false" do
        create(:inspection, :complete, unit: unit, inspection_date: SafetyStandard::REINSPECTION_INTERVAL_DAYS.days.ago)
        expect(unit.inspection_overdue?).to be false
      end
    end
  end

  describe "#next_inspection_due" do
    let(:unit) { create(:unit) }

    context "when unit has never been inspected" do
      it "returns nil" do
        expect(unit.next_inspection_due).to be_nil
      end
    end

    context "when unit has been inspected" do
      it "returns date after reinspection interval from last inspection" do
        inspection_date = Date.new(2024, 1, 15)
        create(:inspection, :completed, unit: unit, inspection_date: inspection_date)

        expect(unit.next_inspection_due).to eq(inspection_date + SafetyStandard::REINSPECTION_INTERVAL_DAYS.days)
      end

      it "uses the most recent inspection date" do
        create(:inspection, :completed, unit: unit, inspection_date: (SafetyStandard::REINSPECTION_INTERVAL_DAYS * 2).days.ago)
        recent_date = (SafetyStandard::REINSPECTION_INTERVAL_DAYS / 2).days.ago.to_date
        create(:inspection, :completed, unit: unit, inspection_date: recent_date)

        expect(unit.next_inspection_due).to eq(recent_date + SafetyStandard::REINSPECTION_INTERVAL_DAYS.days)
      end
    end
  end

  describe ".overdue" do
    let!(:never_inspected) { create(:unit) }
    let!(:recently_inspected) { create(:unit) }
    let!(:overdue_unit) { create(:unit) }
    let!(:just_due_unit) { create(:unit) }

    before do
      create(:inspection, unit: recently_inspected, inspection_date: (SafetyStandard::REINSPECTION_INTERVAL_DAYS / 2).days.ago)
      create(:inspection, unit: overdue_unit, inspection_date: (SafetyStandard::REINSPECTION_INTERVAL_DAYS + 30).days.ago)
      # Create inspection exactly at the reinspection interval boundary (as a date, not datetime)
      create(:inspection, unit: just_due_unit, inspection_date: Date.current - SafetyStandard::REINSPECTION_INTERVAL_DAYS.days)
    end

    it "returns units with inspections older than the reinspection interval" do
      expect(Unit.overdue).to include(overdue_unit)
    end

    it "does not include recently inspected units" do
      expect(Unit.overdue).not_to include(recently_inspected)
    end

    it "does not include never inspected units" do
      expect(Unit.overdue).not_to include(never_inspected)
    end

    it "does not include units inspected exactly at the reinspection interval" do
      expect(Unit.overdue).not_to include(just_due_unit)
    end

    it "returns distinct units even with multiple old inspections" do
      create(:inspection, unit: overdue_unit, inspection_date: (SafetyStandard::REINSPECTION_INTERVAL_DAYS * 2).days.ago)

      result = Unit.overdue
      # When using GROUP BY, result is already distinct by unit
      expect(result.to_a.size).to eq(1) # only overdue_unit
      expect(result).to include(overdue_unit)
      expect(result).not_to include(just_due_unit)
    end
  end

  describe "#compliance_status" do
    let(:unit) { create(:unit) }

    context "when never inspected" do
      it "returns 'Never Inspected'" do
        expect(unit.compliance_status).to eq("Never Inspected")
      end
    end

    context "when inspection is overdue" do
      it "returns 'Overdue'" do
        create(:inspection, :completed, unit: unit, inspection_date: (SafetyStandard::REINSPECTION_INTERVAL_DAYS + 30).days.ago, passed: true)
        expect(unit.compliance_status).to eq("Overdue")
      end
    end

    context "when recently inspected and passed" do
      it "returns 'Compliant'" do
        create(:inspection, :completed, unit: unit, inspection_date: (SafetyStandard::REINSPECTION_INTERVAL_DAYS / 2).days.ago, passed: true)
        expect(unit.compliance_status).to eq("Compliant")
      end
    end

    context "when recently inspected but failed" do
      it "returns 'Non-Compliant'" do
        create(:inspection, :completed, unit: unit, inspection_date: (SafetyStandard::REINSPECTION_INTERVAL_DAYS / 2).days.ago, passed: false)
        expect(unit.compliance_status).to eq("Non-Compliant")
      end
    end
  end
end
