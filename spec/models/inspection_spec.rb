# Business Logic: Inspection Model
#
# An Inspection represents a safety inspection record for inflatable play equipment (bouncy castles).
# This system serves as a document store for inspection records, allowing users to create, edit,
# and manage their inspection documentation.
#
# Key Business Rules:
# 1. Inspection Lifecycle:
#    - Draft state: Incomplete inspection
#    - Complete state: Inspection marked as complete with unique report number and completion date
#    - Inspections remain editable - users can toggle between complete/incomplete as needed
#    - Users have full control over their inspection records
#
# 2. User Association:
#    - Each inspection belongs to a user who created it
#    - Inspections may inherit certain fields from the user at creation time
#    - No direct dependency on inspector companies (users may or may not have a company)
#
# 3. Unit Association & Dimension Copying:
#    - Inspections can be created from existing units (equipment records)
#    - All dimensions are copied from unit at creation time (snapshot approach)
#    - Changes to unit don't affect existing inspections (historical accuracy)
#
# 4. Assessment Components:
#    - Multiple safety assessments can be attached to an inspection
#    - Core assessments: User Height, Structure, Anchorage, Materials, Fan
#    - Conditional assessments: Slide (if has_slide), Enclosed (if is_totally_enclosed)
#
# 5. Validation & Data Requirements:
#    - Complete inspections require: location, unique report number, all assessments
#    - Pass/fail determination based on safety check results
#    - Reinspection due date automatically calculated as inspection_date + 1 year
#
# 6. Search & Filtering:
#    - Searchable by location, inspection ID, internal ID, unit serial/name
#    - Filterable by status (draft/complete), result (passed/failed), date range
#    - Overdue scope identifies inspections older than 1 year
#
# 7. Data Integrity:
#    - Unicode support for international locations and names
#    - Numeric validations ensure non-negative measurements
#    - Unique report numbers prevent duplicate official reports

require "rails_helper"

