# frozen_string_literal: true

require "rails_helper"

RSpec.describe Inspection, type: :model do
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user:) }

  describe "validations" do
    it "requires inspection_date" do
      invalid_inspection = build(:inspection, inspection_date: nil)
      expect(invalid_inspection).not_to be_valid
      error_msg = "can't be blank"
      expect(invalid_inspection.errors[:inspection_date]).to include(error_msg)
    end

    it "requires inspection_location when complete" do
      invalid_inspection = build(:inspection, inspection_location: nil,
        complete_date: Time.current)
      expect(invalid_inspection).not_to be_valid
      error_msg = "can't be blank"
      errors = invalid_inspection.errors[:inspection_location]
      expect(errors).to include(error_msg)
    end
  end

  describe "#complete?" do
    it "returns true when complete_date is present" do
      inspection.complete_date = Time.current
      expect(inspection.complete?).to be true
    end

    it "returns false when complete_date is nil" do
      inspection.complete_date = nil
      expect(inspection.complete?).to be false
    end
  end

  describe "#reinspection_date" do
    it "returns nil when inspection_date is nil" do
      inspection.inspection_date = nil
      expect(inspection.reinspection_date).to be_nil
    end

    it "returns inspection_date + 1 year when inspection_date is present" do
      inspection.inspection_date = Date.new(2025, 1, 1)
      expect(inspection.reinspection_date).to eq(Date.new(2026, 1, 1))
    end
  end

  describe "scopes" do
    let!(:passed) { create(:inspection, :passed) }
    let!(:failed) { create(:inspection, :failed) }
    let!(:completed) { create(:inspection, :completed) }
    let!(:draft) { create(:inspection) }

    it "filters by passed" do
      expect(Inspection.passed).to include(passed)
      expect(Inspection.passed).not_to include(failed)
    end

    it "filters by failed" do
      expect(Inspection.failed).to include(failed)
      expect(Inspection.failed).not_to include(passed)
    end

    it "filters by complete" do
      expect(Inspection.complete).to include(completed)
      expect(Inspection.complete).not_to include(draft)
    end

    it "filters by draft" do
      expect(Inspection.draft).to include(draft)
      expect(Inspection.draft).not_to include(completed)
    end
  end

  describe ".filter_by_result" do
    let!(:passed) { create(:inspection, :passed) }
    let!(:failed) { create(:inspection, :failed) }

    it "filters by passed result" do
      expect(Inspection.filter_by_result("passed")).to include(passed)
      expect(Inspection.filter_by_result("passed")).not_to include(failed)
    end

    it "filters by failed result" do
      expect(Inspection.filter_by_result("failed")).to include(failed)
      expect(Inspection.filter_by_result("failed")).not_to include(passed)
    end

    it "returns all when result is neither passed nor failed" do
      expect(Inspection.filter_by_result("other")).to eq(Inspection.all)
      expect(Inspection.filter_by_result(nil)).to eq(Inspection.all)
    end
  end

  describe ".filter_by_unit" do
    let(:unit1) { create(:unit) }
    let(:unit2) { create(:unit) }
    let!(:matching) { create(:inspection, unit: unit1) }
    let!(:non_matching) { create(:inspection, unit: unit2) }

    it "filters by unit_id when present" do
      result = Inspection.filter_by_unit(unit1.id)
      expect(result).to include(matching)
      expect(result).not_to include(non_matching)
    end

    it "returns all when unit_id is blank" do
      expect(Inspection.filter_by_unit(nil)).to eq(Inspection.all)
      expect(Inspection.filter_by_unit("")).to eq(Inspection.all)
    end
  end

  describe "#get_missing_assessments" do
    it "identifies missing assessments" do
      # Make user_height assessment incomplete
      inspection.user_height_assessment.update(containing_wall_height: nil)

      missing = inspection.get_missing_assessments
      expect(missing).to include(I18n.t("forms.user_height.header"))
    end

    it "identifies missing unit" do
      inspection.unit = nil
      missing = inspection.get_missing_assessments
      expect(missing).to include("Unit")
    end
  end

  describe "#can_be_completed?" do
    it "returns false when unit is nil" do
      inspection.unit = nil
      expect(inspection.can_be_completed?).to be false
    end

    it "returns false when assessments are incomplete" do
      inspection.user_height_assessment.update(containing_wall_height: nil)
      expect(inspection.can_be_completed?).to be false
    end

    it "returns true when unit present and all assessments complete" do
      completed_inspection = create(:inspection, :completed)
      expect(completed_inspection.can_be_completed?).to be true
    end
  end

  describe "#complete!" do
    it "sets complete_date and logs audit action" do
      inspection.complete_date = nil
      expect(inspection).to receive(:log_audit_action)
        .with("completed", user, "Inspection completed")

      inspection.complete!(user)
      expect(inspection.complete_date).not_to be_nil
    end
  end

  describe "photo attachments" do
    describe "validations" do
      it "allows image files for photo_1" do
        file = fixture_file_upload("test_image.jpg", "image/jpeg")
        inspection.photo_1.attach(file)
        expect(inspection).to be_valid
      end

      it "allows image files for photo_2" do
        inspection.photo_2.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
        expect(inspection).to be_valid
      end

      it "allows image files for photo_3" do
        inspection.photo_3.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/test_image.jpg")),
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
        expect(inspection).to be_valid
      end
    end
  end
end
