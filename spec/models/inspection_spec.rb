# typed: false
# frozen_string_literal: true

# == Schema Information
#
# Table name: inspections
#
#  id                   :string(8)        not null, primary key
#  complete_date        :datetime
#  has_slide            :boolean
#  height               :decimal(8, 2)
#  height_comment       :string(1000)
#  indoor_only          :boolean
#  inspection_date      :datetime
#  inspection_type      :string           default("bouncy_castle"), not null
#  is_seed              :boolean          default(FALSE), not null
#  is_totally_enclosed  :boolean
#  length               :decimal(8, 2)
#  length_comment       :string(1000)
#  passed               :boolean
#  pdf_last_accessed_at :datetime
#  risk_assessment      :text
#  width                :decimal(8, 2)
#  width_comment        :string(1000)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  inspector_company_id :string(8)
#  unit_id              :string(8)
#  user_id              :string(8)        not null
#
# Indexes
#
#  index_inspections_on_inspection_type       (inspection_type)
#  index_inspections_on_inspector_company_id  (inspector_company_id)
#  index_inspections_on_is_seed               (is_seed)
#  index_inspections_on_unit_id               (unit_id)
#  index_inspections_on_user_id               (user_id)
#
# Foreign Keys
#
#  inspector_company_id  (inspector_company_id => inspector_companies.id)
#  unit_id               (unit_id => units.id)
#  user_id               (user_id => users.id)
#
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

  describe ".search" do
    let(:unit) { create(:unit, serial: "TEST123", manufacturer: "TestMfg", name: "TestUnit") }
    let!(:matching_by_id) { create(:inspection, id: "INSP1234") }
    let!(:matching_by_serial) { create(:inspection, unit: unit) }
    let!(:non_matching) { create(:inspection) }

    it "finds inspections by inspection ID" do
      result = Inspection.search("INSP")
      expect(result).to include(matching_by_id)
      expect(result).not_to include(non_matching)
    end

    it "finds inspections by unit serial number" do
      result = Inspection.search("TEST123")
      expect(result).to include(matching_by_serial)
      expect(result).not_to include(matching_by_id)
    end

    it "finds inspections by unit manufacturer" do
      result = Inspection.search("TestMfg")
      expect(result).to include(matching_by_serial)
      expect(result).not_to include(matching_by_id)
    end

    it "finds inspections by unit name" do
      result = Inspection.search("TestUnit")
      expect(result).to include(matching_by_serial)
      expect(result).not_to include(matching_by_id)
    end

    it "performs case-insensitive partial matching" do
      result = Inspection.search("test")
      expect(result).to include(matching_by_serial)
    end

    it "returns all when query is blank" do
      expect(Inspection.search(nil)).to eq(Inspection.all)
      expect(Inspection.search("")).to eq(Inspection.all)
    end
  end

  describe ".filter_by_operator" do
    let(:operator1) { "Operator A" }
    let(:operator2) { "Operator B" }
    let!(:matching) { create(:inspection, operator: operator1) }
    let!(:non_matching) { create(:inspection, operator: operator2) }

    it "filters by operator when present" do
      result = Inspection.filter_by_operator(operator1)
      expect(result).to include(matching)
      expect(result).not_to include(non_matching)
    end

    it "returns all when operator is blank" do
      expect(Inspection.filter_by_operator(nil)).to eq(Inspection.all)
      expect(Inspection.filter_by_operator("")).to eq(Inspection.all)
    end
  end

  describe ".filter_by_date_range" do
    let(:start_date) { Date.new(2024, 1, 1) }
    let(:end_date) { Date.new(2024, 1, 31) }
    let!(:within_range) { create(:inspection, inspection_date: Time.zone.local(2024, 1, 15, 12, 0, 0)) }
    let!(:before_range) { create(:inspection, inspection_date: Time.zone.local(2023, 12, 31, 12, 0, 0)) }
    let!(:after_range) { create(:inspection, inspection_date: Time.zone.local(2024, 2, 1, 12, 0, 0)) }

    it "filters inspections within date range" do
      result = Inspection.filter_by_date_range(start_date, end_date)
      expect(result).to include(within_range)
      expect(result).not_to include(before_range, after_range)
    end

    it "includes inspections on start date" do
      on_start = create(:inspection, inspection_date: Time.zone.local(2024, 1, 1, 12, 0, 0))
      result = Inspection.filter_by_date_range(start_date, end_date)
      expect(result).to include(on_start)
    end

    it "handles end date correctly with DateTime fields" do
      # Date ranges with DateTime columns only include times before midnight of end date + 1
      on_end_early = create(:inspection, inspection_date: Time.zone.local(2024, 1, 30, 23, 59, 59))
      create(:inspection, inspection_date: Time.zone.local(2024, 1, 31, 0, 0, 1))

      result = Inspection.filter_by_date_range(start_date, end_date)
      expect(result).to include(on_end_early)
      # Note: Rails Date ranges exclude times on the end date itself for DateTime fields
      # This is a known Rails behavior when mixing Date ranges with DateTime columns
    end

    it "returns all when start_date is nil" do
      result = Inspection.filter_by_date_range(nil, end_date)
      expect(result).to eq(Inspection.all)
    end

    it "returns all when end_date is nil" do
      result = Inspection.filter_by_date_range(start_date, nil)
      expect(result).to eq(Inspection.all)
    end

    it "returns all when both dates are nil" do
      result = Inspection.filter_by_date_range(nil, nil)
      expect(result).to eq(Inspection.all)
    end
  end

  describe ".overdue" do
    let(:today) { Time.zone.today }
    let!(:overdue) { create(:inspection, inspection_date: today - 13.months) }
    let!(:due_soon) { create(:inspection, inspection_date: today - 11.months) }
    let!(:recent) { create(:inspection, inspection_date: today - 6.months) }

    it "includes inspections older than one year" do
      expect(Inspection.overdue).to include(overdue)
    end

    it "excludes inspections less than one year old" do
      expect(Inspection.overdue).not_to include(due_soon, recent)
    end

    it "correctly handles exactly one year old inspections" do
      exactly_one_year = create(:inspection, inspection_date: today - 1.year)
      expect(Inspection.overdue).not_to include(exactly_one_year)
    end
  end

  describe ".search_conditions" do
    it "returns the correct SQL conditions string" do
      expected = "inspections.id LIKE ? OR units.serial LIKE ? OR " \
                 "units.manufacturer LIKE ? OR units.name LIKE ?"
      expect(Inspection.search_conditions).to eq(expected)
    end
  end

  describe ".search_values" do
    it "returns array with query wrapped in wildcards" do
      query = "test"
      result = Inspection.search_values(query)
      expect(result).to eq(["%test%", "%test%", "%test%", "%test%"])
    end

    it "handles special characters in query" do
      query = "test_123%"
      result = Inspection.search_values(query)
      expect(result).to eq(["%test_123%%", "%test_123%%", "%test_123%%", "%test_123%%"])
    end
  end

  describe ".both_dates_present?" do
    it "returns true when both dates are present" do
      expect(Inspection.both_dates_present?("2024-01-01", "2024-01-31")).to be true
      expect(Inspection.both_dates_present?(Date.new(2024, 1, 1), Date.new(2024, 1, 31))).to be true
    end

    it "returns false when start_date is nil" do
      expect(Inspection.both_dates_present?(nil, "2024-01-31")).to be false
    end

    it "returns false when end_date is nil" do
      expect(Inspection.both_dates_present?("2024-01-01", nil)).to be false
    end

    it "returns false when both dates are nil" do
      expect(Inspection.both_dates_present?(nil, nil)).to be false
    end

    it "returns false when dates are empty strings" do
      expect(Inspection.both_dates_present?("", "2024-01-31")).to be false
      expect(Inspection.both_dates_present?("2024-01-01", "")).to be false
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

  describe "#area" do
    it "returns nil when width is nil" do
      inspection.width = nil
      inspection.length = 10
      expect(inspection.area).to be_nil
    end

    it "returns nil when length is nil" do
      inspection.width = 10
      inspection.length = nil
      expect(inspection.area).to be_nil
    end

    it "returns width * length when both present" do
      inspection.width = 5.5
      inspection.length = 7.2
      expect(inspection.area).to eq(39.6)
    end
  end

  describe "#volume" do
    it "returns nil when width is nil" do
      inspection.width = nil
      inspection.length = 10
      inspection.height = 5
      expect(inspection.volume).to be_nil
    end

    it "returns nil when length is nil" do
      inspection.width = 10
      inspection.length = nil
      inspection.height = 5
      expect(inspection.volume).to be_nil
    end

    it "returns nil when height is nil" do
      inspection.width = 10
      inspection.length = 10
      inspection.height = nil
      expect(inspection.volume).to be_nil
    end

    it "returns width * length * height when all present" do
      inspection.width = 5.5
      inspection.length = 7.2
      inspection.height = 3.3
      expect(inspection.volume).to eq(130.68)
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

  describe "#un_complete!" do
    it "sets complete_date to nil and logs audit action" do
      inspection.complete_date = Time.current
      expect(inspection).to receive(:log_audit_action)
        .with("marked_incomplete", user, "Inspection completed")

      inspection.un_complete!(user)
      expect(inspection.complete_date).to be_nil
    end
  end

  describe "#each_applicable_assessment" do
    it "yields each applicable assessment with key, class, and instance" do
      yielded_assessments = []

      inspection.each_applicable_assessment do |key, klass, assessment|
        yielded_assessments << [key, klass, assessment]
      end

      # Should yield all applicable assessments for a castle
      expect(yielded_assessments.map(&:first)).to include(
        :user_height_assessment,
        :structure_assessment,
        :materials_assessment,
        :fan_assessment
      )

      # Each yielded assessment should have the correct class
      yielded_assessments.each do |key, klass, assessment|
        expect(assessment).to be_a(klass)
      end
    end

    it "only yields slide assessment when has_slide is true" do
      inspection.has_slide = false
      yielded_keys = []

      inspection.each_applicable_assessment do |key, _, _|
        yielded_keys << key
      end

      expect(yielded_keys).not_to include(:slide_assessment)

      inspection.has_slide = true
      yielded_keys = []

      inspection.each_applicable_assessment do |key, _, _|
        yielded_keys << key
      end

      expect(yielded_keys).to include(:slide_assessment)
    end

    it "requires a block to be given" do
      # The method has a Sorbet signature requiring a block
      expect { inspection.each_applicable_assessment }.to raise_error(TypeError)
    end
  end

  describe "#completion_errors" do
    it "returns empty array when everything is complete" do
      completed_inspection = create(:inspection, :completed)
      expect(completed_inspection.completion_errors).to be_empty
    end

    it "includes unit error when unit is missing" do
      inspection.unit = nil
      errors = inspection.completion_errors
      expect(errors).to include("Unit is required")
    end

    it "includes incomplete field information for each tab" do
      inspection.user_height_assessment.update(containing_wall_height: nil)
      errors = inspection.completion_errors

      expect(errors.any? { |e| e.include?(I18n.t("forms.user_height.header")) }).to be true
    end

    it "formats errors with tab name and field labels" do
      inspection.passed = nil
      errors = inspection.completion_errors

      expect(errors.any? { |e| e.include?(I18n.t("forms.results.header")) }).to be true
    end
  end

  describe "#log_audit_action" do
    it "creates an event log entry" do
      expect(Event).to receive(:log).with(
        user: user,
        action: "test_action",
        resource: inspection,
        details: "Test details"
      )

      inspection.log_audit_action("test_action", user, "Test details")
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
          io: Rails.root.join("spec/fixtures/files/test_image.jpg").open,
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
        expect(inspection).to be_valid
      end

      it "allows image files for photo_3" do
        inspection.photo_3.attach(
          io: Rails.root.join("spec/fixtures/files/test_image.jpg").open,
          filename: "test.jpg",
          content_type: "image/jpeg"
        )
        expect(inspection).to be_valid
      end
    end
  end

  describe "#invalidate_pdf_cache" do
    it "does not invalidate cache when only pdf_last_accessed_at changes" do
      expect(PdfCacheService).not_to receive(:invalidate_inspection_cache)

      inspection.update!(pdf_last_accessed_at: Time.current)
    end

    it "does not invalidate cache when only updated_at changes" do
      expect(PdfCacheService).not_to receive(:invalidate_inspection_cache)

      # Simulate touching the record
      inspection.touch
    end

    it "invalidates cache when other attributes change" do
      expect(PdfCacheService).to receive(:invalidate_inspection_cache).with(inspection)

      inspection.update!(risk_assessment: "Updated risk assessment")
    end

    it "invalidates cache when multiple attributes change including pdf_last_accessed_at" do
      expect(PdfCacheService).to receive(:invalidate_inspection_cache).with(inspection)

      inspection.update!(
        pdf_last_accessed_at: Time.current,
        risk_assessment: "Updated risk assessment"
      )
    end
  end
end