RSpec.describe Inspection, type: :model do
  let(:user) { create(:user) }

  describe "validations" do
    it "validates presence of required fields" do
      inspection = build(:inspection, inspection_location: nil, inspection_date: nil, complete_date: Time.current)
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
        complete_date: nil
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
        complete_date: nil,
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
      # Create inspection with special characters in location
      create(:inspection, inspection_location: "Location SPEC!@#$%^&*()_+")

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
    let!(:search_inspection1) { create(:inspection, inspection_location: "SearchTerm123 Location") }
    let!(:search_inspection2) { create(:inspection, :failed, inspection_location: "AnotherPlace456 Site") }

    it "finds records by partial location match" do
      expect(Inspection.search("SearchTerm")).to include(search_inspection1)
      expect(Inspection.search("AnotherPlace")).to include(search_inspection2)
      expect(Inspection.search("SearchTerm").count).to eq(1)
      expect(Inspection.search("AnotherPlace").count).to eq(1)
    end

    it "returns empty collection when no match found" do
      expect(Inspection.search("NONEXISTENT").count).to eq(0)
    end

    it "finds records by inspection ID, internal ID, and unit serial" do
      # Create inspection with known IDs and unit
      unit = create(:unit, serial: "UNITTEST123")
      inspection = create(:inspection, unit: unit, unique_report_number: "INTERNAL-ABC123")

      # Search by public inspection ID
      expect(Inspection.search(inspection.id)).to include(inspection)

      # Search by internal ID (unique_report_number)
      expect(Inspection.search("INTERNAL-ABC")).to include(inspection)

      # Search by unit serial
      expect(Inspection.search("UNITTEST")).to include(inspection)
    end

    it "is case-insensitive when searching" do
      expect(Inspection.search("searchterm").count).to eq(1)
      expect(Inspection.search("anotherplace").count).to eq(1)

      # Create a record with lowercase location
      create(:inspection, inspection_location: "lowercase123 location")

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

  describe "status and completion" do
    let(:inspection) { create(:inspection) }

    describe "#complete?" do
      it "returns false when complete_date is nil" do
        inspection.complete_date = nil
        expect(inspection.complete?).to be_falsey
      end

      it "returns true when complete_date is present" do
        inspection.complete_date = Time.current
        expect(inspection.complete?).to be_truthy
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
  end

  describe "URL routing methods" do
    let(:inspection) { create(:inspection) }

    describe "#primary_url_path" do
      it "returns inspection_path when complete" do
        inspection.complete_date = Time.current
        expect(inspection.primary_url_path).to eq("inspection_path(self)")
      end

      it "returns edit_inspection_path when draft" do
        inspection.complete_date = nil
        expect(inspection.primary_url_path).to eq("edit_inspection_path(self)")
      end
    end

    describe "#preferred_path" do
      it "returns show path when complete" do
        inspection.complete_date = Time.current
        result = inspection.preferred_path
        expect(result).to include("/inspections/#{inspection.id}")
        expect(result).not_to include("/edit")
      end

      it "returns edit path when draft" do
        inspection.complete_date = nil
        result = inspection.preferred_path
        expect(result).to include("/inspections/#{inspection.id}/edit")
      end
    end
  end

  describe "validation scopes and filters" do
    let!(:passed_inspection) { create(:inspection, :passed) }
    let!(:failed_inspection) { create(:inspection, :failed) }
    let!(:complete_inspection) { create(:inspection, :complete) }
    let!(:draft_inspection) { create(:inspection) }

    describe "scopes" do
      it "filters passed inspections" do
        expect(Inspection.passed).to include(passed_inspection)
        expect(Inspection.passed).not_to include(failed_inspection)
      end

      it "filters failed inspections" do
        expect(Inspection.failed).to include(failed_inspection)
        expect(Inspection.failed).not_to include(passed_inspection)
      end

      it "filters complete inspections" do
        expect(Inspection.complete).to include(complete_inspection)
        expect(Inspection.complete).not_to include(draft_inspection)
      end

      it "filters draft inspections" do
        expect(Inspection.draft).to include(draft_inspection)
        expect(Inspection.draft).not_to include(complete_inspection)
      end

      describe "filter_by_result" do
        it "filters by passed result" do
          result = Inspection.filter_by_result("passed")
          expect(result).to include(passed_inspection)
          expect(result).not_to include(failed_inspection)
        end

        it "filters by failed result" do
          result = Inspection.filter_by_result("failed")
          expect(result).to include(failed_inspection)
          expect(result).not_to include(passed_inspection)
        end

        it "returns all when result is neither passed nor failed" do
          result = Inspection.filter_by_result("something_else")
          expect(result.count).to eq(Inspection.count)
        end
      end

      describe "filter_by_unit" do
        let!(:unit1) { create(:unit) }
        let!(:unit2) { create(:unit) }
        let!(:inspection_with_unit1) { create(:inspection, unit: unit1) }
        let!(:inspection_with_unit2) { create(:inspection, unit: unit2) }

        it "filters by unit_id when present" do
          result = Inspection.filter_by_unit(unit1.id)
          expect(result).to include(inspection_with_unit1)
          expect(result).not_to include(inspection_with_unit2)
        end

        it "returns all when unit_id is blank" do
          expect(Inspection.filter_by_unit("")).to eq(Inspection.all)
          expect(Inspection.filter_by_unit(nil)).to eq(Inspection.all)
        end
      end

      describe "filter_by_date_range" do
        let!(:old_inspection) { create(:inspection, inspection_date: 2.years.ago) }
        let!(:recent_inspection) { create(:inspection, inspection_date: 1.month.ago) }

        it "filters by date range when both dates present" do
          result = Inspection.filter_by_date_range(6.months.ago, Date.current)
          expect(result).to include(recent_inspection)
          expect(result).not_to include(old_inspection)
        end

        it "returns all when dates are blank" do
          expect(Inspection.filter_by_date_range(nil, nil)).to eq(Inspection.all)
          expect(Inspection.filter_by_date_range("", "")).to eq(Inspection.all)
        end
      end

      describe "overdue" do
        let!(:overdue_inspection) { create(:inspection, inspection_date: 2.years.ago) }
        let!(:current_inspection) { create(:inspection, inspection_date: 6.months.ago) }

        it "returns inspections older than 1 year" do
          result = Inspection.overdue
          expect(result).to include(overdue_inspection)
          expect(result).not_to include(current_inspection)
        end
      end
    end

    describe "search with units joined" do
      let!(:unit_with_serial) { create(:unit, serial: "ABC123", name: "Test Unit") }
      let!(:inspection_with_unit) { create(:inspection, unit: unit_with_serial, inspection_location: "Test Location") }

      it "searches by unit serial number" do
        expect(Inspection.search("ABC123")).to include(inspection_with_unit)
      end

      it "searches by unit name" do
        expect(Inspection.search("Test Unit")).to include(inspection_with_unit)
      end

      it "returns all when query is blank" do
        expect(Inspection.search("")).to eq(Inspection.all)
        expect(Inspection.search(nil)).to eq(Inspection.all)
      end
    end
  end

  describe "validations with conditional requirements" do
    let(:inspector_company) { create(:inspector_company) }

    describe "complete inspection validations" do
      it "requires inspection_location when complete" do
        inspection = build(:inspection,
          inspection_location: nil,
          complete_date: Time.current,
          inspector_company: inspector_company)
        expect(inspection).not_to be_valid
        expect(inspection.errors[:inspection_location]).to include("can't be blank")
      end

      it "validates unique_report_number uniqueness when provided" do
        create(:inspection, :complete,
          unique_report_number: "TEST-123",
          inspector_company: inspector_company,
          user: user)

        duplicate = build(:inspection,
          unique_report_number: "TEST-123",
          complete_date: Time.current,
          inspector_company: inspector_company,
          user: user)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:unique_report_number]).to include("has already been taken")
      end

      it "allows complete inspection without unique_report_number" do
        inspection = build(:inspection,
          inspection_location: "Test Location",
          complete_date: Time.current,
          unique_report_number: nil,
          inspector_company: inspector_company)
        expect(inspection).to be_valid
      end

      it "allows blank inspection_location when draft" do
        inspection = build(:inspection,
          inspection_location: nil,
          complete_date: nil,
          inspector_company: inspector_company)
        expect(inspection).to be_valid
      end
    end

    describe "numeric field validations" do
      let(:inspection) { build(:inspection) }

      it "validates step_ramp_size is non-negative" do
        inspection.step_ramp_size = -1
        expect(inspection).not_to be_valid
        expect(inspection.errors[:step_ramp_size]).to include("must be greater than or equal to 0")
      end

      it "validates critical_fall_off_height is non-negative" do
        inspection.critical_fall_off_height = -1
        expect(inspection).not_to be_valid
        expect(inspection.errors[:critical_fall_off_height]).to include("must be greater than or equal to 0")
      end

      it "validates unit_pressure is non-negative" do
        inspection.unit_pressure = -1
        expect(inspection).not_to be_valid
        expect(inspection.errors[:unit_pressure]).to include("must be greater than or equal to 0")
      end

      it "validates trough_depth is non-negative" do
        inspection.trough_depth = -1
        expect(inspection).not_to be_valid
        expect(inspection.errors[:trough_depth]).to include("must be greater than or equal to 0")
      end

      it "validates trough_adjacent_panel_width is non-negative" do
        inspection.trough_adjacent_panel_width = -1
        expect(inspection).not_to be_valid
        expect(inspection.errors[:trough_adjacent_panel_width]).to include("must be greater than or equal to 0")
      end
    end

    describe "boolean field validations" do
      let(:inspection) { build(:inspection) }

      it "allows boolean pass/fail fields to be true, false, or nil" do
        inspection.step_ramp_size_pass = true
        inspection.critical_fall_off_height_pass = false
        inspection.unit_pressure_pass = nil
        expect(inspection).to be_valid
      end
    end
  end

  describe "callbacks and lifecycle" do
    let(:inspector_company) { create(:inspector_company) }
    let(:unit) { create(:unit, width: 10, length: 8) }

    describe "before_validation callbacks" do
      it "sets inspector_company_from_user on creation" do
        user_with_company = create(:user, inspection_company: inspector_company)
        inspection = build(:inspection, user: user_with_company, inspector_company: nil)

        inspection.valid? # Trigger validations and callbacks
        expect(inspection.inspector_company_id).to eq(inspector_company.id)
      end

      it "copies unit values when unit_id changes" do
        inspection = build(:inspection, unit: unit)
        inspection.save!
        expect(inspection.width).to eq(unit.width)
        expect(inspection.length).to eq(unit.length)
      end
    end

    describe "before_create callbacks" do
      it "does not auto-generate unique_report_number" do
        inspection = build(:inspection)
        inspection.complete_date = Time.current
        inspection.unique_report_number = nil
        inspection.save!
        
        expect(inspection.unique_report_number).to be_nil
      end

      it "preserves user-provided unique_report_number" do
        existing_number = "USER-PROVIDED-123"
        inspection = build(:inspection,
          complete_date: Time.current,
          unique_report_number: existing_number)
        inspection.save!
        expect(inspection.unique_report_number).to eq(existing_number)
      end
    end
  end

  describe "advanced methods" do
    let(:inspection) { create(:inspection) }

    describe "#can_be_completed?" do
      it "returns false when unit is nil" do
        inspection.unit = nil
        expect(inspection.can_be_completed?).to be_falsey
      end

      it "returns false when not all assessments are complete" do
        inspection.unit = create(:unit)
        allow(inspection).to receive(:all_assessments_complete?).and_return(false)
        expect(inspection.can_be_completed?).to be_falsey
      end

      it "returns true when unit present and all assessments complete" do
        inspection.unit = create(:unit)
        allow(inspection).to receive(:all_assessments_complete?).and_return(true)
        expect(inspection.can_be_completed?).to be_truthy
      end
    end

    describe "#completion_status" do
      it "returns comprehensive completion status" do
        inspection.unit = create(:unit)
        allow(inspection).to receive(:all_assessments_complete?).and_return(false)
        allow(inspection).to receive(:get_missing_assessments).and_return(["User Height"])

        status = inspection.completion_status
        expect(status[:complete]).to eq(inspection.complete?)
        expect(status[:all_assessments_complete]).to be_falsey
        expect(status[:missing_assessments]).to eq(["User Height"])
        expect(status[:can_be_completed]).to be_falsey
      end
    end

    describe "#get_missing_assessments" do
      let(:inspection) { create(:inspection, unit: create(:unit, has_slide: true), is_totally_enclosed: true) }

      it "identifies missing unit" do
        inspection.unit = nil
        missing = inspection.get_missing_assessments
        expect(missing).to include("Unit")
      end

      it "identifies missing assessments" do
        # Mock incomplete assessments
        allow(inspection).to receive_message_chain(:user_height_assessment, :complete?).and_return(false)
        allow(inspection).to receive_message_chain(:structure_assessment, :complete?).and_return(false)

        missing = inspection.get_missing_assessments
        expect(missing).to include("User Height", "Structure")
      end

      it "includes slide assessment when has_slide is true" do
        inspection.has_slide = true
        allow(inspection).to receive_message_chain(:slide_assessment, :complete?).and_return(false)

        missing = inspection.get_missing_assessments
        expect(missing).to include("Slide")
      end

      it "includes enclosed assessment when is_totally_enclosed is true" do
        inspection.is_totally_enclosed = true
        allow(inspection).to receive_message_chain(:enclosed_assessment, :complete?).and_return(false)

        missing = inspection.get_missing_assessments
        expect(missing).to include("Enclosed")
      end
    end

    describe "#complete!" do
      it "sets complete_date and logs audit action" do
        inspection.complete_date = nil
        expect(inspection).to receive(:log_audit_action).with("completed", user, "Inspection completed")

        inspection.complete!(user)
        expect(inspection.complete_date).to be_present
      end
    end

    describe "inspection lifecycle management" do
      let(:inspection) { create(:inspection, user: user) }
      
      it "allows editing after marking as complete" do
        inspection.complete!(user)
        expect(inspection.complete?).to be true
        
        inspection.update!(inspection_location: "Updated after completion")
        expect(inspection.reload.inspection_location).to eq("Updated after completion")
      end
      
      it "allows toggling between complete and incomplete states" do
        inspection.complete!(user)
        expect(inspection.complete?).to be true
        
        inspection.update!(complete_date: nil)
        expect(inspection.complete?).to be false
        
        inspection.complete!(user)
        expect(inspection.complete?).to be true
      end
      
      it "preserves all data when toggling completion status" do
        original_location = "Original Location"
        original_report_number = "TEST-REPORT-123"
        inspection.update!(
          inspection_location: original_location, 
          comments: "Test comments",
          unique_report_number: original_report_number
        )
        
        inspection.complete!(user)
        inspection.update!(complete_date: nil)
        
        expect(inspection.inspection_location).to eq(original_location)
        expect(inspection.comments).to eq("Test comments")
        expect(inspection.unique_report_number).to eq(original_report_number) # Should preserve report number
      end

      it "allows users full control over their inspection records" do
        # User can create draft
        expect(inspection.complete?).to be false
        
        # User can add data
        inspection.update!(
          inspection_location: "Test Location",
          passed: true,
          comments: "All good"
        )
        
        # User can mark complete
        inspection.complete!(user)
        expect(inspection.complete?).to be true
        
        # User can still edit when complete
        inspection.update!(comments: "Updated comments after completion")
        expect(inspection.reload.comments).to eq("Updated comments after completion")
        
        # User can revert to draft
        inspection.update!(complete_date: nil)
        expect(inspection.complete?).to be false
      end

      it "does not auto-generate unique_report_number" do
        expect(inspection.unique_report_number).to be_nil
        
        # Marking complete without setting report number should not generate one
        inspection.complete!(user)
        expect(inspection.unique_report_number).to be_nil
        
        # User can set their own report number
        inspection.update!(unique_report_number: "CUSTOM-2024-001")
        expect(inspection.unique_report_number).to eq("CUSTOM-2024-001")
      end

      it "allows user to set unique_report_number manually" do
        inspection.update!(unique_report_number: "USER-DEFINED-123")
        inspection.complete!(user)
        
        expect(inspection.unique_report_number).to eq("USER-DEFINED-123")
      end
    end

    describe "#duplicate_for_user" do
      let(:original_user) { create(:user) }
      let(:new_user) { create(:user) }
      let(:inspection) { create(:inspection, :complete, user: original_user) }

      it "creates a copy for new user" do
        allow(inspection).to receive(:duplicate_assessments)

        duplicate = inspection.duplicate_for_user(new_user)

        expect(duplicate.user).to eq(new_user)
        expect(duplicate.complete_date).to be_nil
        expect(duplicate.unique_report_number).to be_nil
        expect(duplicate.passed).to be_nil
        expect(duplicate).to be_persisted
      end

      it "calls duplicate_assessments" do
        expect(inspection).to receive(:duplicate_assessments)
        inspection.duplicate_for_user(new_user)
      end
    end

    describe "#validate_completeness" do
      let(:inspection) { create(:inspection) }

      it "returns empty array when all assessments complete" do
        # Mock all assessments as complete
        complete_assessment = double(present?: true, complete?: true)
        allow(inspection).to receive(:user_height_assessment).and_return(complete_assessment)
        allow(inspection).to receive(:slide_assessment).and_return(complete_assessment)
        allow(inspection).to receive(:structure_assessment).and_return(complete_assessment)
        allow(inspection).to receive(:anchorage_assessment).and_return(complete_assessment)
        allow(inspection).to receive(:materials_assessment).and_return(complete_assessment)
        allow(inspection).to receive(:fan_assessment).and_return(complete_assessment)
        allow(inspection).to receive(:enclosed_assessment).and_return(complete_assessment)

        errors = inspection.validate_completeness
        expect(errors).to be_empty
      end

      it "returns errors for incomplete assessments" do
        # Mock incomplete assessments
        incomplete_assessment = double(present?: true, complete?: false)
        allow(inspection).to receive(:user_height_assessment).and_return(incomplete_assessment)
        allow(inspection).to receive(:structure_assessment).and_return(incomplete_assessment)

        errors = inspection.validate_completeness
        expect(errors).to include("User Height Assessment incomplete")
        expect(errors).to include("Structure Assessment incomplete")
      end
    end

    describe "#pass_fail_summary" do
      let(:inspection) { create(:inspection) }

      it "returns zero summary when no safety checks" do
        allow(inspection).to receive(:total_safety_checks).and_return(0)

        summary = inspection.pass_fail_summary
        expect(summary[:total_checks]).to eq(0)
        expect(summary[:passed_checks]).to eq(0)
        expect(summary[:failed_checks]).to eq(0)
        expect(summary[:pass_percentage]).to eq(0)
      end

      it "calculates pass/fail summary" do
        allow(inspection).to receive(:total_safety_checks).and_return(10)
        allow(inspection).to receive(:passed_safety_checks).and_return(8)
        allow(inspection).to receive(:failed_safety_checks).and_return(2)

        summary = inspection.pass_fail_summary
        expect(summary[:total_checks]).to eq(10)
        expect(summary[:passed_checks]).to eq(8)
        expect(summary[:failed_checks]).to eq(2)
        expect(summary[:pass_percentage]).to eq(80.0)
      end
    end

    describe "#log_audit_action" do
      it "logs to Rails logger" do
        expect(Rails.logger).to receive(:info).with("Inspection #{inspection.id}: test_action by #{user.email} - test details")
        inspection.log_audit_action("test_action", user, "test details")
      end

      it "handles nil user" do
        expect(Rails.logger).to receive(:info).with("Inspection #{inspection.id}: test_action by  - test details")
        inspection.log_audit_action("test_action", nil, "test details")
      end
    end
  end

  describe "private methods" do
    let(:inspection) { create(:inspection) }

    describe "#copy_unit_values" do
      it "does nothing when unit is nil" do
        inspection.unit = nil
        expect(inspection).not_to receive(:copy_attributes_from)
        inspection.send(:copy_unit_values)
      end

      it "copies attributes from unit when present" do
        unit = create(:unit)
        inspection.unit = unit
        expect(inspection).to receive(:copy_attributes_from).with(unit)
        inspection.send(:copy_unit_values)
      end
    end

    describe "#set_inspector_company_from_user" do
      it "sets inspector_company_id from user when nil" do
        inspector_company = create(:inspector_company)
        user_with_company = create(:user, inspection_company: inspector_company)
        inspection.user = user_with_company
        inspection.inspector_company_id = nil

        inspection.send(:set_inspector_company_from_user)
        expect(inspection.inspector_company_id).to eq(inspector_company.id)
      end

      it "does not override existing inspector_company_id" do
        existing_company = create(:inspector_company)
        new_company = create(:inspector_company)
        user_with_company = create(:user, inspection_company: new_company)

        inspection.user = user_with_company
        inspection.inspector_company_id = existing_company.id

        inspection.send(:set_inspector_company_from_user)
        expect(inspection.inspector_company_id).to eq(existing_company.id)
      end
    end

    describe "assessment checking methods" do
      let(:inspection) { create(:inspection) }

      describe "#has_assessments?" do
        it "returns false when no assessments present" do
          expect(inspection.send(:has_assessments?)).to be_falsey
        end

        it "returns true when any assessment present" do
          inspection.create_user_height_assessment!
          expect(inspection.send(:has_assessments?)).to be_truthy
        end
      end

      describe "#all_assessments_complete?" do
        it "returns false when no assessments" do
          expect(inspection.send(:all_assessments_complete?)).to be_falsey
        end

        it "checks required assessments with mocking" do
          # Mock all required assessments as complete
          allow(inspection).to receive_message_chain(:user_height_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:structure_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:anchorage_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:materials_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:fan_assessment, :complete?).and_return(true)
          allow(inspection).to receive(:has_assessments?).and_return(true)

          expect(inspection.send(:all_assessments_complete?)).to be_truthy
        end

        it "includes slide assessment when has_slide" do
          inspection.has_slide = true
          # Mock assessments but missing slide
          allow(inspection).to receive_message_chain(:user_height_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:structure_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:anchorage_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:materials_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:fan_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:slide_assessment, :complete?).and_return(false)
          allow(inspection).to receive(:has_assessments?).and_return(true)

          expect(inspection.send(:all_assessments_complete?)).to be_falsey
        end

        it "includes enclosed assessment when is_totally_enclosed" do
          inspection.is_totally_enclosed = true
          # Mock assessments but missing enclosed
          allow(inspection).to receive_message_chain(:user_height_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:structure_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:anchorage_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:materials_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:fan_assessment, :complete?).and_return(true)
          allow(inspection).to receive_message_chain(:enclosed_assessment, :complete?).and_return(false)
          allow(inspection).to receive(:has_assessments?).and_return(true)

          expect(inspection.send(:all_assessments_complete?)).to be_falsey
        end
      end
    end

    describe "safety check methods" do
      let(:inspection) { create(:inspection) }

      before do
        inspection.create_user_height_assessment!
        inspection.create_structure_assessment!
      end

      describe "#all_safety_checks_pass?" do
        it "returns true when no assessments" do
          allow(inspection).to receive(:has_assessments?).and_return(false)
          expect(inspection.send(:all_safety_checks_pass?)).to be_truthy
        end

        it "checks for critical failures" do
          # Mock assessments with critical failures
          structure = double(has_critical_failures?: true)
          allow(inspection).to receive(:structure_assessment).and_return(structure)
          allow(structure).to receive(:respond_to?).with(:has_critical_failures?).and_return(true)

          expect(inspection.send(:all_safety_checks_pass?)).to be_falsey
        end

        it "checks safety thresholds" do
          allow(inspection).to receive(:meet_safety_thresholds?).and_return(false)
          expect(inspection.send(:all_safety_checks_pass?)).to be_falsey
        end
      end

      describe "#meet_safety_thresholds?" do
        it "returns true when no assessments" do
          allow(inspection).to receive(:has_assessments?).and_return(false)
          expect(inspection.send(:meet_safety_thresholds?)).to be_truthy
        end

        it "returns true when no failing safety requirements" do
          allow(inspection).to receive(:has_assessments?).and_return(true)
          allow(inspection).to receive(:user_height_assessment).and_return(nil)
          allow(inspection).to receive(:slide_assessment).and_return(nil)
          allow(inspection).to receive(:anchorage_assessment).and_return(nil)

          expect(inspection.send(:meet_safety_thresholds?)).to be_truthy
        end
      end

      describe "safety check counting methods" do
        describe "#total_safety_checks" do
          it "returns 0 when no assessments" do
            allow(inspection).to receive(:has_assessments?).and_return(false)
            expect(inspection.send(:total_safety_checks)).to eq(0)
          end

          it "sums safety checks from all assessments" do
            assessment = double(safety_check_count: 5)
            allow(assessment).to receive(:respond_to?).with(:safety_check_count).and_return(true)
            allow(assessment).to receive(:respond_to?).with(:present?).and_return(true)
            allow(assessment).to receive(:respond_to?).with(:empty?).and_return(false)
            allow(assessment).to receive(:present?).and_return(true)

            allow(inspection).to receive(:user_height_assessment).and_return(assessment)
            allow(inspection).to receive(:slide_assessment).and_return(nil)
            allow(inspection).to receive(:structure_assessment).and_return(nil)
            allow(inspection).to receive(:anchorage_assessment).and_return(nil)
            allow(inspection).to receive(:materials_assessment).and_return(nil)
            allow(inspection).to receive(:fan_assessment).and_return(nil)
            allow(inspection).to receive(:has_assessments?).and_return(true)

            expect(inspection.send(:total_safety_checks)).to eq(5)
          end
        end

        describe "#passed_safety_checks" do
          it "returns 0 when no assessments" do
            allow(inspection).to receive(:has_assessments?).and_return(false)
            expect(inspection.send(:passed_safety_checks)).to eq(0)
          end

          it "sums passed checks from all assessments" do
            assessment = double(passed_checks_count: 4)
            allow(assessment).to receive(:respond_to?).with(:passed_checks_count).and_return(true)
            allow(assessment).to receive(:respond_to?).with(:present?).and_return(true)
            allow(assessment).to receive(:respond_to?).with(:empty?).and_return(false)
            allow(assessment).to receive(:present?).and_return(true)

            allow(inspection).to receive(:user_height_assessment).and_return(assessment)
            allow(inspection).to receive(:slide_assessment).and_return(nil)
            allow(inspection).to receive(:structure_assessment).and_return(nil)
            allow(inspection).to receive(:anchorage_assessment).and_return(nil)
            allow(inspection).to receive(:materials_assessment).and_return(nil)
            allow(inspection).to receive(:fan_assessment).and_return(nil)
            allow(inspection).to receive(:has_assessments?).and_return(true)

            expect(inspection.send(:passed_safety_checks)).to eq(4)
          end
        end

        describe "#failed_safety_checks" do
          it "calculates failed checks as total minus passed" do
            allow(inspection).to receive(:total_safety_checks).and_return(10)
            allow(inspection).to receive(:passed_safety_checks).and_return(7)
            expect(inspection.send(:failed_safety_checks)).to eq(3)
          end
        end
      end
    end

    describe "#duplicate_assessments" do
      let(:original_inspection) { create(:inspection) }
      let(:new_inspection) { create(:inspection) }

      before do
        original_inspection.create_user_height_assessment!
        original_inspection.create_structure_assessment!
      end

      it "duplicates all present assessments" do
        original_inspection.send(:duplicate_assessments, new_inspection)

        new_inspection.reload
        expect(new_inspection.user_height_assessment).to be_present
        expect(new_inspection.structure_assessment).to be_present
      end

      it "duplicates enclosed assessment when is_totally_enclosed" do
        original_inspection.is_totally_enclosed = true
        original_inspection.create_enclosed_assessment!

        original_inspection.send(:duplicate_assessments, new_inspection)

        new_inspection.reload
        expect(new_inspection.enclosed_assessment).to be_present
      end
    end
  end
end
